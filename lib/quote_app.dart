import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'quote.dart';
import 'quote_service.dart';
import 'browse.dart';
import 'browse_hub.dart';
import 'about.dart';
import 'learn_hub.dart';
import 'profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'srs_service.dart';
import 'package:flutter/services.dart';
import 'package:quotes_app/recommendation_service.dart';
import 'package:flutter/rendering.dart';

class QuoteApp extends StatefulWidget {
  const QuoteApp({super.key});

  @override
  QuoteAppState createState() => QuoteAppState();
}

class QuoteAppState extends State<QuoteApp> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  final SRSService _srsService = SRSService();
  late ScrollController _detailsScrollController;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartAnimation;

  List<Quote> _quotes = [];
  List<Quote> _allQuotes = [];
  final List<Quote> _favoriteQuotes = [];
  final Set<String> _selectedTags = <String>{};
  final Set<String> _seenQuoteIds = <String>{};
  final Map<String, int> _likeCounts = <String, int>{};
  bool _isFavoritesMode = false;
  bool _isPersonalizedMode = true;

  bool _isDarkMode = false;
  bool _isSecondPageVisible = false;
  bool _isLoading = true;

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
    final likeCount = _likeCounts[quote.id] ?? 0;
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
                        alignment: Alignment.center,
                        child: Text(
                          quote.text,
                          style: TextStyle(
                            fontSize: _getFontSize(quote.text),
                            fontWeight: FontWeight.w500,
                            fontFamily: "Georgia",
                            color: _isDarkMode ? Colors.white : Colors.black,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
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
                            fontFamily: "Georgia",
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
                              fontFamily: "Georgia",
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Tags as chips
                    if (quote.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: quote.tags
                              .map((tag) => _buildTagChip(tag))
                              .toList(),
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
                fontFamily: "Georgia",
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
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                quote.interpretation!,
                style: TextStyle(
                  fontFamily: 'Georgia',
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
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontSize: 15,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final bool isSelected = _selectedTags.contains(tag);

    return GestureDetector(
      onTap: () => _toggleTagFilter(tag),
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
                fontFamily: 'Georgia',
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

  void _clearFilter() {
    setState(() {
      _selectedTags.clear();
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

  void _toggleFavoritesFilter() {
    setState(() {
      _isFavoritesMode = !_isFavoritesMode;
      if (_isFavoritesMode) {
        _selectedTags.clear();
      }
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      List<Quote> baseQuotes;
      if (_isFavoritesMode) {
        baseQuotes = _favoriteQuotes;
      } else {
        baseQuotes = _allQuotes;
      }

      List<Quote> filteredQuotes;
      if (_isPersonalizedMode && _selectedTags.isEmpty && !_isFavoritesMode) {
        final recommendationService = RecommendationService(
          allQuotes: _allQuotes,
          favoriteQuotes: _favoriteQuotes,
          likeCounts: _likeCounts,
        );
        filteredQuotes = recommendationService.getRecommendations();
      } else if (_selectedTags.isEmpty) {
        filteredQuotes = List.from(baseQuotes);
      } else {
        filteredQuotes = baseQuotes.where((quote) {
          return _selectedTags.every(
            (selectedTag) => quote.tags.contains(selectedTag),
          );
        }).toList();
      }

      if (!_isFavoritesMode && !_isPersonalizedMode) {
        filteredQuotes.shuffle();
      }

      _quotes = filteredQuotes;
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
    await Navigator.push(
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
        ),
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final newPersonalizedMode =
        prefs.getBool('personalizedSuggestions') ?? true;
    if (newPersonalizedMode != _isPersonalizedMode) {
      setState(() {
        _isPersonalizedMode = newPersonalizedMode;
      });
      _applyFilters();
    }
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LearnHubPage(
            isDarkMode: _isDarkMode,
            allQuotes: _allQuotes,
            favoriteQuotes: _favoriteQuotes,
          ),
        ),
      );
    }
  }

  void _navigateToBrowse() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => BrowseHubPage(
          allQuotes: _allQuotes,
          initialSelectedTags: _selectedTags,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
    if (result != null && mounted) {
      _applyTagFilter(result);
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
              fontFamily: 'Georgia',
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
              fontFamily: 'Georgia',
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
                fontFamily: 'Georgia',
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
      body: Column(
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
                      final quoteIndex = index % _quotes.length;
                      setState(() {
                        _currentIndex = quoteIndex;
                        _seenQuoteIds.add(_quotes[quoteIndex].id);
                      });
                    }
                  },
                  itemBuilder: (context, index) {
                    if (_quotes.isEmpty) {
                      return Container(); // Should not happen if handled properly
                    }
                    final quoteIndex = index % _quotes.length;
                    return _buildQuoteCard(_quotes[quoteIndex]);
                  },
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
                              _favoriteQuotes.contains(_quotes[_currentIndex])
                              ? Colors.red
                              : Colors.black,
                        ),
                        if ((_likeCounts[_quotes[_currentIndex].id] ?? 0) > 1)
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
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    iconSize: 24.0,
                    color: _isSecondPageVisible ? Colors.grey : Colors.black,
                    onPressed: _isSecondPageVisible ? null : _showSecondPage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(
          '',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'Georgia',
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

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Center(
              child: Text(
                "Literature Bites",
                style: TextStyle(fontSize: 32, fontFamily: 'Georgia'),
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
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _navigateToLearn();
            },
          ),
          if (_selectedTags.isNotEmpty || _isFavoritesMode)
            ListTile(
              leading: const Icon(Icons.clear),
              title: Text(
                "Clear Filters (${_quotes.length}/${_allQuotes.length})",
              ),
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
