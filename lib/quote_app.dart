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
import 'utils/system_ui.dart';
import 'widgets/active_filters_bar.dart';
import 'widgets/settings_sheet.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/widgets/award_sheet.dart';
import 'package:quotes_app/widgets/reward_island.dart';
import 'quote.dart';
import 'quote_service.dart';
import 'browse_hub.dart';
import 'about.dart';
import 'learn_hub.dart';
import 'profile_rewards_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'srs_service.dart';

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

  bool _showStreakIsland = false;
  String _streakMessage = '';
  List<bool> _weeklyView = [];
  String? _celebrationType; // 'confetti' or 'fireworks'
  String? _awardedFeatureKey;

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
  bool _isLoading = true;
  bool _isSecondPageVisible = false;
  final Set<String> _infoCardIds = <String>{};
  List<dynamic> _pageViewItems = [];

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
    }
  }

  Future<void> _handleAppLaunch() async {
    final result = await StreakService.instance.recordAppLaunch();
    final isNewEngagement = result['isNewEngagement'] as bool;

    if (isNewEngagement) {
      final streakCount = result['streakCount'] as int;
      final celebrationType = result['celebrationType'] as String?;
      final awardedFeatureKeys = (result['awardedFeatureKeys'] as List)
          .cast<String>();

      setState(() {
        _streakMessage = '$streakCount Day Streak!';
        _weeklyView = result['weeklyView'] as List<bool>;
        _showStreakIsland = true;
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
      final weeklyView = result['weeklyView'] as List<bool>?;
      if (weeklyView != null) {
        setState(() {
          _weeklyView = weeklyView;
        });
      }
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

  void _showAwardSheet(List<String> awardedFeatureKeys) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return AwardSheet(
          awardedFeatureKeys: awardedFeatureKeys,
          onSeeRewards: () {
            Navigator.of(context).pop(); // Close the sheet
            _navigateToRewardsCenter();
          },
          onTryFeature: (featureKey) {
            Navigator.of(context).pop(); // Close the sheet
            // For now, just show a snackbar. Later, this will navigate.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Feature coming in Phase 2: $featureKey')),
            );
          },
        );
      },
    );
  }

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
      MaterialPageRoute(builder: (context) => AboutPage()),
    );
  }

  void _navigateToRewardsCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileRewardsPage()),
    );
  }

  void _showDetailsPopup(BuildContext anchorContext) {
    final quote = _quotes[_currentIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DetailsPopupContent(
          quote: quote,
          buildTagChip: _buildTagChip,
          buildAuthorChip: _buildAuthorChip,
          onTagToggled: _toggleTagFilter,
          onAuthorToggled: _toggleAuthorFilter,
        );
      },
    );
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
          _toggleAuthorFilter(authorName);
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
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontFamily: 'EBGaramond',
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
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'EBGaramond',
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
                              }
                            });
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
                    DetailsCard(
                      quote: _quotes[_currentIndex],
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
                isFavoritesMode: _isFavoritesMode,
                onClear: _clearFilter,
              ),

              // Bottom navigation bar
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

          // Streak Island Overlay
          if (_showStreakIsland || _awardedFeatureKey != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false, // Don't apply SafeArea to bottom
                child: Column(
                  children: [
                    if (_showStreakIsland)
                      StreakIsland(
                        streakMessage: _streakMessage,
                        weeklyView: _weeklyView,
                        onTap: () {
                          // Optional: Show streak history or details
                        },
                        onDismiss: () {
                          setState(() {
                            _showStreakIsland = false;
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
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontFamily: 'EBGaramond',
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
                    child: const SettingsSheet(),
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

  Widget _buildInfoCard() {
    String title = 'Did You Know?';
    String message;
    List<Widget> actions = [];
    final cardColor = Theme.of(context).brightness == Brightness.dark
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
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text("Rewards & Passes"),
            onTap: () {
              Navigator.pop(context);
              _navigateToRewardsCenter();
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
        ],
      ),
    );
  }
}
