import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../announcement/announcement_detail_screen.dart';

class AnnouncementsSection extends StatefulWidget {
  final List<Map<String, dynamic>> announcements;
  final bool isLoadingAnnouncements;

  const AnnouncementsSection({
    super.key,
    required this.announcements,
    required this.isLoadingAnnouncements,
  });

  @override
  State<AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<AnnouncementsSection> {
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentAnnouncementIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant AnnouncementsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart timer if announcements changed
    if (widget.announcements.length != oldWidget.announcements.length) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _carouselTimer?.cancel();
    if (widget.announcements.length > 1) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_pageController.hasClients) {
          int nextPage = _currentAnnouncementIndex + 1;
          if (nextPage >= widget.announcements.length) {
            nextPage = 0;
          }
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.latestInformation,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/announcements');
              },
              child: Text(
                AppLocalizations.of(context)!.seeAll,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorEggplant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.isLoadingAnnouncements)
          const Center(child: CircularProgressIndicator())
        else if (widget.announcements.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.noLatestAnnouncement,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.announcements.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentAnnouncementIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = widget.announcements[index];
                    final isNews = item['category'] == 'news';
                    final imagePath = item['image_path'];
                    final imageUrl = ApiConfig.getStorageUrl(imagePath);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: imageUrl == null
                            ? LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: isNews
                                    ? [
                                        AppTheme.colorEggplant.withValues(
                                          alpha: 0.9,
                                        ),
                                        AppTheme.colorEggplant.withValues(
                                          alpha: 0.7,
                                        ),
                                      ]
                                    : [
                                        Colors.orange.shade800,
                                        Colors.orange.shade600,
                                      ],
                              )
                            : null,
                        image: imageUrl != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(imageUrl),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.3),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Gradient Overlay for Image
                          if (imageUrl != null)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.colorEggplant.withValues(
                                      alpha: 0.9,
                                    ),
                                  ],
                                  stops: const [0.3, 1.0],
                                ),
                              ),
                            ),

                          // Decorative Circles (Only if no image)
                          if (imageUrl == null) ...[
                            Positioned(
                              right: -10,
                              top: -10,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -30,
                              right: -10,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                            ),
                          ],

                          // Main Content
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AnnouncementDetailScreen(item: item),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isNews
                                            ? AppLocalizations.of(context)!.newsLabel
                                            : AppLocalizations.of(context)!.importantLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      item['title'] ?? AppLocalizations.of(context)!.announcementLabel,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.readMore,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.announcements.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentAnnouncementIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentAnnouncementIndex == index
                          ? AppTheme.colorEggplant
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
      ],
    );
  }
}
