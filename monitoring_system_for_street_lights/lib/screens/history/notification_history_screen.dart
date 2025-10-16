import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../street_light/street_light_detail_screen.dart';

class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
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
          'Fixed Notifications History',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
       
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
         stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('isFixed', isEqualTo: true)
              .snapshots(),
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

            return Column(
              children: [
                // History stats card
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
                ).animate().fadeIn(duration: 400.ms),

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

                        return GestureDetector(
                              onTap: () {
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
                                                    data: docSnapshot.data()!,
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.2),
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
                                        Container(
                                          width: 40.w,
                                          height: 40.w,
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
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
                                                  color: const Color(
                                                    0xFF1A202C,
                                                  ),
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
                                                  color: const Color(
                                                    0xFF047857,
                                                  ),
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
                                                  // Confirm then delete
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
                            )
                            .animate()
                            .slideY(
                              begin: 0.1,
                              duration: 300.ms,
                              delay: (index * 50).ms,
                            )
                            .fadeIn(duration: 300.ms);
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
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
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
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Notification deleted'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Error deleting notification'),
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
}
