import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../street_light/street_light_detail_screen.dart';
import '../history/notification_history_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late StreamController<void> _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = StreamController<void>.broadcast();
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  void _triggerRefresh() {
    _refreshController.add(null);
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
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
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 62.h,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'Fault Notifications',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
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
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
        ),
      ),
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
                  _buildEmptyState(context),
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
                final isFixed = doc.data()['isFixed'] as bool? ?? false;
                print('Doc ${doc.id}: isFixed = $isFixed');
                return !isFixed;
              } catch (e) {
                print('Error checking isFixed for doc ${doc.id}: $e');
                return true;
              }
            }).toList();

            final fixedCount = allSmsDocs.length - pendingDocs.length;
            final totalCount = allSmsDocs.length;
            final pendingCount = pendingDocs.length;

            print(
              'Total SMS docs: $totalCount, Pending: $pendingCount, Fixed: $fixedCount',
            );

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
                  _buildEmptyState(context),
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
                final from = data['from'] ?? 'Unknown';
                final body = data['body'] ?? '';
                final ts = data['timestamp'] as Timestamp?;
                final isFixed = data['isFixed'] ?? false;
                final related =
                    (data['relatedLights'] as List<dynamic>?)?.cast<String>() ??
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
                                              await _markNotificationAsFixed(
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
                                        child: related.isNotEmpty
                                            ? FutureBuilder<
                                                DocumentSnapshot<
                                                  Map<String, dynamic>
                                                >
                                              >(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .collection('street_lights')
                                                    .doc(related.first)
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData) {
                                                    return Text(
                                                      from,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 14.sp,
                                                        color: const Color(
                                                          0xFF1A202C,
                                                        ),
                                                      ),
                                                    );
                                                  }

                                                  final lightData = snapshot
                                                      .data
                                                      ?.data();
                                                  final lightName =
                                                      lightData?['name'] ??
                                                      from;
                                                  final location =
                                                      lightData?['location'] ??
                                                      lightData?['address'] ??
                                                      '';

                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        lightName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 14.sp,
                                                          color: const Color(
                                                            0xFF1A202C,
                                                          ),
                                                        ),
                                                      ),
                                                      if (location
                                                          .isNotEmpty) ...[
                                                        SizedBox(height: 2.h),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.location_on,
                                                              size: 12.sp,
                                                              color:
                                                                  const Color(
                                                                    0xFF718096,
                                                                  ),
                                                            ),
                                                            SizedBox(
                                                              width: 2.w,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                location,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      12.sp,
                                                                  color: const Color(
                                                                    0xFF718096,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ],
                                                  );
                                                },
                                              )
                                            : Text(
                                                from,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14.sp,
                                                  color: const Color(
                                                    0xFF1A202C,
                                                  ),
                                                ),
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
                                                  _markNotificationAsFixed(
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
}) async {
  try {
    print('Marking notification as fixed: $notificationId');

    // First verify the notification exists and user owns it
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final docSnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .get();

    if (!docSnapshot.exists) {
      throw Exception('Notification not found');
    }

    final data = docSnapshot.data();
    if (data != null && data['createdBy'] != user.uid) {
      throw Exception('Permission denied - not your notification');
    }

    // Check if already fixed
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

    // Update the notification to fixed status
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({
          'isFixed': true,
          'fixedAt': FieldValue.serverTimestamp(),
          'fixedBy': user.uid,
        });

    print('Successfully marked notification $notificationId as fixed');

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

// Method to delete all notifications for current user
Future<void> _deleteAllNotifications(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final notifications = await FirebaseFirestore.instance
        .collection('notifications')
        .where('createdBy', isEqualTo: user.uid)
        .where('isFixed', isEqualTo: false)
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
              Text('All notifications deleted successfully'),
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
              Text('Error deleting notifications'),
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

Widget _buildEmptyState(BuildContext context) {
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
          onPressed: () {},
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
