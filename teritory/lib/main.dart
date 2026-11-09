import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/services/teritory_data_service.dart';
import 'core/theme/teritory_theme.dart';
import 'features/community/presentation/community_screen.dart';
import 'features/home/presentation/home_map_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/wonders/presentation/wonders_catalog_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TeritoryDataService.instance.initialize();
  runApp(const TeritoryApp());
}

class TeritoryApp extends StatelessWidget {
  const TeritoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teritory',
      debugShowCheckedModeBanner: false,
      theme: TeritoryTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeMapScreen(),
    CommunityScreen(),
    WondersCatalogScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.explore_rounded, 'Explore Map'),
                _buildNavItem(1, Icons.groups_rounded, 'Community'),
                _buildNavItem(2, Icons.military_tech_rounded, 'Wonders'),
                _buildNavItem(3, Icons.person_pin_rounded, 'My Footprint'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? TeritoryColors.primaryLight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? TeritoryColors.primary
                  : TeritoryColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? TeritoryColors.primary
                    : TeritoryColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
