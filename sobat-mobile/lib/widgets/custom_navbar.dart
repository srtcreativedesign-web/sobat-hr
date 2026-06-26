import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../config/theme.dart';

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: CurvedNavigationBar(
        index: currentIndex > 4 ? 0 : currentIndex,
        height: 65.0,
        items: <Widget>[
          Icon(Icons.dashboard_rounded, size: 28, color: currentIndex == 0 ? Colors.white : AppTheme.textLight),
          Icon(Icons.folder_open_rounded, size: 28, color: currentIndex == 1 ? Colors.white : AppTheme.textLight),
          Icon(Icons.add_circle_rounded, size: 40, color: currentIndex == 2 ? Colors.white : AppTheme.colorPrimary),
          Icon(Icons.school_rounded, size: 28, color: currentIndex == 3 ? Colors.white : AppTheme.textLight),
          Icon(Icons.person_rounded, size: 28, color: currentIndex == 4 ? Colors.white : AppTheme.textLight),
        ],
        color: const Color(0xFFEBF9FF),
        buttonBackgroundColor: AppTheme.colorPrimary,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOutCubic,
        animationDuration: const Duration(milliseconds: 550),
        letIndexChange: (index) => true,
        onTap: onTap,
      ),
    );
  }
}
