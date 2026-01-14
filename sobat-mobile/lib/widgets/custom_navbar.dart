import 'dart:ui';
import 'package:flutter/material.dart';
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.colorCyan.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.colorCyan.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Side
              Row(
                children: [
                  _buildNavItem(Icons.dashboard_rounded, 0, context),
                  const SizedBox(width: 12),
                  _buildNavItem(Icons.folder_open_rounded, 1, context),
                ],
              ),

              // Spacer for the Floating FAB (which is now in HomeScreen)
              const SizedBox(width: 48),

              // Right Side
              Row(
                children: [
                  _buildNavItem(
                    Icons.account_balance_wallet_rounded,
                    3,
                    context,
                  ),
                  const SizedBox(width: 12),
                  _buildNavItem(Icons.person_rounded, 4, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, BuildContext context) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.colorEggplant : AppTheme.textLight,
              size: 26,
            ),
            const SizedBox(height: 4),
            Container(
              height: 4,
              width: 4,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.colorEggplant : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
