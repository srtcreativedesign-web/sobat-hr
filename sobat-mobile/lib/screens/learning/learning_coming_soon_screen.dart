import 'package:flutter/material.dart';
import '../../config/theme.dart';

class LearningComingSoonScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const LearningComingSoonScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.colorPrimary,
        elevation: 0,
        centerTitle: true,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: onBack,
              )
            : const SizedBox.shrink(),
        title: const Text(
          'Knowledge Hub',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.colorPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 80,
                color: AppTheme.colorPrimary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Segera Hadir!\nPusat Kemudahan Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kami sedang menyiapkan Knowledge Hub cerdas untuk membantu pekerjaan harian Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            
            // Feature Highlights
            _buildFeatureItem(
              icon: Icons.search_rounded,
              title: 'Pencarian SOP Cepat',
              description: 'Temukan panduan operasional dalam < 3 detik saat bertugas.',
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              icon: Icons.flash_on_rounded,
              title: 'Daily Micro-Quiz',
              description: 'Tingkatkan kompetensi harian tanpa menjadi beban.',
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              icon: Icons.military_tech_rounded,
              title: 'Kumpulkan XP & Reward',
              description: 'Tingkatkan status penguasaan skill Anda menjadi Expert!',
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.colorSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.colorPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
