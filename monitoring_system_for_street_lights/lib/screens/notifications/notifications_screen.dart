import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import '../street_light/street_light_detail_screen.dart';
import '../../services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ...existing code...

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.showAppBar = true,
    this.isEmbeddedInBottomNav = false,
  });

  final bool showAppBar;
  final bool isEmbeddedInBottomNav;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late StreamController<void> _refreshController;
  bool _initialNotificationsLoaded = false;
  final Set<String> _displayedNotificationIds = {};
  // Locally track notifications marked fixed by this device so we can
  // optimistically hide them from the UI before Firestore round-trip.
  final Set<String> _locallyFixedNotificationIds = {};
  // Track suppressed alert signatures ("from|body") so once the user
  // marks a given alert signature fixed we don't show equivalent alerts
  // again on this device.
  final Set<String> _suppressedSignatures = {};
  // Cache for related street light documents keyed by their id. This lets
  // us show the street light name synchronously in the list without
  // flashing the phone number first.
  final Map<String, Map<String, dynamic>> _streetLightCache = {};
  // Prevent excessive rebuilds
  bool _isUpdatingCache = false;
  // Track failed fetch attempts to prevent infinite retry
  final Set<String> _failedFetches = {};

  @override
  void initState() {
    super.initState();
    _refreshController = StreamController<void>.broadcast();
    _loadSuppressedSignatures();
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  /// Prefetch street_light documents for the provided set of ids and store
  /// their data in `_streetLightCache` so the UI can synchronously read
  /// the name/location without per-item async lookups.
  Future<void> _prefetchStreetLightDocs(Set<String> ids) async {
    try {
      final toFetch = ids
          .where(
            (id) =>
                !_streetLightCache.containsKey(id) &&
                !_failedFetches.contains(id),
          )
          .toList();
      if (toFetch.isEmpty) return;

      print('🔄 Prefetching ${toFetch.length} street light documents...');

      final coll = FirebaseFirestore.instance.collection('street_lights');
      const int chunkSize = 10; // Firestore whereIn limit
      for (int i = 0; i < toFetch.length; i += chunkSize) {
        final end = min(i + chunkSize, toFetch.length);
        final chunk = toFetch.sublist(i, end);
        try {
          final snap = await coll
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (final d in snap.docs) {
            _streetLightCache[d.id] = d.data();
            print(
              '✅ Cached street light: ${d.id} - ${d.data()['name'] ?? 'Unnamed'}',
            );
          }

          // Mark any not found as failed to prevent retry
          final foundIds = snap.docs.map((d) => d.id).toSet();
          for (final id in chunk) {
            if (!foundIds.contains(id)) {
              _failedFetches.add(id);
            }
          }
        } catch (chunkError) {
          print('❌ Error fetching chunk: $chunkError');
          // Mark all in this chunk as failed to prevent infinite retry
          _failedFetches.addAll(chunk);
        }
      }

      // Only update UI once at the end, not per document
      if (mounted && _streetLightCache.isNotEmpty) {
        setState(() {});
      }
    } catch (e) {
      print('❌ Error prefetching street lights: $e');
    }
  }

  /// Fetch a single street light document and update the cache
  Future<void> _fetchSingleStreetLight(String lightId) async {
    try {
      // Skip if already cached, already updating, failed before, or widget unmounted
      if (_streetLightCache.containsKey(lightId) ||
          _isUpdatingCache ||
          _failedFetches.contains(lightId) ||
          !mounted)
        return;

      _isUpdatingCache = true;

      final doc = await FirebaseFirestore.instance
          .collection('street_lights')
          .doc(lightId)
          .get();

      if (doc.exists && mounted) {
        _streetLightCache[lightId] = doc.data()!;
        // Only update state if we're not in the middle of another update
        if (mounted) {
          setState(() {});
        }
      } else {
        // Mark as failed to prevent retry
        _failedFetches.add(lightId);
      }
    } catch (e) {
      print('❌ Error fetching single street light $lightId: $e');
      // Mark as failed to prevent infinite retry
      _failedFetches.add(lightId);
    } finally {
      _isUpdatingCache = false;
    }
  }

  Future<void> _loadSuppressedSignatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('suppressed_signatures_v1') ?? [];
      if (list.isNotEmpty && mounted) {
        setState(() {
          _suppressedSignatures.addAll(list);
        });
      } else {
        _suppressedSignatures.addAll(list);
      }
    } catch (e) {
      print('Error loading suppressed signatures: $e');
    }
  }

  Future<void> _addSuppressedSignatures(Iterable<String> signatures) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList('suppressed_signatures_v1') ?? [];
      final merged = current.toSet()..addAll(signatures);
      await prefs.setStringList('suppressed_signatures_v1', merged.toList());
      if (mounted) {
        setState(() {
          _suppressedSignatures.addAll(signatures);
        });
      } else {
        _suppressedSignatures.addAll(signatures);
      }
    } catch (e) {
      print('Error saving suppressed signatures: $e');
    }
  }

  Future<void> _removeSuppressedSignatures(Iterable<String> signatures) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList('suppressed_signatures_v1') ?? [];
      final remaining = current.toSet()..removeAll(signatures);
      await prefs.setStringList('suppressed_signatures_v1', remaining.toList());
      if (mounted) {
        setState(() {
          _suppressedSignatures.removeAll(signatures);
        });
      } else {
        _suppressedSignatures.removeAll(signatures);
      }
    } catch (e) {
      print('Error removing suppressed signatures: $e');
    }
  }

  /// Finds other notification document ids that share the same sender/body
  /// signature as the provided notification and returns both the list of
  /// matching ids and the signature string. This is used to mark duplicates
  /// fixed together and to persist suppression keys locally.
  Future<Map<String, dynamic>> _findDuplicateIdsAndSignatureForNotification(
    String notificationId,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId);
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        return {
          'ids': <String>[notificationId],
          'signature': '',
        };
      }
      final data = docSnapshot.data() ?? {};
      final from = data['from']?.toString() ?? 'Unknown';
      final body = (data['body'] ?? '').toString().trim();
      final signature = '$from|$body';

      final user = FirebaseAuth.instance.currentUser;
      if (user == null)
        return {
          'ids': <String>[notificationId],
          'signature': signature,
        };

      // Query notifications created by this user and filter locally to
      // avoid composite index requirements on Firestore.
      final q = await FirebaseFirestore.instance
          .collection('notifications')
          .where('createdBy', isEqualTo: user.uid)
          .get();
      final matches = <String>[];
      for (final d in q.docs) {
        final dData = d.data();
        final dFrom = dData['from']?.toString() ?? 'Unknown';
        final dBody = (dData['body'] ?? '').toString().trim();
        if (dFrom == from && dBody == body) {
          matches.add(d.id);
        }
      }

      if (matches.isEmpty) matches.add(notificationId);
      return {'ids': matches, 'signature': signature};
    } catch (e) {
      print('Error finding duplicates for $notificationId: $e');
      return {
        'ids': <String>[notificationId],
        'signature': '',
      };
    }
  }

  /// Optimistic handler used by UI controls. Adds the notification id to
  /// the local fixed set (hides it immediately), then calls the real
  /// Firestore update routine. If the update fails, the local state is
  /// reverted and an error snackbar is shown.
  Future<void> _handleMarkAsFixed(
    String notificationId,
    BuildContext context, {
    bool showSnackBar = true,
  }) async {
    // Discover duplicates (same sender/body) and the signature used for
    // de-duplication so we can optimistically hide all of them and persist
    // a local suppression entry. This prevents the alert from coming back
    // as another notification document with the same signature.
    List<String> duplicates = [notificationId];
    String signature = '';
    try {
      final res = await _findDuplicateIdsAndSignatureForNotification(
        notificationId,
      );
      duplicates = List<String>.from(
        res['ids'] as List<dynamic>? ?? [notificationId],
      );
      signature = (res['signature'] as String?) ?? '';
    } catch (e) {
      print('Error gathering duplicates for $notificationId: $e');
      duplicates = [notificationId];
    }

    // Optimistically hide all matching docs
    final toAdd = duplicates
        .where((id) => !_locallyFixedNotificationIds.contains(id))
        .toList();
    if (toAdd.isNotEmpty) {
      setState(() {
        _locallyFixedNotificationIds.addAll(toAdd);
      });
    }

    // Persist the signature suppression so new docs with the same
    // signature won't be shown on this device.
    if (signature.isNotEmpty) {
      await _addSuppressedSignatures([signature]);
    }

    try {
      await _markNotificationAsFixed(
        notificationId,
        context,
        showSnackBar: showSnackBar,
        alsoFixIds: duplicates,
      );
    } catch (e) {
      // Revert optimistic hide on failure
      if (mounted) {
        setState(() {
          _locallyFixedNotificationIds.removeAll(duplicates);
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as fixed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Revert suppressed signature.
      if (signature.isNotEmpty) {
        await _removeSuppressedSignatures([signature]);
      }
    }
  }

  // Reset all notification filters to show all notifications
  Future<void> _resetNotificationFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear suppressed signatures
      await prefs.remove('suppressed_signatures_v1');

      // Clear locally tracked fixed notifications
      setState(() {
        _locallyFixedNotificationIds.clear();
        _suppressedSignatures.clear();

        // Clear street light cache to force fresh fetch
        _streetLightCache.clear();
        _failedFetches.clear();

        // Reset other state variables to force complete reload
        _initialNotificationsLoaded = false;
        _displayedNotificationIds.clear();
        _isUpdatingCache = false;
      });

      // Force a small delay to ensure UI resets completely
      await Future.delayed(const Duration(milliseconds: 100));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications feed refreshed! 🔄'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If no user is logged in, return empty stream
      return const Stream.empty();
    }

    // Show only notifications for the current user
    // Removed orderBy to avoid composite index requirement
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('createdBy', isEqualTo: user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: widget.showAppBar
          ? AppBar(
              elevation: 0,
              centerTitle: true,
              toolbarHeight: 62.h,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              title: Text(
                'Fault Notifications',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
              ),
              leading:
                  !widget.isEmbeddedInBottomNav &&
                      Navigator.of(context).canPop()
                  ? IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back),
                    )
                  : null,
              automaticallyImplyLeading:
                  !widget.isEmbeddedInBottomNav &&
                  Navigator.of(context).canPop(),
              actions: [
                IconButton(
                  onPressed: _resetNotificationFilters,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Notifications',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'reset') {
                      _resetNotificationFilters();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reset',
                      child: Text('Reset All Filters'),
                    ),
                  ],
                ),
              ],
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28.r),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _buildNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('Firestore Error: ${snapshot.error}');

              // Check if it's a permission error
              String errorMessage = 'Unable to load notifications';
              String errorDetails = 'Please check your internet connection';

              if (snapshot.error.toString().contains('permission')) {
                errorMessage = 'Permission denied';
                errorDetails =
                    'Please make sure you are logged in and have proper access rights';
              } else if (snapshot.error.toString().contains(
                'failed-precondition',
              )) {
                errorMessage = 'Database index required';
                errorDetails =
                    'Please contact support to fix the database configuration';
              } else if (snapshot.error.toString().contains('unavailable')) {
                errorMessage = 'Service unavailable';
                errorDetails =
                    'Firebase service is temporarily unavailable. Please try again later';
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      errorMessage,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      errorDetails,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {
                        // Trigger rebuild
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: const Text('Retry'),
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
                        const Color(0xFF667EEA),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Loading notifications...',
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
              return ListView(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
                children: [
                  _buildSummaryCard(0, 0, 0).animate().fadeIn(duration: 400.ms),
                  SizedBox(height: 32.h),
                  _buildEmptyState(
                    context,
                    onRefresh: _resetNotificationFilters,
                  ),
                ],
              );
            }

            final allDocs = snapshot.data!.docs;

            // Remove duplicates based on message body and sender
            final uniqueDocs =
                <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
            for (final doc in allDocs) {
              try {
                final data = doc.data();
                final from = data['from'] ?? 'Unknown';
                final body = (data['body'] ?? '').toString().trim();
                final uniqueKey = '$from|$body'; // Create unique key

                // Keep the latest one if duplicates exist, but prioritize unfixed notifications
                if (!uniqueDocs.containsKey(uniqueKey)) {
                  uniqueDocs[uniqueKey] = doc;
                } else {
                  final existingData = uniqueDocs[uniqueKey]!.data();
                  final existingTimestamp =
                      existingData['timestamp'] as Timestamp?;
                  final existingIsFixed =
                      existingData['isFixed'] as bool? ?? false;

                  final currentTimestamp = data['timestamp'] as Timestamp?;
                  final currentIsFixed = data['isFixed'] as bool? ?? false;

                  // Priority logic:
                  // 1. If existing is fixed but current is not, replace with current (unfixed)
                  // 2. If both have same fixed status, keep the latest timestamp
                  // 3. If current is fixed but existing is not, keep existing (unfixed)

                  bool shouldReplace = false;

                  if (existingIsFixed && !currentIsFixed) {
                    // Replace fixed with unfixed
                    shouldReplace = true;
                  } else if (existingIsFixed == currentIsFixed) {
                    // Same fixed status, check timestamp
                    if (currentTimestamp != null && existingTimestamp != null) {
                      if (currentTimestamp.seconds >
                          existingTimestamp.seconds) {
                        shouldReplace = true;
                      }
                    }
                  }
                  // If currentIsFixed && !existingIsFixed, keep existing (don't replace)

                  if (shouldReplace) {
                    uniqueDocs[uniqueKey] = doc;
                  }
                }
              } catch (e) {
                print('Error processing duplicate for doc ${doc.id}: $e');
              }
            }

            // Convert back to list and sort by timestamp (newest first)
            final deduplicatedDocs = uniqueDocs.values.toList();
            deduplicatedDocs.sort((a, b) {
              try {
                final aTimestamp = a.data()['timestamp'] as Timestamp?;
                final bTimestamp = b.data()['timestamp'] as Timestamp?;

                if (aTimestamp == null && bTimestamp == null) return 0;
                if (aTimestamp == null) return 1;
                if (bTimestamp == null) return -1;

                return bTimestamp.compareTo(aTimestamp); // descending
              } catch (e) {
                return 0;
              }
            });

            // Filter SMS notifications and related lights
            final allSmsDocs = deduplicatedDocs.where((doc) {
              try {
                final data = doc.data();
                final related = (data['relatedLights'] as List<dynamic>?) ?? [];
                final source = (data['source'] ?? '').toString().toLowerCase();
                return source.startsWith('sms') || related.isNotEmpty;
              } catch (e) {
                print('Error filtering doc ${doc.id}: $e');
                return false;
              }
            }).toList();

            // Separate pending and fixed notifications
            final pendingDocs = allSmsDocs.where((doc) {
              try {
                // Hide any notifications that have been locally marked fixed
                if (_locallyFixedNotificationIds.contains(doc.id)) return false;

                // Hide notifications that match a locally suppressed
                // signature (from|body). This prevents alerts the user has
                // dismissed from coming back as duplicates with new doc ids.
                final dData = doc.data();
                final dFrom = dData['from']?.toString() ?? 'Unknown';
                final dBody = (dData['body'] ?? '').toString().trim();
                final sig = '$dFrom|$dBody';
                if (_suppressedSignatures.contains(sig)) return false;

                final isFixed = doc.data()['isFixed'] as bool? ?? false;
                print('Doc ${doc.id}: isFixed = $isFixed');
                return !isFixed;
              } catch (e) {
                print('Error checking isFixed for doc ${doc.id}: $e');
                return true;
              }
            }).toList();

            // Prefetch related street light docs so we can show the
            // street light name immediately in the list (avoid 'Unknown').
            final relatedIds = <String>{};
            for (final d in pendingDocs) {
              try {
                final related =
                    (d.data()['relatedLights'] as List<dynamic>?)
                        ?.cast<String>() ??
                    [];
                relatedIds.addAll(related);
              } catch (_) {}
            }
            if (relatedIds.isNotEmpty && _failedFetches.length < 5) {
              // Only prefetch if we haven't had too many failures
              Future.microtask(() => _prefetchStreetLightDocs(relatedIds));
            }

            final fixedCount = allSmsDocs.length - pendingDocs.length;
            final totalCount = allSmsDocs.length;
            final pendingCount = pendingDocs.length;

            // Show a local OS notification for any newly added pending document
            // after the initial snapshot (to avoid showing for existing docs).
            try {
              if (!_initialNotificationsLoaded) {
                // Mark existing docs as already displayed on first load
                for (final doc in snapshot.data!.docs) {
                  _displayedNotificationIds.add(doc.id);
                }
                _initialNotificationsLoaded = true;
              } else {
                for (final change in snapshot.data!.docChanges) {
                  if (change.type == DocumentChangeType.added) {
                    final addedId = change.doc.id;

                    // Skip if already handled
                    if (_displayedNotificationIds.contains(addedId)) continue;

                    // Skip local writes that originated from this device
                    final changeData = change.doc.data();
                    final token = changeData?['createdByToken'] as String?;
                    if (token != null &&
                        token == PushNotificationService.fcmToken) {
                      _displayedNotificationIds.add(addedId);
                      continue;
                    }

                    // Only show notifications that are in the pending list (UI-visible)
                    final isInPending = pendingDocs.any((d) => d.id == addedId);
                    // Extra safety: if the signature for this incoming doc is
                    // suppressed (user already marked that alert signature
                    // fixed), skip showing a local notification and mark it
                    // as handled so we don't later try to display it.
                    final incomingData =
                        change.doc.data() ?? <String, dynamic>{};
                    final incomingFrom = (incomingData['from'] ?? 'Unknown')
                        .toString();
                    final incomingBody = (incomingData['body'] ?? '')
                        .toString()
                        .trim();
                    final incomingSig = '$incomingFrom|$incomingBody';
                    if (_suppressedSignatures.contains(incomingSig)) {
                      _displayedNotificationIds.add(addedId);
                      continue;
                    }
                    if (!isInPending) continue;

                    // Avoid showing notifications for local uncommitted writes
                    if (change.doc.metadata.hasPendingWrites) continue;

                    final data = changeData ?? <String, dynamic>{};
                    final title = (data['title'] ?? data['from'] ?? 'Alert')
                        .toString();
                    final body = (data['body'] ?? '').toString();

                    // Fire local notification (do not await to prevent UI jank)
                    PushNotificationService.displayLocalNotification(
                      title: title,
                      body: body,
                      data: data,
                    );

                    _displayedNotificationIds.add(addedId);
                  }
                }
              }
            } catch (e) {
              print('Error processing new notification changes: $e');
            }

            // Reduce debug logging frequency
            if (pendingCount > 0) {
              print(
                'NOTIFICATION DEBUG: Total SMS docs: $totalCount, Pending: $pendingCount, Fixed: $fixedCount',
              );
            }

            if (pendingDocs.isEmpty) {
              return ListView(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
                children: [
                  _buildSummaryCard(
                    totalCount,
                    pendingCount,
                    fixedCount,
                  ).animate().fadeIn(duration: 400.ms),
                  SizedBox(height: 32.h),
                  _buildEmptyState(
                    context,
                    onRefresh: _resetNotificationFilters,
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
              itemCount: pendingDocs.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: 14.h),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSummaryCard(
                    totalCount,
                    pendingCount,
                    fixedCount,
                  ).animate().fadeIn(duration: 400.ms);
                }

                final doc = pendingDocs[index - 1];
                final data = doc.data();
                final from = (data['from'] ?? '').toString();
                final body = data['body'] ?? '';
                final ts = data['timestamp'] as Timestamp?;
                final isFixed = data['isFixed'] ?? false;
                final related =
                    (data['relatedLights'] as List<dynamic>?)?.cast<String>() ??
                    [];
                // Compute a stable display title for the list — prefer any
                // server-provided lightName/title/name. If missing, try the
                // cached related street light name. We DO NOT show the raw
                // phone number in the main list to avoid flicker.
                String displayTitle;
                final rawCandidate =
                    (data['lightName'] ?? data['title'] ?? data['name']);
                if (rawCandidate != null &&
                    rawCandidate.toString().trim().isNotEmpty) {
                  displayTitle = rawCandidate.toString();
                } else if (related.isNotEmpty) {
                  final cached = _streetLightCache[related.first];
                  final cachedName = cached == null
                      ? null
                      : (cached['name'] ??
                            cached['streetLightNumber'] ??
                            cached['lightName']);
                  if (cachedName != null &&
                      cachedName.toString().trim().isNotEmpty) {
                    displayTitle = cachedName.toString();
                  } else {
                    // Show generic name while fetching street light data
                    displayTitle = 'Street Light';

                    // Only fetch if not already failed due to permissions
                    if (!_failedFetches.contains(related.first)) {
                      Future.microtask(
                        () => _fetchSingleStreetLight(related.first),
                      );
                    }
                  }
                } else {
                  displayTitle = 'Alert';
                }

                // Prepare cached related street light data so the UI can
                // render name and location synchronously without per-item
                // async work inside the widget tree.
                final cachedLight = related.isNotEmpty
                    ? _streetLightCache[related.first]
                    : null;
                final locationStr = cachedLight == null
                    ? ''
                    : (cachedLight['location'] ?? cachedLight['address'] ?? '')
                          .toString();

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
                                            data: {
                                              ...docSnapshot.data()!,
                                              'id': docSnapshot.id,
                                            },
                                          ),
                                    ),
                                  );
                                }
                              });
                        } else {
                          // Show bottom sheet if no related lights
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24.r),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, -6),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    20.w,
                                    20.h,
                                    20.w,
                                    28.h,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 40.w,
                                            height: 40.w,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF667EEA,
                                              ).withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            child: const Icon(
                                              Icons.message,
                                              color: Color(0xFF667EEA),
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  from,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16.sp,
                                                    color: const Color(
                                                      0xFF1A202C,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  _formatTimestamp(ts),
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: const Color(
                                                      0xFF718096,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          _buildStatusChip(isFixed),
                                        ],
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        body,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          height: 1.4,
                                          color: const Color(0xFF2D3748),
                                        ),
                                      ),
                                      if (related.isNotEmpty) ...[
                                        SizedBox(height: 18.h),
                                        Text(
                                          'Related Lights',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                        SizedBox(height: 10.h),
                                        FutureBuilder<
                                          List<
                                            DocumentSnapshot<
                                              Map<String, dynamic>
                                            >
                                          >
                                        >(
                                          future: Future.wait(
                                            related
                                                .map(
                                                  (id) => FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                        'street_lights',
                                                      )
                                                      .doc(id)
                                                      .get(),
                                                )
                                                .toList(),
                                          ),
                                          builder: (context, snap) {
                                            if (snap.connectionState ==
                                                ConnectionState.waiting) {
                                              return Center(
                                                child: SizedBox(
                                                  height: 48.h,
                                                  width: 48.h,
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }
                                            if (!snap.hasData ||
                                                snap.data!.isEmpty) {
                                              return Text(
                                                'No related street lights found',
                                              );
                                            }
                                            final list = snap.data!;
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ...list.map((doc) {
                                                  final d = doc.data() ?? {};
                                                  final name =
                                                      d['name'] ?? 'Unnamed';
                                                  final slNumber =
                                                      d['streetLightNumber'] ??
                                                      d['number'] ??
                                                      '';
                                                  final gsm =
                                                      d['gsmNumber'] ?? '';
                                                  return ListTile(
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    leading: Icon(
                                                      Icons.lightbulb,
                                                      color: const Color(
                                                        0xFF667EEA,
                                                      ),
                                                    ),
                                                    title: Text(
                                                      name.toString(),
                                                    ),
                                                    subtitle: Text(
                                                      'Pole: $slNumber\nGSM: $gsm',
                                                    ),
                                                    isThreeLine: true,
                                                  );
                                                }).toList(),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                      SizedBox(height: 24.h),
                                      if (!isFixed)
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              await _handleMarkAsFixed(
                                                doc.id,
                                                context,
                                                showSnackBar: false,
                                              );
                                              Navigator.pop(context);
                                            },
                                            icon: const Icon(
                                              Icons.check_circle_outline,
                                            ),
                                            label: const Text('Mark as Fixed'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF667EEA,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                vertical: 14.h,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14.r),
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10.h,
                                            horizontal: 12.w,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDEF7EC),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.verified,
                                                color: Color(0xFF047857),
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                'Fixed on site',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF047857,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48.w,
                              height: 48.w,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF667EEA),
                                    Color(0xFF764BA2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: const Icon(
                                Icons.flash_on,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Stable display title: prefer server-provided
                                            // names; do not show raw phone number here.
                                            Text(
                                              displayTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14.sp,
                                                color: const Color(0xFF1A202C),
                                              ),
                                            ),
                                            if (locationStr.isNotEmpty) ...[
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: 4.h,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      size: 12.sp,
                                                      color: const Color(
                                                        0xFF718096,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Expanded(
                                                      child: Text(
                                                        locationStr,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 12.sp,
                                                          color: const Color(
                                                            0xFF718096,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildStatusChip(isFixed),
                                          if (!isFixed) ...[
                                            SizedBox(width: 4.w),
                                            PopupMenuButton<String>(
                                              padding: EdgeInsets.zero,
                                              iconSize: 16.sp,
                                              icon: Icon(
                                                Icons.more_vert,
                                                color: Colors.grey[600],
                                                size: 16.sp,
                                              ),
                                              onSelected: (value) {
                                                if (value == 'mark_fixed') {
                                                  _handleMarkAsFixed(
                                                    doc.id,
                                                    context,
                                                  );
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'mark_fixed',
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        color: Colors.green,
                                                        size: 16.sp,
                                                      ),
                                                      SizedBox(width: 8.w),
                                                      const Text(
                                                        'Mark as Fixed',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFF4A5568),
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14.sp,
                                            color: const Color(0xFF718096),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            _formatTimestamp(ts),
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: const Color(0xFF718096),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (related.isNotEmpty)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEBF8FF),
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                          ),
                                          child: Text(
                                            '${related.length} linked',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2B6CB0),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .slideY(
                      begin: 0.08,
                      duration: 350.ms,
                      delay: ((index - 1) * 60).ms,
                    )
                    .fadeIn(duration: 350.ms);
              },
            );
          },
        ),
      ),
    );
  }
}

Future<void> _markNotificationAsFixed(
  String notificationId,
  BuildContext context, {
  bool showSnackBar = true,
  List<String>? alsoFixIds,
}) async {
  try {
    print('Marking notification as fixed: $notificationId');

    // First verify the notification exists and user owns it
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final docRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw Exception('Notification not found');
    }

    final data = docSnapshot.data();
    if (data != null && data['createdBy'] != user.uid) {
      throw Exception('Permission denied - not your notification');
    }

    // If already fixed, show info and return
    if (data != null && data['isFixed'] == true) {
      print('Notification already marked as fixed');
      if (showSnackBar && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('Notification already marked as fixed'),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    // Determine which documents to mark fixed: the provided id plus any
    // duplicates (other docs with the same from/body signature). If
    // duplicates were discovered by the caller pass them in; otherwise
    // compute them here by scanning the user's notifications.
    final idsToFix = <String>{notificationId};
    if (alsoFixIds != null && alsoFixIds.isNotEmpty) {
      idsToFix.addAll(alsoFixIds);
    } else {
      try {
        final from = data?['from']?.toString() ?? 'Unknown';
        final body = (data?['body'] ?? '').toString().trim();
        final q = await FirebaseFirestore.instance
            .collection('notifications')
            .where('createdBy', isEqualTo: user.uid)
            .get();
        for (final d in q.docs) {
          final dData = d.data();
          final dFrom = dData['from']?.toString() ?? 'Unknown';
          final dBody = (dData['body'] ?? '').toString().trim();
          if (dFrom == from && dBody == body) {
            idsToFix.add(d.id);
          }
        }
      } catch (e) {
        print('Error enumerating duplicate notifications: $e');
      }
    }

    // Batch-update all matched documents so the fix is permanent across
    // copies/duplicates and other devices.
    final batch = FirebaseFirestore.instance.batch();
    for (final id in idsToFix) {
      final r = FirebaseFirestore.instance.collection('notifications').doc(id);
      batch.update(r, {
        'isFixed': true,
        'fixedAt': FieldValue.serverTimestamp(),
        'fixedBy': user.uid,
      });
    }
    await batch.commit();

    print('Successfully marked notifications as fixed: $idsToFix');

    // Cancel the OS notification(s) so they disappear immediately from the
    // device's notification center.
    for (final id in idsToFix) {
      try {
        await PushNotificationService.cancelNotificationByDocId(id);
      } catch (e) {
        print('Error cancelling OS notification for $id: $e');
      }
    }

    if (showSnackBar && context.mounted) {
      // Clear any existing snackbars first
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Notification marked as fixed'),
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
    print('Error marking notification as fixed: $e');
    if (showSnackBar && context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error: ${e.toString()}')),
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

Widget _buildSummaryCard(int total, int pending, int fixed) {
  Widget buildStat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 6.w),
              Text(
                value.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  return Container(
    padding: EdgeInsets.all(18.w),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF667EEA), Color.fromARGB(255, 168, 136, 200)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22.r),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF667EEA).withOpacity(0.3),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Live Fault Feed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),
        Row(
          children: [
            buildStat('Total alerts', total, Colors.white),
            Container(
              width: 1.5,
              height: 40.h,
              color: Colors.white.withOpacity(0.6),
            ),
            SizedBox(width: 12.w),
            buildStat('Pending', pending, const Color(0xFFFBBF24)),
            Container(
              width: 1.5,
              height: 40.h,
              color: Colors.white.withOpacity(0.6),
            ),
            SizedBox(width: 12.w),
            buildStat('Fixed', fixed, const Color(0xFF34D399)),
          ],
        ),
      ],
    ),
  );
}

Widget _buildEmptyState(BuildContext context, {VoidCallback? onRefresh}) {
  return Container(
    padding: EdgeInsets.all(28.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72.w,
          height: 72.w,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: const Icon(
            Icons.sentiment_satisfied_alt,
            color: Color(0xFF6366F1),
            size: 36,
          ),
        ),
        SizedBox(height: 18.h),
        Text(
          'You’re all caught up!',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'We’ll alert you here if any street light reports a fault or anomaly.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            color: const Color(0xFF718096),
            height: 1.4,
          ),
        ),
        SizedBox(height: 24.h),
        ElevatedButton.icon(
          onPressed: onRefresh ?? () {},
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Feed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667EEA),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatusChip(bool isFixed) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: isFixed ? const Color(0xFFDEF7EC) : const Color(0xFFFFF4D6),
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isFixed ? Icons.check_circle : Icons.warning_amber_rounded,
          size: 14.sp,
          color: isFixed ? const Color(0xFF047857) : const Color(0xFFB7791F),
        ),
        SizedBox(width: 6.w),
        Text(
          isFixed ? 'Fixed' : 'Pending',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: isFixed ? const Color(0xFF047857) : const Color(0xFFB7791F),
          ),
        ),
      ],
    ),
  );
}
