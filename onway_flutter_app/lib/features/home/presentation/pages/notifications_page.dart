import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_top_bar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _api = BuyerApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _todayNotifications = [];
  List<Map<String, dynamic>> _earlierNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await _api.getNotifications();
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final today = (data['today'] as List?) ?? [];
        final earlier = (data['earlier'] as List?) ?? [];

        setState(() {
          _todayNotifications = today.map<Map<String, dynamic>>((n) => {
            'id': n['id'],
            'title': n['title'] ?? 'Notification',
            'description': n['body'] ?? '',
            'time': 'Today',
            'isUnread': !(n['isRead'] ?? false),
          }).toList();

          _earlierNotifications = earlier.map<Map<String, dynamic>>((n) => {
            'id': n['id'],
            'title': n['title'] ?? 'Notification',
            'description': n['body'] ?? '',
            'time': 'Earlier',
            'isUnread': !(n['isRead'] ?? false),
          }).toList();

          _isLoading = false;
        });
      } else {
        setState(() {
          _todayNotifications = _fallbackToday.map((n) => Map<String, dynamic>.from(n)).toList();
          _earlierNotifications = _fallbackEarlier.map((n) => Map<String, dynamic>.from(n)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _todayNotifications = _fallbackToday.map((n) => Map<String, dynamic>.from(n)).toList();
        _earlierNotifications = _fallbackEarlier.map((n) => Map<String, dynamic>.from(n)).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (var n in _todayNotifications) {
        n['isUnread'] = false;
      }
      for (var n in _earlierNotifications) {
        n['isUnread'] = false;
      }
    });
    await _api.markNotificationsAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                const StandardTopBar(
                  title: 'Notifications',
                  subtitle: 'Stay updated',
                  icon: Icons.notifications_outlined,
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: _markAllRead,
                          child: Text(
                            'Mark all as read',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_todayNotifications.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: _SectionHeader(title: 'Today'),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final n = _todayNotifications[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: _NotificationCard(
                            title: n['title'],
                            description: n['description'],
                            time: n['time'],
                            icon: Icons.storefront,
                            isUnread: n['isUnread'],
                          ),
                        );
                      },
                      childCount: _todayNotifications.length,
                    ),
                  ),
                ],

                if (_earlierNotifications.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: _SectionHeader(title: 'Earlier'),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final n = _earlierNotifications[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: _NotificationCard(
                            title: n['title'],
                            description: n['description'],
                            time: n['time'],
                            icon: Icons.notifications,
                            isUnread: n['isUnread'],
                          ),
                        );
                      },
                      childCount: _earlierNotifications.length,
                    ),
                  ),
                ],

                // Bento Style Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -40, top: -40,
                            child: Container(
                              width: 150, height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.onPrimaryContainer.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text('RECOMMENDED', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onPrimaryContainer, letterSpacing: 0.5
                                )),
                              ),
                              const SizedBox(height: 12),
                              Text('Discover New Markets', style: GoogleFonts.plusJakartaSans(
                                fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onPrimaryContainer
                              )),
                              const SizedBox(height: 4),
                              Text('Explore artisan clusters opening near your work route today.', style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, color: AppColors.onPrimaryContainer.withValues(alpha: 0.9)
                              )),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.onPrimaryContainer,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: Text('Explore Hubs', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.bold
                                )),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  static const _fallbackToday = [
    {
      'title': 'Green Valley Hub is LIVE! 🥦',
      'description': 'Your favorite vendor is now active and 1.2 km away.',
      'time': '2m ago',
      'isUnread': true,
    },
    {
      'title': 'Order Arriving Soon',
      'description': 'Your order from Artisan Bakes is 5 mins away.',
      'time': '15m ago',
      'isUnread': true,
    },
  ];

  static const _fallbackEarlier = [
    {
      'title': 'Promo: Farm Fresh',
      'description': 'Get 20% off all organic veggies today.',
      'time': '2h ago',
      'isUnread': false,
    },
    {
      'title': 'Order Delivered',
      'description': 'Your order from Ocean Catch was delivered successfully.',
      'time': '5h ago',
      'isUnread': false,
    },
  ];
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(), style: GoogleFonts.plusJakartaSans(
      fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, letterSpacing: 1.2
    ));
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final bool isUnread;

  const _NotificationCard({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.secondaryContainer.withValues(alpha: 0.2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUnread ? AppColors.secondaryContainer.withValues(alpha: 0.5) : AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isUnread ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: isUnread ? AppColors.secondary : AppColors.tertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(time, style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant
                    )),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.3
                )),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            )
          ]
        ],
      ),
    );
  }
}
