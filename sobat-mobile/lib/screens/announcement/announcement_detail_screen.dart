import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const AnnouncementDetailScreen({super.key, required this.item});

  /// Helper to construct storage URL safely
  String? _getImageUrl(dynamic imagePath) {
    if (imagePath == null || imagePath.toString().isEmpty) return null;

    String path = imagePath.toString();

    // If already a full URL, return as-is
    if (path.startsWith('http')) return path;

    // Get base URL without /api
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');

    // Remove leading slash if present
    if (path.startsWith('/')) path = path.substring(1);

    // Remove 'storage/' prefix if already present to avoid duplication
    if (path.startsWith('storage/')) path = path.substring(8);

    return '$baseUrl/storage/$path';
  }

  Future<void> _downloadAttachment(String url) async {
    String downloadUrl = url;
    if (!url.startsWith('http')) {
      final baseUrlObj = Uri.parse(ApiConfig.baseUrl);
      final rootUrl = '${baseUrlObj.scheme}://${baseUrlObj.authority}';

      // Ensure url starts with / if not present
      var safePath = url.startsWith('/') ? url : '/$url';

      // Add /storage prefix if not present and not starting with http
      if (!safePath.startsWith('/storage')) {
        safePath = '/storage$safePath';
      }

      downloadUrl = '$rootUrl$safePath';
    }

    final uri = Uri.parse(downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Handle error
      debugPrint('Could not launch $downloadUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(item['created_at']);
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(date);
    final isNews = item['category'] == 'news';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Dynamic Gradient Header
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isNews
                    ? [
                        AppTheme.colorEggplant,
                        AppTheme.colorEggplant.withValues(alpha: 0.8),
                      ]
                    : [Colors.orange.shade800, Colors.orange.shade600],
              ),
            ),
            child: Stack(
              children: [
                // Decorative Circles
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Custom App Bar (Back Button)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. Header Content (Title & Category)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isNews ? 'PENGUMUMAN' : 'KEBIJAKAN HR',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. White Scrollable Content Container
          Padding(
            padding: const EdgeInsets.only(top: 260),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Image Logic Here ---
                    if (_getImageUrl(item['image_path']) != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _getImageUrl(item['image_path'])!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) =>
                                const SizedBox.shrink(),
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[100],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.colorEggplant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // Content Body
                    Text(
                      item['content'] ?? item['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Color(0xFF2D3748), // Cool Gray
                      ),
                    ),

                    if (item['attachment_url'] != null &&
                        item['attachment_url'].toString().isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Container(
                        clipBehavior:
                            Clip.hardEdge, // Ensure ripple respects radius
                        decoration: BoxDecoration(
                          color: isNews
                              ? Colors.blue.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isNews
                                ? Colors.blue.shade100
                                : Colors.orange.shade100,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                _downloadAttachment(item['attachment_url']),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.file_present_rounded,
                                      color: isNews
                                          ? Colors.blue
                                          : Colors.orange,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Dokumen Lampiran',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Ketuk untuk melihat atau mengunduh',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_circle_down_rounded,
                                    color: isNews ? Colors.blue : Colors.orange,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
