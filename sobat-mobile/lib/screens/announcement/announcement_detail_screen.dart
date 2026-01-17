import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const AnnouncementDetailScreen({super.key, required this.item});

  Future<void> _downloadAttachment(String url) async {
    final fullUrl = url.startsWith('http')
        ? url
        : '${ApiConfig.baseUrl}/storage/$url'; // Adjust based on storage link
    // Note: storage link usually needs correct base URL.
    // If backend returns full URL, use it. If relative, prepend.
    // Our Controller returns Storage::url($path) which is usually /storage/path.
    // So we need ApiConfig.baseUrl (without /api) + url.
    // But let's assume ApiConfig.baseUrl is http://10.0.2.2:8000/api
    // We need http://10.0.2.2:8000 + url.

    String downloadUrl = url;
    if (!url.startsWith('http')) {
      final baseUrlObj = Uri.parse(ApiConfig.baseUrl);
      final rootUrl = '${baseUrlObj.scheme}://${baseUrlObj.authority}';
      downloadUrl = '$rootUrl$url';
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
      appBar: AppBar(
        title: Text(isNews ? 'Detail Pengumuman' : 'Detail Kebijakan'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isNews ? Colors.blue[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isNews ? 'PENGUMUMAN' : 'KEBIJAKAN HR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isNews ? Colors.blue : Colors.orange,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item['title'] ?? 'No Title',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Content
            Text(
              item['content'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF4A5568),
              ),
            ),

            // Attachment
            if (item['attachment_url'] != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.file_present,
                      color: AppTheme.colorEggplant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lampiran',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            'Ketuk untuk mengunduh',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _downloadAttachment(item['attachment_url']),
                      icon: const Icon(
                        Icons.download_rounded,
                        color: AppTheme.colorEggplant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
