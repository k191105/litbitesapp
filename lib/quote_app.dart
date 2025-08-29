import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
import 'widgets/quote_card.dart';
import 'widgets/details_card.dart';
import 'widgets/bottom_action_bar.dart';
import 'widgets/details_popup.dart';
import 'widgets/tag_chip.dart';
import 'widgets/author_chip.dart';
import 'utils/share_quote.dart';
import 'models/period_catalog.dart';
import 'utils/system_ui.dart';
import 'widgets/active_filters_bar.dart';
import 'widgets/settings_sheet.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/widgets/reward_island.dart';
import 'package:quotes_app/widgets/tip_island.dart';
import 'quote.dart';
import 'quote_service.dart';
import 'browse_hub.dart';
import 'utils/feature_gate.dart';
import 'about.dart';
import 'learn_hub.dart';
import 'profile_rewards_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'srs_service.dart';
import 'package:quotes_app/services/purchase_service.dart';
import 'package:quotes_app/services/revenuecat_keys.dart';

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

class QuoteAppState extends State<QuoteApp>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  late PageController _pageController;
  final SRSService _srsService = SRSService();
  late ScrollController _detailsScrollController;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartAnimation;

  Map<String, dynamic>? _streakIslandData;
  String? _celebrationType; // 'confetti' or 'fireworks'
  String? _awardedFeatureKey;
  String? _activeTip;

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
  Map<String, dynamic>? _periodFilter;
  bool _isFavoritesMode = false;
  bool _isPersonalizedMode = true;
  bool _isLoading = true;
  bool _isSecondPageVisible = false;
  final Set<String> _infoCardIds = <String>{};

  List<dynamic> _pageViewItems = [];
  bool _showDetailsIsland = false;

  bool _hasExploredLearn = false;
  bool _hasExploredBrowse = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      EntitlementsService.instance.clearExpiredPasses().then((_) {
        // A simple way to refresh any UI that depends on entitlements
        setState(() {});
      });

      // Sync notifications with current preferences
      _syncNotifications();
    }
  }

  Future<void> _syncNotifications() async {
    final prefs = await NotificationService.loadNotificationPrefs();
    await NotificationService.syncWithPrefs(
      prefs,
      DateTime.now(),
      feed: _allQuotes,
      favoriteQuotes: _favoriteQuotes,
    );
  }

  Future<void> _handleAppLaunch() async {
    final result = await StreakService.instance.recordAppLaunch();
    final isNewEngagement = result['isNewEngagement'] as bool;

    if (isNewEngagement) {
      final streakCount = result['streakCount'] as int;
      final celebrationType = result['celebrationType'] as String?;
      final awardedFeatureKeys = (result['awardedFeatureKeys'] as List)
          .cast<String>();
      final weeklyView =
          (result['weeklyView'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      setState(() {
        _streakIslandData = {
          'message': '$streakCount Day Streak!',
          'weeklyView': weeklyView,
        };
        _celebrationType = celebrationType;
      });

      // Show celebration overlay if applicable
      if (celebrationType != null) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _showCelebrationOverlay(awardedFeatureKeys);
          }
        });
      }
    } else {
      // For existing engagements, we don't need to show the island,
      // but you might want to update the view if the app has been open overnight.
      // This part of the logic can be decided based on desired app behavior.
    }
  }

  void _showCelebrationOverlay(List<String> awardedFeatureKeys) {
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
        // After celebration, if there are awards, show the award sheet.
        if (awardedFeatureKeys.isNotEmpty) {
          setState(() {
            _awardedFeatureKey = awardedFeatureKeys.first;
          });
        }
      }
    });
  }

  // Removed unused _showAwardSheet; reward surfaces via RewardIsland

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      final seenInfoCardIds = prefs.getStringList('infoCardIds') ?? [];
      _infoCardIds.addAll(seenInfoCardIds);
      final seenQuoteIds = prefs.getStringList('seenQuoteIds') ?? [];
      _seenQuoteIds.addAll(seenQuoteIds);

      // Configure RevenueCat
      PurchaseService.instance.configure(
        iosApiKey: rcAppleApiKey,
        // Android deferred
      );

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
    await prefs.setStringList('seenQuoteIds', _seenQuoteIds.toList());
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
        _srsService.removeQuote(currentQuote.id);
      } else {
        _favoriteQuotes.add(currentQuote);
        _likeCounts[currentQuote.id] = (_likeCounts[currentQuote.id] ?? 0) + 1;
        _srsService.addQuote(currentQuote.id);
        _heartAnimationController.forward(from: 0.0);
      }
      _saveFavorites();
    });
  }

  Widget _buildQuoteCard(Quote quote) {
    return QuoteCard(
      quote: quote,
      onDoubleTap: _toggleFavorite,
      onReadMore: _showSecondPage,
      heartAnimation: _heartAnimation,
    );
  }

  Widget _buildTagChip(String tag, {void Function(String)? onTap}) {
    final bool isSelected = _selectedTags.contains(tag);

    return TagChip(
      tag: tag,
      isSelected: isSelected,
      onTap: (selectedTag) {
        if (onTap != null) {
          onTap(tag);
        } else {
          _toggleTagFilter(tag);
        }
      },
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
      _periodFilter = null;
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

  void _applyPeriodFilter(Map<String, dynamic> periodFilter) {
    setState(() {
      _periodFilter = periodFilter;
      _selectedAuthors.clear();
      // Don't add selected authors to _selectedAuthors to avoid showing them in active filters
      // The period filter logic will handle author filtering internally
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

      // Apply period filter if set
      if (_periodFilter != null) {
        final startYear = _periodFilter!['start_year'] as int;
        final endYear = _periodFilter!['end_year'] as int;
        filteredQuotes = PeriodCatalog.getQuotesForRange(
          filteredQuotes,
          startYear,
          endYear,
        );

        // Apply selected authors from period filter
        final selectedAuthors = _periodFilter!['selected_authors'];
        if (selectedAuthors is Set<String> && selectedAuthors.isNotEmpty) {
          filteredQuotes = filteredQuotes
              .where((quote) => selectedAuthors.contains(quote.authorName))
              .toList();
        } else if (selectedAuthors is Iterable && selectedAuthors.isNotEmpty) {
          final authorSet = selectedAuthors.cast<String>().toSet();
          filteredQuotes = filteredQuotes
              .where((quote) => authorSet.contains(quote.authorName))
              .toList();
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
    await shareQuoteAsImage(
      context,
      _quotes[_currentIndex],
      Theme.of(context).brightness == Brightness.dark,
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileRewardsPage()),
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
            allQuotes: _allQuotes,
            favoriteQuotes: _favoriteQuotes,
            viewCounts: _viewCounts,
            likeCounts: _likeCounts,
          ),
        ),
      );
    }
  }

  void _navigateToBrowse() async {
    setState(() {
      _hasExploredBrowse = true;
    });
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrowseHubPage(
          allQuotes: _allQuotes,
          favoriteQuotes: _favoriteQuotes,
          viewCounts: _viewCounts,
          initialSelectedTags: _selectedTags,
          initialSelectedAuthors: _selectedAuthors,
        ),
      ),
    );
    if (!mounted) return;
    if (result is Map) {
      // Handle different filter types returned from BrowseHubPage
      if (result.containsKey('tags')) {
        final tags = result['tags'];
        if (tags is Set<String>) _applyTagFilter(tags);
      } else if (result.containsKey('authors')) {
        final authors = result['authors'];
        if (authors is Set<String>) _applyAuthorFilter(authors);
      } else if (result.containsKey('period_filter') &&
          result['period_filter'] != null) {
        final pf = result['period_filter'];
        if (pf is Map) {
          _applyPeriodFilter(pf.cast<String, dynamic>());
        }
      } else if (result.containsKey('favorites')) {
        _toggleFavoritesFilter();
      }
    }
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AboutPage()),
    );
  }

  void _showDetailsPopup(BuildContext anchorContext) {
    setState(() {
      _showDetailsIsland = true;
    });
  }

  Widget _buildAuthorChip(String authorName, {void Function(String)? onTap}) {
    final bool isSelected = _selectedAuthors.contains(authorName);

    return AuthorChip(
      authorName: authorName,
      isSelected: isSelected,
      onTap: (selectedAuthor) {
        if (onTap != null) {
          onTap(authorName);
        } else {
          // Gate author filtering for non-Pro users
          requireFeature(
            context,
            EntitlementsService.browseAuthor,
            onAllowed: () {
              _toggleAuthorFilter(authorName);
            },
            onBlocked: () {
              openPaywall(context: context, contextKey: 'browse_author');
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sync the system status bar with our app bar background to avoid the lavender tint on iOS
    setSystemUIOverlayStyle(Theme.of(context).brightness == Brightness.dark);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            '',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0.0,
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        ),
        drawer: _buildDrawer(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                            _viewCounts.update(
                              quoteId,
                              (value) => value + 1,
                              ifAbsent: () => 1,
                            );
                            _saveViewCounts();
                            setState(() {
                              _currentIndex = _quotes.indexOf(item);
                              if (!_seenQuoteIds.contains(quoteId)) {
                                _seenQuoteIds.add(quoteId);
                                _updatePageViewItems();
                                _checkForTips();
                              }
                            });
                          }
                        }
                      },
                      itemBuilder: (context, index) {
                        // Safety check to prevent empty cards
                        if (index >= _pageViewItems.length ||
                            _pageViewItems.isEmpty) {
                          // If we have quotes but pageViewItems is misaligned, rebuild it
                          if (_quotes.isNotEmpty && _pageViewItems.isEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _pageViewItems = List.from(_quotes);
                                });
                              }
                            });
                          }
                          return const SizedBox.shrink(); // Better than empty Container
                        }

                        final item = _pageViewItems[index];
                        if (item is Quote) {
                          return _buildQuoteCard(item);
                        } else if (item is _InfoCardModel) {
                          return _buildInfoCard();
                        }

                        // Log unexpected items to help debug
                        debugPrint(
                          'Warning: Unexpected item type in _pageViewItems: ${item.runtimeType}',
                        );
                        return const SizedBox.shrink();
                      },
                      itemCount: _pageViewItems.length,
                    ),
                    DetailsCard(
                      quote:
                          _quotes.isNotEmpty && _currentIndex < _quotes.length
                          ? _quotes[_currentIndex]
                          : Quote(
                              id: 'loading',
                              text: 'Loading...',
                              authorName: '',
                              themes: [],
                              tags: [],
                              status: 'loading',
                            ),
                      onHide: _hideSecondPage,
                      buildTagChip: _buildTagChip,
                      controller: _detailsScrollController,
                    ),
                  ],
                ),
              ),

              // Active Filters Bar
              ActiveFiltersBar(
                selectedTags: _selectedTags,
                selectedAuthors: _selectedAuthors,
                periodFilter: _periodFilter,
                isFavoritesMode: _isFavoritesMode,
                onClear: _clearFilter,
              ),

              // Bottom navigation bar
              if (_quotes.isNotEmpty && _currentIndex < _quotes.length)
                BottomActionBar(
                  currentQuote: _quotes[_currentIndex],
                  favoriteQuotes: _favoriteQuotes,
                  likeCounts: _likeCounts,
                  onShare: _shareQuoteAsImage,
                  onNext: () {
                    _hideSecondPage();
                    _nextQuote();
                  },
                  onPrevious: () {
                    _hideSecondPage();
                    _previousQuote();
                  },
                  onToggleFavorite: _toggleFavoriteFromBar,
                  onShowDetails: _showDetailsPopup,
                ),
            ],
          ),

          // Tag/Author details island overlay above the bottom action bar
          if (_showDetailsIsland)
            Positioned.fill(
              child: Stack(
                children: [
                  // Dismiss barrier
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _showDetailsIsland = false),
                      behavior: HitTestBehavior.opaque,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  // Island positioned just above the bottom bar
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: 80 + MediaQuery.of(context).padding.bottom + 6,
                      ),
                      child:
                          _quotes.isNotEmpty && _currentIndex < _quotes.length
                          ? DetailsPopupContent(
                              quote: _quotes[_currentIndex],
                              buildTagChip: _buildTagChip,
                              buildAuthorChip: _buildAuthorChip,
                              onTagToggled: _toggleTagFilter,
                              onAuthorToggled: _toggleAuthorFilter,
                              onRequestClose: () =>
                                  setState(() => _showDetailsIsland = false),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),

          // Streak Island Overlay
          if (_streakIslandData != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false, // Don't apply SafeArea to bottom
                child: Column(
                  children: [
                    if (_streakIslandData != null)
                      StreakIsland(
                        streakMessage: _streakIslandData!['message'] as String,
                        weeklyView:
                            _streakIslandData!['weeklyView']
                                as List<Map<String, dynamic>>,
                        onTap: () {
                          // Optional: Show streak history or details
                        },
                        onDismiss: () {
                          setState(() {
                            _streakIslandData = null;
                          });
                        },
                      ),
                    if (_awardedFeatureKey != null)
                      RewardIsland(
                        featureKey: _awardedFeatureKey!,
                        onDismiss: () {
                          setState(() {
                            _awardedFeatureKey = null;
                          });
                        },
                      ),
                    if (_activeTip != null)
                      TipIsland(
                        message: _getTipMessage(_activeTip!),
                        icon: _getTipIcon(_activeTip!),
                        onDismiss: () {
                          setState(() {
                            _activeTip = null;
                          });
                        },
                      ),
                  ],
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return FractionallySizedBox(
                    heightFactor: 0.75,
                    child: SettingsSheet(
                      allQuotes: _allQuotes,
                      favoriteQuotes: _favoriteQuotes,
                      viewCounts: _viewCounts,
                    ),
                  );
                },
              );
            },
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
            _saveInfoCardIds();
          }
        }
      }
    });
  }

  Future<void> _saveInfoCardIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('infoCardIds', _infoCardIds.toList());
  }

  void _checkForTips() async {
    final prefs = await SharedPreferences.getInstance();
    final shownTips = prefs.getStringList('shownTips') ?? [];

    if (_favoriteQuotes.isNotEmpty) {
      return;
    }

    final milestones = [5, 15, 30];
    for (var milestone in milestones) {
      if (_seenQuoteIds.length == milestone &&
          !shownTips.contains('double_tap_$milestone')) {
        setState(() {
          _activeTip = 'double_tap';
        });

        shownTips.add('double_tap_$milestone');
        await prefs.setStringList('shownTips', shownTips);
        break;
      }
    }
  }

  String _getTipMessage(String tipKey) {
    switch (tipKey) {
      case 'double_tap':
        return 'Double-tap any quote to add it to your favorites!';
      default:
        return 'Tip: Explore the app to discover more features!';
    }
  }

  IconData _getTipIcon(String tipKey) {
    switch (tipKey) {
      case 'double_tap':
        return Icons.favorite_border;
      default:
        return Icons.lightbulb_outline;
    }
  }

  Widget _buildInfoCard() {
    String title = 'Did You Know?';
    String message;
    List<Widget> actions = [];

    final bool shouldShowLearnCard = !_hasExploredLearn;
    final bool shouldShowBrowseCard = !_hasExploredBrowse;

    if (shouldShowLearnCard && shouldShowBrowseCard) {
      message =
          'You can expand the drawer to browse quotes by author or tag, or to start a personalized quiz in the Learn section.';
      actions = [
        GradientOutlinedButton(
          onPressed: () => _handleInfoCardNavigation(_navigateToBrowse),
          child: const Text('Browse'),
        ),
        GradientOutlinedButton(
          onPressed: () => _handleInfoCardNavigation(_navigateToLearn),
          child: const Text('Learn'),
        ),
      ];
    } else if (shouldShowLearnCard) {
      message =
          'You can expand the drawer to start a personalized quiz in the Learn section.';
      actions = [
        GradientOutlinedButton(
          onPressed: () => _handleInfoCardNavigation(_navigateToLearn),
          child: const Text('Learn Now'),
        ),
      ];
    } else if (shouldShowBrowseCard) {
      message =
          'You can expand the drawer to browse quotes by author, tag, or historical period.';
      actions = [
        GradientOutlinedButton(
          onPressed: () => _handleInfoCardNavigation(_navigateToBrowse),
          child: const Text('Browse Now'),
        ),
      ];
    } else {
      // This case should ideally not be hit if logic is correct
      return Container();
    }
    return Center(
      child: InfoCard(title: title, message: message, actions: actions),
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
            title: const Text("Your Profile"),
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
            selectedTileColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            selected: _isFavoritesMode,
            onTap: () {
              Navigator.pop(context);
              _toggleFavoritesFilter();
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text("Learn"),
            onTap: () {
              Navigator.pop(context);
              _navigateToLearn();
            },
          ),
          if (_selectedTags.isNotEmpty ||
              _selectedAuthors.isNotEmpty ||
              _periodFilter != null ||
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
        ],
      ),
    );
  }
}
