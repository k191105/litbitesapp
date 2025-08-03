import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'quote.dart';
import 'quote_service.dart';
import 'browse_hub.dart';
import 'about.dart';
import 'learn_hub.dart';
import 'profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'srs_service.dart';
import 'package:flutter/services.dart';
import 'package:quotes_app/recommendation_service.dart';
import 'package:flutter/rendering.dart';
import 'onboarding_page.dart';
import 'post_onboarding_sequence.dart';
import 'info_card.dart';
import 'services/notification_service.dart';
import 'services/streak_service.dart';
import 'widgets/streak_island.dart';
import 'widgets/milestone_celebration.dart';

class _InfoCardModel {
  final String id;
  const _InfoCardModel({required this.id});
}

class QuoteApp extends StatefulWidget {
  final String? quoteId;
  const QuoteApp({super.key, this.quoteId});

  @override
  QuoteAppState createState() => QuoteAppState();
}

class QuoteAppState extends State<QuoteApp> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  final SRSService _srsService = SRSService();
  final StreakService _streakService = StreakService();
  late ScrollController _detailsScrollController;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartAnimation;

  bool _showStreakIsland = false;
  String _streakMessage = '';
  List<Map<String, dynamic>> _weeklyView = [];
  String? _celebrationType; // 'confetti' or 'fireworks'

  List<Quote> _quotes = [];
  List<Quote> _allQuotes = [];
  final List<Quote> _favoriteQuotes = [];
  final Set<String> _selectedTags = <String>{};
  final Set<String> _seenQuoteIds = <String>{};
  final Map<String, int> _likeCounts = <String, int>{};
  final Map<String, int> _viewCounts = <String, int>{};
  final Set<String> _preferredAuthors = <String>{};
  final Set<String> _preferredTags = <String>{};
  final Set<String> _selectedAuthors = <String>{};
  bool _isFavoritesMode = false;
  bool _isPersonalizedMode = true;
  final Set<String> _infoCardIds = <String>{};
  List<dynamic> _pageViewItems = [];

  bool _isDarkMode = false;
  bool _isSecondPageVisible = false;
  bool _isLoading = true;
  bool _hasExploredLearn = false;
  bool _hasExploredBrowse = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _detailsScrollController = ScrollController();
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartAnimation = CurvedAnimation(
      parent: _heartAnimationController,
      curve: Curves.elasticOut,
    );

    _heartAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _heartAnimationController.reverse();
          }
        });
      }
    });
    _loadQuotes();
    _handleAppLaunch();
  }

  Future<void> _handleAppLaunch() async {
    final result = await _streakService.recordAppLaunch();
    final isNewEngagement = result['isNewEngagement'] as bool;

    if (isNewEngagement) {
      final currentStreak = result['currentStreak'] as int;
      final isNewStreak = result['isNewStreak'] as bool;
      final milestone = result['milestone'] as String?;

      setState(() {
        _streakMessage = isNewStreak
            ? 'New Streak Started'
            : '$currentStreak Day Streak!';
        _weeklyView = result['weeklyView'] as List<Map<String, dynamic>>;
        _showStreakIsland = true;
        _celebrationType = milestone;
      });

      // Show celebration overlay if applicable
      if (milestone != null) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _showCelebrationOverlay();
          }
        });
      }
    }
  }

  void _showCelebrationOverlay() {
    if (_celebrationType == null) return;

    setState(() {
      // The overlay will be shown in the UI build method
    });

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _celebrationType = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _detailsScrollController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    try {
      final quotes = await QuoteService.loadQuotes();
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('favoriteQuoteIds') ?? [];
      final likeCountsJson = prefs.getString('likeCounts');
      if (likeCountsJson != null) {
        final decodedMap = json.decode(likeCountsJson) as Map<String, dynamic>;
        _likeCounts.addAll(
          decodedMap.map((key, value) => MapEntry(key, value as int)),
        );
      }
      final viewCountsJson = prefs.getString('viewCounts');
      if (viewCountsJson != null) {
        final decodedMap = json.decode(viewCountsJson) as Map<String, dynamic>;
        _viewCounts.addAll(
          decodedMap.map((key, value) => MapEntry(key, value as int)),
        );
      }

      _isPersonalizedMode = prefs.getBool('personalizedSuggestions') ?? true;

      setState(() {
        _allQuotes = quotes;
        _quotes = List.from(quotes)..shuffle();
        _favoriteQuotes.addAll(
          _allQuotes.where((q) => favoriteIds.contains(q.id)),
        );
        _isLoading = false;
      });
      _applyFilters();
      if (widget.quoteId != null) {
        final index = _quotes.indexWhere((q) => q.id == widget.quoteId);
        if (index != -1) {
          // Use a post-frame callback to ensure the PageView is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(index);
              _showSecondPage();
            }
          });
        }
      }
      NotificationService.scheduleForToday(
        feed: _quotes,
        favoriteQuotes: _favoriteQuotes,
        now: DateTime.now(),
      );
      await _showOnboardingIfNeeded();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading quotes: $e')));
      }
    }
  }

  Future<void> _showOnboardingIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasOnboarded = prefs.getBool('hasOnboarded') ?? false;

    if (!hasOnboarded && mounted) {
      final result = await Navigator.of(context).push<OnboardingResult>(
        MaterialPageRoute(
          builder: (context) => OnboardingPage(allQuotes: _allQuotes),
          fullscreenDialog: true,
        ),
      );

      if (result != null) {
        // Show the post-onboarding sequence
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostOnboardingSequence(
              onFinished: () {
                Navigator.of(context).pop();
              },
            ),
            fullscreenDialog: true,
          ),
        );

        setState(() {
          if (result.selectedTags.isNotEmpty) {
            _preferredTags.addAll(result.selectedTags);
          }
          if (result.selectedAuthors.isNotEmpty) {
            _preferredAuthors.addAll(result.selectedAuthors);
          }
        });
        // Re-apply filters to kick-start recommendations with new preferences
        _applyFilters();
      }

      // After onboarding is complete, set the flag
      await prefs.setBool('hasOnboarded', true);
    }
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _showSecondPage() {
    if (_detailsScrollController.hasClients) {
      _detailsScrollController.jumpTo(0);
    }
    setState(() {
      _isSecondPageVisible = true;
    });
  }

  void _hideSecondPage() {
    setState(() {
      _isSecondPageVisible = false;
    });
  }

  void _nextQuote() {
    if (_quotes.isNotEmpty) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuote() {
    if (_quotes.isNotEmpty) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleFavorite() {
    if (_quotes.isEmpty) return;
    HapticFeedback.lightImpact();
    final currentQuote = _quotes[_currentIndex];

    _heartAnimationController.forward(from: 0.0);

    setState(() {
      if (!_favoriteQuotes.contains(currentQuote)) {
        _favoriteQuotes.add(currentQuote);
        _srsService.addQuote(currentQuote.id);
      }
      _likeCounts.update(
        currentQuote.id,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      _saveFavorites();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = _favoriteQuotes.map((q) => q.id).toList();
    await prefs.setStringList('favoriteQuoteIds', favoriteIds);
    await prefs.setString('likeCounts', json.encode(_likeCounts));
  }

  Future<void> _saveViewCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('viewCounts', json.encode(_viewCounts));
  }

  void _toggleFavoriteFromBar() {
    if (_quotes.isEmpty) return;
    HapticFeedback.lightImpact();
    final currentQuote = _quotes[_currentIndex];

    setState(() {
      if (_favoriteQuotes.contains(currentQuote)) {
        _favoriteQuotes.remove(currentQuote);
        _likeCounts.remove(currentQuote.id);
        _srsService.removeQuote(currentQuote.id);
      } else {
        _favoriteQuotes.add(currentQuote);
        _likeCounts[currentQuote.id] = 1;
        _srsService.addQuote(currentQuote.id);
        _heartAnimationController.forward(from: 0.0);
      }
      _saveFavorites();
    });
  }

  double _getFontSize(String text) {
    if (text.length > 300) return 20.0;
    if (text.length > 200) return 22.0;
    if (text.length > 120) return 24.0;
    if (text.length > 80) return 26.0;
    return 28.0;
  }

  double _getSourceFontSize(String source) {
    if (source.length > 100) return 15.0;
    if (source.length > 80) return 16.0;
    if (source.length > 60) return 17.0;
    return 18.0;
  }

  Widget _buildQuoteCard(Quote quote) {
    return GestureDetector(
      onDoubleTap: _toggleFavorite,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: double.infinity,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 32.0,
                        bottom: 10.0,
                        top: 32.0,
                        right: 32.0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          quote.text,
                          style: TextStyle(
                            fontSize: _getFontSize(quote.text),
                            fontWeight: FontWeight.w500,
                            fontFamily: "EBGaramond",
                            color: _isDarkMode ? Colors.white : Colors.black,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 32.0,
                        right: 32.0,
                        top: 10.0,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '— ${quote.authorInfo}',
                          style: TextStyle(
                            fontSize: _getSourceFontSize(quote.authorInfo),
                            fontWeight: FontWeight.w300,
                            color: const Color.fromARGB(255, 166, 165, 165),
                            fontFamily: "EBGaramond",
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                    if (quote.displaySource.isNotEmpty) ...[
                      const SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0, right: 32.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            quote.displaySource,
                            style: TextStyle(
                              fontSize:
                                  _getSourceFontSize(quote.displaySource) - 2,
                              fontWeight: FontWeight.w300,
                              color: const Color.fromARGB(255, 140, 140, 140),
                              fontFamily: "EBGaramond",
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Tags as chips
                    OutlinedButton(
                      onPressed: _showSecondPage,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        side: BorderSide(
                          width: 0.5,
                          color: _isDarkMode ? Colors.white54 : Colors.black54,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                      ),
                      child: Text(
                        'Read more »',
                        style: TextStyle(
                          fontFamily: "EBGaramond",
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _heartAnimation,
            child: ScaleTransition(
              scale: _heartAnimation,
              child: Icon(
                Icons.favorite,
                size: 120,
                color: Colors.red.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharableQuoteCard(Quote quote) {
    return Material(
      color: _isDarkMode
          ? Colors.black
          : const Color.fromARGB(255, 240, 234, 225),
      child: Container(
        padding: const EdgeInsets.all(32.0),
        child: _buildQuoteCard(quote),
      ),
    );
  }

  Widget _buildDetailsCard(Quote quote) {
    return SingleChildScrollView(
      controller: _detailsScrollController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote Text
            Text(
              '"${quote.text}"',
              style: TextStyle(
                fontFamily: "EBGaramond",
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: _isDarkMode ? Colors.white : Colors.black,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Interpretation Section
            if (quote.interpretation != null &&
                quote.interpretation!.isNotEmpty) ...[
              Text(
                'Interpretation',
                style: TextStyle(
                  fontFamily: 'EBGaramond',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                quote.interpretation!,
                style: TextStyle(
                  fontFamily: 'EBGaramond',
                  fontSize: 16,
                  height: 1.6,
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.85)
                      : Colors.black.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 32),
            ],

            const Divider(),
            const SizedBox(height: 24),

            // Metadata sections
            _buildDetailSection('Author', quote.authorInfo),
            if (quote.displaySource.isNotEmpty)
              _buildDetailSection('Source', quote.displaySource),
            if (quote.sourceBlurb != null && quote.sourceBlurb!.isNotEmpty)
              _buildDetailSection('Source Note', quote.sourceBlurb!),

            const SizedBox(height: 24),

            // Tags
            if (quote.tags.isNotEmpty)
              _buildTagsDetailSection('Tags', quote.tags),

            const SizedBox(height: 48),

            // Back button
            Center(
              child: OutlinedButton(
                onPressed: _hideSecondPage,
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    width: 0.2,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                child: Text(
                  '« Back to Quote',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'EBGaramond',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontSize: 15,
              fontFamily: 'EBGaramond',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag, {void Function(String)? onTap}) {
    final bool isSelected = _selectedTags.contains(tag);

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap(tag);
        } else {
          _toggleTagFilter(tag);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? (_isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.15))
              : (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.6)
                : (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.3),
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: TextStyle(
                color: isSelected
                    ? (_isDarkMode ? Colors.white : Colors.black)
                    : (_isDarkMode ? Colors.white70 : Colors.black87),
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'EBGaramond',
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6.0),
              Icon(
                Icons.close,
                size: 14.0,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleTagFilter(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
      _isFavoritesMode = false;
    });
    _applyFilters();
  }

  void _toggleAuthorFilter(String authorName) {
    setState(() {
      if (_selectedAuthors.contains(authorName)) {
        _selectedAuthors.remove(authorName);
      } else {
        _selectedAuthors.add(authorName);
      }
      _isFavoritesMode = false;
    });
    _applyFilters();
  }

  void _clearFilter() {
    setState(() {
      _selectedTags.clear();
      _selectedAuthors.clear();
      _isFavoritesMode = false;
    });
    _applyFilters();
  }

  void _applyTagFilter(Set<String> selectedTags) {
    setState(() {
      _selectedTags.clear();
      _selectedTags.addAll(selectedTags);
      _isFavoritesMode = false;
    });
    _applyFilters();
  }

  void _applyAuthorFilter(Set<String> selectedAuthors) {
    setState(() {
      _selectedAuthors.clear();
      _selectedAuthors.addAll(selectedAuthors);
      _isFavoritesMode = false;
    });
    _applyFilters();
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _isFavoritesMode = !_isFavoritesMode;
      if (_isFavoritesMode) {
        _selectedTags.clear();
        _selectedAuthors.clear();
      }
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      final sessionSeed = DateTime.now().millisecondsSinceEpoch;
      List<Quote> baseQuotes;
      if (_isFavoritesMode) {
        baseQuotes = _favoriteQuotes;
      } else {
        baseQuotes = _allQuotes;
      }

      final totalViews = _viewCounts.values.fold(
        0,
        (sum, count) => sum + count,
      );

      List<Quote> filteredQuotes;
      if (_isPersonalizedMode && _selectedTags.isEmpty && !_isFavoritesMode) {
        final recommendationService = RecommendationService(
          allQuotes: _allQuotes,
          favoriteQuotes: _favoriteQuotes,
          likeCounts: _likeCounts,
          viewCounts: _viewCounts,
          totalViews: totalViews,
          preferredAuthors: _preferredAuthors,
          preferredTags: _preferredTags,
          sessionSeed: sessionSeed,
        );
        filteredQuotes = recommendationService.getRecommendations();
      } else if (_selectedTags.isEmpty) {
        filteredQuotes = List.from(baseQuotes);
        // Reverse favorites to show most recently favorited first
        if (_isFavoritesMode) {
          filteredQuotes = filteredQuotes.reversed.toList();
        }
      } else {
        filteredQuotes = baseQuotes.where((quote) {
          return _selectedTags.every(
            (selectedTag) => quote.tags.contains(selectedTag),
          );
        }).toList();
        // Reverse favorites to show most recently favorited first
        if (_isFavoritesMode) {
          filteredQuotes = filteredQuotes.reversed.toList();
        }
      }

      if (_selectedAuthors.isNotEmpty) {
        filteredQuotes = filteredQuotes
            .where((quote) => _selectedAuthors.contains(quote.authorName))
            .toList();
        // Reverse favorites to show most recently favorited first
        if (_isFavoritesMode) {
          filteredQuotes = filteredQuotes.reversed.toList();
        }
      }

      if (!_isFavoritesMode && !_isPersonalizedMode) {
        filteredQuotes.shuffle();
      }

      _quotes = filteredQuotes;
      _pageViewItems = List.from(_quotes);
      _currentIndex = 0;
      _isSecondPageVisible = false;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  Future<void> _shareQuoteAsImage() async {
    final screenshotController = ScreenshotController();
    final quoteToShare = _quotes[_currentIndex];

    final image = await screenshotController.captureFromWidget(
      _buildSharableQuoteCard(quoteToShare),
      pixelRatio: MediaQuery.of(context).devicePixelRatio,
      context: context,
    );

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await File('${directory.path}/quote.png').create();
    await imagePath.writeAsBytes(image);

    await Share.shareXFiles([XFile(imagePath.path)]);
  }

  void _navigateToProfile() async {
    final currentStreak = await _streakService.getCurrentWeekStreak();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          seenQuotesCount: _seenQuoteIds.length,
          favoriteQuotesCount: _favoriteQuotes.length,
          favoriteQuotes: _favoriteQuotes,
          seenQuotes: _allQuotes
              .where((q) => _seenQuoteIds.contains(q.id))
              .toList(),
          isDarkMode: _isDarkMode,
          currentStreak: currentStreak,
        ),
      ),
    );
  }

  void _navigateToLearn() {
    if (_favoriteQuotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have no favorites to learn from yet!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      setState(() {
        _hasExploredLearn = true;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LearnHubPage(
            isDarkMode: _isDarkMode,
            allQuotes: _allQuotes,
            favoriteQuotes: _favoriteQuotes,
            viewCounts: _viewCounts,
          ),
        ),
      );
    }
  }

  void _navigateToBrowse() async {
    setState(() {
      _hasExploredBrowse = true;
    });
    final result = await Navigator.push<Map<String, Set<String>>>(
      context,
      MaterialPageRoute(
        builder: (context) => BrowseHubPage(
          allQuotes: _allQuotes,
          initialSelectedTags: _selectedTags,
          isDarkMode: _isDarkMode,
          initialSelectedAuthors: _selectedAuthors,
        ),
      ),
    );
    if (result != null && mounted) {
      // This part might need adjustment depending on what BrowseHubPage returns.
      // Assuming it can return a map like {'tags': Set<String>} or {'authors': Set<String>}.
      if (result.containsKey('tags')) {
        _applyTagFilter(result['tags']!);
      } else if (result.containsKey('authors')) {
        _applyAuthorFilter(result['authors']!);
      }
    }
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AboutPage(isDarkMode: _isDarkMode),
      ),
    );
  }

  void _showDetailsPopup(BuildContext anchorContext) {
    final quote = _quotes[_currentIndex];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Details',
      barrierColor: Colors.black.withOpacity(0.1),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              right: 20,
              bottom: 105,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 20.0,
                  ),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? const Color.fromARGB(220, 45, 45, 45)
                        : const Color.fromARGB(240, 255, 255, 255),
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        spreadRadius: 2,
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tags Column
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Tags',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'EBGaramond',
                                  ),
                                ),
                              ),
                              if (quote.tags.isEmpty)
                                const Text(
                                  'No tags for this quote.',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontFamily: 'EBGaramond',
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: quote.tags.map((tag) {
                                    return _buildTagChip(
                                      tag,
                                      onTap: (selectedTag) {
                                        Navigator.pop(context);
                                        _toggleTagFilter(selectedTag);
                                      },
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),

                        const VerticalDivider(width: 24),

                        // Author Column
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Author',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'EBGaramond',
                                  ),
                                ),
                              ),
                              _buildAuthorChip(
                                quote.authorName,
                                onTap: (selectedAuthor) {
                                  Navigator.pop(context);
                                  _toggleAuthorFilter(selectedAuthor);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          alignment: Alignment.bottomRight,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildAuthorChip(String authorName, {void Function(String)? onTap}) {
    final bool isSelected = _selectedAuthors.contains(authorName);

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap(authorName);
        } else {
          _toggleAuthorFilter(authorName);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? (_isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.15))
              : (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.6)
                : (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.3),
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              authorName,
              style: TextStyle(
                color: isSelected
                    ? (_isDarkMode ? Colors.white : Colors.black)
                    : (_isDarkMode ? Colors.white70 : Colors.black87),
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'EBGaramond',
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6.0),
              Icon(
                Icons.close,
                size: 14.0,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagsDetailSection(String title, List<String> tags) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'EBGaramond',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: tags.map((tag) => _buildTagChip(tag)).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sync the system status bar with our app bar background to avoid the lavender tint on iOS
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
    );
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _isDarkMode
            ? Colors.black
            : const Color.fromARGB(255, 240, 234, 225),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_quotes.isEmpty) {
      final message = _isFavoritesMode
          ? 'You have no favorites yet.\nTap the heart on a quote to add it.'
          : (_allQuotes.isEmpty
                ? 'No quotes available.'
                : 'No quotes found for the selected filters.');

      return Scaffold(
        backgroundColor: _isDarkMode
            ? Colors.black
            : const Color.fromARGB(255, 240, 234, 225),
        appBar: AppBar(
          title: Text(
            '',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontFamily: 'EBGaramond',
            ),
          ),
          backgroundColor: _isDarkMode
              ? Colors.black
              : const Color.fromARGB(255, 240, 234, 225),
          elevation: 0,
          scrolledUnderElevation: 0.0,
          iconTheme: IconThemeData(
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        drawer: _buildDrawer(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'EBGaramond',
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _isDarkMode
          ? Colors.black
          : const Color.fromARGB(255, 240, 234, 225),
      body: Stack(
        children: [
          // Main content area
          Column(
            children: [
              // Main content area
              Expanded(
                child: IndexedStack(
                  index: _isSecondPageVisible ? 1 : 0,
                  children: <Widget>[
                    PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      onPageChanged: (index) {
                        if (_quotes.isNotEmpty) {
                          final item = _pageViewItems[index];
                          if (item is Quote) {
                            final quoteId = item.id;
                            setState(() {
                              _currentIndex = _quotes.indexOf(item);
                              if (!_seenQuoteIds.contains(quoteId)) {
                                _seenQuoteIds.add(quoteId);
                                _updatePageViewItems();
                              }
                            });
                            _saveViewCounts();
                            _viewCounts.update(
                              quoteId,
                              (value) => value + 1,
                              ifAbsent: () => 1,
                            );
                          }
                        }
                      },
                      itemBuilder: (context, index) {
                        if (index >= _pageViewItems.length) {
                          return Container();
                        }
                        final item = _pageViewItems[index];
                        if (item is Quote) {
                          return _buildQuoteCard(item);
                        } else if (item is _InfoCardModel) {
                          return _buildInfoCard();
                        }
                        return Container();
                      },
                      itemCount: _pageViewItems.length,
                    ),
                    _buildDetailsCard(_quotes[_currentIndex]),
                  ],
                ),
              ),

              // Bottom navigation bar
              Container(
                width: double.infinity,
                height: 100.0,
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.white38),
                  color: _isDarkMode
                      ? const Color.fromARGB(255, 239, 237, 231)
                      : const Color.fromARGB(255, 224, 222, 212),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        iconSize: 24.0,
                        color: Colors.black,
                        onPressed: _shareQuoteAsImage,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward_outlined),
                        iconSize: 24.0,
                        color: Colors.black,
                        onPressed: () {
                          _hideSecondPage();
                          _nextQuote();
                        },
                      ),
                      IconButton(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              _favoriteQuotes.contains(_quotes[_currentIndex])
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  _favoriteQuotes.contains(
                                    _quotes[_currentIndex],
                                  )
                                  ? Colors.red
                                  : Colors.black,
                            ),
                            if ((_likeCounts[_quotes[_currentIndex].id] ?? 0) >
                                1)
                              Positioned(
                                right: -8,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'x${_likeCounts[_quotes[_currentIndex].id]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        iconSize: 24.0,
                        onPressed: _toggleFavoriteFromBar,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward_outlined),
                        iconSize: 24.0,
                        color: Colors.black,
                        onPressed: () {
                          _hideSecondPage();
                          _previousQuote();
                        },
                      ),
                      Builder(
                        builder: (context) {
                          return IconButton(
                            icon: const Icon(Icons.sell_outlined),
                            iconSize: 24.0,
                            color: Colors.black,
                            onPressed: () => _showDetailsPopup(context),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Streak Island Overlay
          if (_showStreakIsland)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false, // Don't apply SafeArea to bottom
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 0, color: Colors.transparent),
                    ),
                  ),
                  child: StreakIsland(
                    streakMessage: _streakMessage,
                    weeklyView: _weeklyView,
                    isDarkMode: _isDarkMode,
                    onTap: () {
                      // Optional: Show streak history or details
                    },
                    onDismiss: () {
                      setState(() {
                        _showStreakIsland = false;
                      });
                    },
                  ),
                ),
              ),
            ),

          // Celebration Overlay
          if (_celebrationType != null)
            Positioned.fill(
              child: SimpleCelebrationOverlay(
                animationType: _celebrationType!,
                onComplete: () {
                  setState(() {
                    _celebrationType = null;
                  });
                },
              ),
            ),
        ],
      ),
      appBar: AppBar(
        title: Text(
          'Literature Bites',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'EBGaramond',
          ),
        ),
        backgroundColor: _isDarkMode
            ? Colors.black
            : const Color.fromARGB(255, 240, 234, 225),
        elevation: 0,
        scrolledUnderElevation: 0.0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
        actions: [
          IconButton(
            icon: _isDarkMode
                ? const Icon(Icons.brightness_low)
                : const Icon(Icons.brightness_high),
            onPressed: _toggleDarkMode,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
    );
  }

  void _updatePageViewItems() {
    setState(() {
      final views = _seenQuoteIds.length;
      if ([10, 30, 60].contains(views)) {
        final cardId = 'info_$views';
        if (!_infoCardIds.contains(cardId)) {
          final nextQuoteIndex =
              _pageViewItems.indexWhere(
                (item) => item is Quote && item.id == _quotes[_currentIndex].id,
              ) +
              1;
          if (nextQuoteIndex < _pageViewItems.length) {
            _pageViewItems.insert(nextQuoteIndex, _InfoCardModel(id: cardId));
            _infoCardIds.add(cardId);
          }
        }
      }
    });
  }

  Widget _buildInfoCard() {
    String title = 'Did You Know?';
    String message;
    List<Widget> actions = [];
    final cardColor = _isDarkMode
        ? const Color.fromARGB(255, 239, 237, 231)
        : const Color.fromARGB(255, 224, 222, 212);

    final bool shouldShowLearnCard = !_hasExploredLearn;
    final bool shouldShowBrowseCard = !_hasExploredBrowse;

    if (shouldShowLearnCard && shouldShowBrowseCard) {
      message =
          'Expand the side drawer to browse quotes by author or tag, or to start a personalized quiz in the Learn section.';
      actions = [
        GradientOutlinedButton(
          onPressed: () => _handleInfoCardNavigation(_navigateToBrowse),
          backgroundColor: cardColor,
          child: const Text('Browse'),
        ),
        GradientOutlinedButton(
          onPressed: () => _handleInfoCardNavigation(_navigateToLearn),
          backgroundColor: cardColor,
          child: const Text('Learn'),
        ),
      ];
    } else if (shouldShowLearnCard) {
      message =
          'Expand the side drawer to start a personalized quiz in the Learn section.';
      actions = [
        GradientOutlinedButton(
          onPressed: () => _handleInfoCardNavigation(_navigateToLearn),
          backgroundColor: cardColor,
          child: const Text('Learn Now'),
        ),
      ];
    } else if (shouldShowBrowseCard) {
      message =
          'Expand the side drawer to browse quotes by author, tag, or historical period.';
      actions = [
        GradientOutlinedButton(
          onPressed: () => _handleInfoCardNavigation(_navigateToBrowse),
          backgroundColor: cardColor,
          child: const Text('Browse Now'),
        ),
      ];
    } else {
      // This case should ideally not be hit if logic is correct
      return Container();
    }
    return Center(
      child: InfoCard(
        title: title,
        message: message,
        actions: actions,
        color: cardColor,
      ),
    );
  }

  void _handleInfoCardNavigation(VoidCallback navigationAction) {
    // Remove the info card before navigating
    setState(() {
      _pageViewItems.removeWhere((item) => item is _InfoCardModel);
    });
    navigationAction();
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Center(
              child: Text(
                "Literature Bites",
                style: TextStyle(fontSize: 32, fontFamily: 'EBGaramond'),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              _navigateToProfile();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.explore),
            title: const Text("Browse"),
            onTap: () {
              Navigator.pop(context);
              _navigateToBrowse();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.favorite_rounded,
              color: _isFavoritesMode ? Colors.redAccent : null,
            ),
            title: Text("Your Favorites (${_favoriteQuotes.length})"),
            selectedTileColor: _isDarkMode
                ? Colors.grey.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            selected: _isFavoritesMode,
            onTap: () {
              Navigator.pop(context);
              _toggleFavoritesFilter();
            },
          ),
          ListTile(
            leading: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent],
                tileMode: TileMode.mirror,
              ).createShader(bounds),
              child: const Icon(Icons.school, color: Colors.white),
            ),
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.blue, Colors.purple],
                tileMode: TileMode.mirror,
              ).createShader(bounds),
              child: const Text(
                "Learn",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'EBGaramond',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _navigateToLearn();
            },
          ),
          if (_selectedTags.isNotEmpty ||
              _selectedAuthors.isNotEmpty ||
              _isFavoritesMode)
            ListTile(
              leading: const Icon(Icons.clear),
              title: Text("Clear Filters"),
              onTap: () {
                Navigator.pop(context);
                _clearFilter();
              },
            ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About this App"),
            onTap: () {
              Navigator.pop(context);
              _navigateToAbout();
            },
          ),
          const ListTile(
            leading: Icon(Icons.share_outlined),
            title: Text("Share"),
          ),
        ],
      ),
    );
  }
}
