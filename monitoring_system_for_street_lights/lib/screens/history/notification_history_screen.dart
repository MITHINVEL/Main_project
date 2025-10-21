import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../street_light/street_light_detail_screen.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  // Selection state
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;
  List<String> _visibleHistoryIds = [];
  // Whether the initial history load animation has already run. When true
  // we avoid re-running item animations on each stream update which was
  // causing a perceived "loading/refreshing" effect.
  bool _initialHistoryLoaded = false;

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  // Styled delete-selected button. Accepts the build context because the
  // confirmation flow requires it.
  Widget _buildDeleteSelectedButton(BuildContext context) {
    final enabled = _selectedIds.isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: IconButton(
        tooltip: enabled ? 'Delete selected' : 'Select items to delete',
        onPressed: enabled ? () => _confirmAndDeleteSelected(context) : null,
        icon: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [Color(0xFFE53E3E), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: enabled ? null : Colors.white.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete,
            color: enabled ? Colors.white : Colors.white70,
            size: 20.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectAllButton() {
    final allSelected =
        _selectedIds.length == _visibleHistoryIds.length &&
        _visibleHistoryIds.isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: IconButton(
        tooltip: allSelected ? 'Deselect all' : 'Select all',
        onPressed: () {
          HapticFeedback.lightImpact();
          _toggleSelectAll();
        },
        icon: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            gradient: allSelected
                ? const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: allSelected ? null : Colors.white.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            allSelected ? Icons.check : Icons.select_all,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildHistoryStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If no user is logged in, return empty stream
      return const Stream.empty();
    }

    // Show only fixed notifications for the current user
    // Removed orderBy to avoid composite index requirement
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('createdBy', isEqualTo: user.uid)
        .where('isFixed', isEqualTo: true)
        .snapshots();
  }

  void _toggleSelectId(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _selectionMode = _selectedIds.isNotEmpty;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _visibleHistoryIds.length &&
          _visibleHistoryIds.isNotEmpty) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(_visibleHistoryIds);
        _selectionMode = true;
      }
    });
  }

  // Provide a nicer select-all button that adapts when everything is
  // selected. Shows a small gradient circle with an icon so it looks
  // distinct in the app bar.

  // Wrap the summary card with a one-time animation helper. After the
  // first successful data load we set `_initialHistoryLoaded` so future
  // snapshots don't replay the animation.
  Widget _maybeAnimateSummary(Widget child) {
    if (_initialHistoryLoaded) return child;
    return child.animate().fadeIn(duration: 400.ms);
  }

  // Wrap each item in a one-time slide+fade animation. Delay can be used
  // to stagger items on the initial load. After the first load we return
  // the widget directly to avoid re-animation.
  Widget _maybeAnimateItem(Widget child, {int delayMs = 0}) {
    if (_initialHistoryLoaded) return child;
    return child
        .animate()
        .slideY(begin: 0.1, duration: 300.ms, delay: (delayMs).ms)
        .fadeIn(duration: 300.ms);
  }

  Future<void> _confirmAndDeleteSelected(BuildContext context) async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: const Text('Delete Selected Notifications'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} selected notification(s)? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteSelectedItems(context);
    }
  }

  Future<void> _deleteSelectedItems(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        final ref = FirebaseFirestore.instance
            .collection('notifications')
            .doc(id);
        batch.delete(ref);
      }
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${_selectedIds.length} notification(s) deleted'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    } catch (e) {
      print('Error deleting selected notifications: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(child: Text('Error deleting: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _confirmAndClearAll(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to permanently clear your entire fixed notifications history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _clearHistory(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 62.h,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          _selectionMode
              ? '${_selectedIds.length} selected'
              : 'Fixed Notifications History',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          onPressed: () {
            if (_selectionMode) {
              setState(() {
                _selectionMode = false;
                _selectedIds.clear();
              });
            } else {
              Navigator.of(context).pop();
            }
          },
          icon: Icon(_selectionMode ? Icons.close : Icons.arrow_back),
        ),
        // Only show select/all and delete actions when user is in selection mode.
        // The default AppBar should not show the clear/delete icon.
        actions: _selectionMode
            ? [_buildSelectAllButton(), _buildDeleteSelectedButton(context)]
            : [],

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _buildHistoryStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64.sp, color: Colors.grey),
                    SizedBox(height: 16.h),
                    Text(
                      'Unable to load history',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Please check your internet connection',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Trigger rebuild
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationHistoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF4CAF50),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Loading history...',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyHistoryState(context);
            }

            final docs = snapshot.data!.docs;
            final historyDocs = docs.where((doc) {
              try {
                final data = doc.data();
                final related = (data['relatedLights'] as List<dynamic>?) ?? [];
                final source = (data['source'] ?? '').toString().toLowerCase();
                return source.startsWith('sms') || related.isNotEmpty;
              } catch (e) {
                print('Error filtering history doc ${doc.id}: $e');
                return false;
              }
            }).toList();

            // Update visible ids and clean up any selections that no longer exist
            final newVisibleIds = historyDocs.map((d) => d.id).toList();
            if (!listEquals(newVisibleIds, _visibleHistoryIds)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _visibleHistoryIds = newVisibleIds;
                  _selectedIds.removeWhere(
                    (id) => !_visibleHistoryIds.contains(id),
                  );
                  if (_selectedIds.isEmpty) _selectionMode = false;
                });
              });
            }

            // Sort client-side by fixedAt (if available) otherwise timestamp.
            historyDocs.sort((a, b) {
              Timestamp? aTs =
                  (a.data()['fixedAt'] as Timestamp?) ??
                  (a.data()['timestamp'] as Timestamp?);
              Timestamp? bTs =
                  (b.data()['fixedAt'] as Timestamp?) ??
                  (b.data()['timestamp'] as Timestamp?);
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1; // push nulls to end
              if (bTs == null) return -1;
              return bTs.compareTo(aTs); // descending
            });

            if (historyDocs.isEmpty) {
              return _buildEmptyHistoryState(context);
            }

            // After the first successful data load schedule a post-frame
            // callback to mark animations as already shown so subsequent
            // stream updates don't replay them (which looked like a
            // continuous loading/refreshing effect).
            if (!_initialHistoryLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _initialHistoryLoaded = true;
                });
              });
            }

            return Column(
              children: [
                // History stats card (animated once)
                _maybeAnimateSummary(
                  Container(
                    margin: EdgeInsets.all(16.w),
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: const Icon(
                                Icons.history,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fixed Notifications',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${historyDocs.length} notifications resolved',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // History list
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                    itemCount: historyDocs.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      try {
                        final doc = historyDocs[index];
                        final data = doc.data();
                        final from = data['from'] ?? 'Unknown';
                        final body = data['body'] ?? '';
                        final fixedAt = data['fixedAt'] as Timestamp?;
                        final timestamp =
                            data['timestamp']
                                as Timestamp?; // Fallback to timestamp
                        final related =
                            (data['relatedLights'] as List<dynamic>?)
                                ?.cast<String>() ??
                            [];

                        final isSelected = _selectedIds.contains(doc.id);

                        final itemWidget = Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            onLongPress: () {
                              // Start selection mode and select this item
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectionMode = true;
                                _selectedIds.add(doc.id);
                              });
                            },
                            onTap: () {
                              if (_selectionMode) {
                                _toggleSelectId(doc.id);
                                return;
                              }
                              if (related.isNotEmpty) {
                                FirebaseFirestore.instance
                                    .collection('street_lights')
                                    .doc(related.first)
                                    .get()
                                    .then((docSnapshot) {
                                      if (docSnapshot.exists) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StreetLightDetailScreen(
                                                  data: {
                                                    ...docSnapshot.data()!,
                                                    'id': docSnapshot.id,
                                                  },
                                                ),
                                          ),
                                        );
                                      }
                                    })
                                    .catchError((error) {
                                      print(
                                        'Error navigating to detail: $error',
                                      );
                                    });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.green.withOpacity(0.04)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.12),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 40.w,
                                        height: 40.w,
                                        child: _selectionMode
                                            ? Center(
                                                child: Checkbox(
                                                  value: isSelected,
                                                  onChanged: (_) =>
                                                      _toggleSelectId(doc.id),
                                                ),
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        10.r,
                                                      ),
                                                ),
                                                child: const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                              ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              related.isNotEmpty
                                                  ? 'Street Light Fixed'
                                                  : from,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14.sp,
                                                color: const Color(0xFF1A202C),
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            if (related.isNotEmpty)
                                              Text(
                                                '${related.length} light(s) resolved',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDEF7EC),
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                            ),
                                            child: Text(
                                              'FIXED',
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF047857),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          PopupMenuButton<String>(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: Colors.grey[600],
                                              size: 18.sp,
                                            ),
                                            onSelected: (value) async {
                                              if (value == 'delete') {
                                                await _confirmAndDelete(
                                                  context,
                                                  doc.id,
                                                );
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                      size: 18.sp,
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    const Text('Delete'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    body,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: const Color(0xFF4A5568),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 12.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14.sp,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Fixed on ${_formatTimestamp(fixedAt ?? timestamp)}',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        // Wrap with one-time animation helper to avoid
                        // replaying on subsequent stream updates.
                        return _maybeAnimateItem(
                          itemWidget,
                          delayMs: index * 50,
                        );
                      } catch (e) {
                        print('Error building history item $index: $e');
                        return Container(
                          padding: EdgeInsets.all(16.w),
                          margin: EdgeInsets.symmetric(vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 20.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Error loading this notification',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32.w),
        margin: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(40.r),
              ),
              child: const Icon(Icons.history, size: 40, color: Colors.grey),
            ),
            SizedBox(height: 20.h),
            Text(
              'No History Yet',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Fixed notifications will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF718096)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearHistory(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('createdBy', isEqualTo: user.uid)
          .where('isFixed', isEqualTo: true)
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('History cleared successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
        _visibleHistoryIds.clear();
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Error clearing history'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification from history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteHistoryItem(context, docId);
    }
  }

  Future<void> _deleteHistoryItem(BuildContext context, String docId) async {
    try {
      print('Attempting to delete notification with ID: $docId');

      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if document exists before deletion
      final docSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Notification not found');
      }

      // Verify user owns this notification
      final docData = docSnapshot.data();
      if (docData != null && docData['createdBy'] != user.uid) {
        throw Exception('Permission denied - not your notification');
      }

      // Perform deletion
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .delete();

      print('Successfully deleted notification: $docId');

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Notification deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      setState(() {
        _selectedIds.remove(docId);
        if (_selectedIds.isEmpty) _selectionMode = false;
      });
    } catch (e) {
      print('Error deleting notification: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error deleting: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
