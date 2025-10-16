import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../street_light/street_light_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final bool showAppBar;

  const NotificationsScreen({super.key, this.showAppBar = true});

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: showAppBar
          ? AppBar(
              elevation: 0,
              centerTitle: true,
              toolbarHeight: 72.h,
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
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.tune, size: 22),
                  tooltip: 'Filters',
                ),
              ],
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28.r),
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
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error loading notifications'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            // Only keep notifications that came from SMS or have relatedLights
            final smsDocs = docs.where((doc) {
              final allDocs = snapshot.data!.docs;
              final data = allDocs.firstWhere((d) => d.id == doc.id).data();
              final related = (data['relatedLights'] as List<dynamic>?) ?? [];
              final source = (data['source'] ?? '').toString().toLowerCase();
              return source.startsWith('sms') || related.isNotEmpty;
            }).toList();

            final pendingCount = smsDocs
                .where((doc) => !(doc.data()['isFixed'] as bool? ?? false))
                .length;
            final fixedCount = smsDocs.length - pendingCount;

            if (smsDocs.isEmpty) {
              return ListView(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
                children: [
                  _buildSummaryCard(
                    docs.length,
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
              itemCount: smsDocs.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: 14.h),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSummaryCard(
                    docs.length,
                    pendingCount,
                    fixedCount,
                  ).animate().fadeIn(duration: 400.ms);
                }

                final doc = smsDocs[index - 1];
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
                        // Navigate to street light detail page if related lights exist
                        if (related.isNotEmpty) {
                          // Fetch street light data and navigate
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
                                      _buildStatusChip(isFixed),
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

  Future<void> _markNotificationAsFixed(
    String notificationId,
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isFixed': true, 'fixedAt': FieldValue.serverTimestamp()});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification marked as fixed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error marking notification as fixed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
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
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
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
                width: 1.2,
                height: 40.h,
                color: Colors.white.withOpacity(0.2),
              ),
              SizedBox(width: 12.w),
              buildStat('Pending', pending, const Color(0xFFFBBF24)),
              Container(
                width: 1.2,
                height: 40.h,
                color: Colors.white.withOpacity(0.2),
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
              color: isFixed
                  ? const Color(0xFF047857)
                  : const Color(0xFFB7791F),
            ),
          ),
        ],
      ),
    );
  }
}
