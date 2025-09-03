import 'package:flutter/material.dart';
import 'package:quotes_app/profile_rewards_page.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/services/notification_service.dart';
import 'package:quotes_app/services/theme_controller.dart';
import 'package:quotes_app/theme/theme_registry.dart';
import 'package:quotes_app/utils/feature_gate.dart';
import 'package:quotes_app/models/notification_prefs.dart';
import 'package:quotes_app/widgets/notification_editor_sheet.dart';
import 'package:quotes_app/quote.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quotes_app/services/purchase_service.dart';

class SettingsSheet extends StatefulWidget {
  final List<Quote>? allQuotes;
  final List<Quote>? favoriteQuotes;
  final Map<String, int>? viewCounts;

  const SettingsSheet({
    super.key,
    this.allQuotes,
    this.favoriteQuotes,
    this.viewCounts,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late String _previewThemeId;
  late String _previewFontId;
  bool _isPro = false;
  NotificationPrefs? _notificationPrefs;

  @override
  void initState() {
    super.initState();
    _previewThemeId = ThemeController.instance.themeId;
    _previewFontId = ThemeController.instance.fontId;
    _loadProStatus();
    _loadNotificationPrefs();
    Analytics.instance.logEvent('settings.opened');
  }

  Future<void> _loadProStatus() async {
    final proStatus = await EntitlementsService.instance.isPro();
    if (mounted) {
      setState(() {
        _isPro = proStatus;
      });
    }
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await NotificationService.loadNotificationPrefs();
    if (mounted) {
      setState(() {
        _notificationPrefs = prefs;
      });
    }
  }

  void _openPaywall(String contextKey) {
    openPaywall(context: context, contextKey: contextKey).then((result) {
      // If purchase was successful, refresh the UI
      if (result == true) {
        setState(() {
          _loadProStatus();
        });
      }
    });
  }

  Future<void> _handleRestore() async {
    Analytics.instance.logEvent('settings.restore');
    try {
      await PurchaseService.instance.restore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildPreview(),
                const SizedBox(height: 24),
                _buildSectionTitle('Theme'),
                const SizedBox(height: 12),
                _buildThemeSelector(),
                const SizedBox(height: 24),
                _buildSectionTitle('Font'),
                const SizedBox(height: 12),
                _buildFontSelector(),
                const SizedBox(height: 24),
                const Divider(height: 1, indent: 12, endIndent: 12),
                const SizedBox(height: 16),
                _buildSectionTitle('Reminders'),
                const SizedBox(height: 12),
                _buildRemindersSection(),
                const SizedBox(height: 24),
                const Divider(height: 1, indent: 12, endIndent: 12),
                const SizedBox(height: 16),
                _buildSectionTitle('Rewards & Account'),
                const SizedBox(height: 12),
                _buildAccountSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (_isPro)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final previewTheme = ThemeRegistry.getTheme(
      _previewThemeId,
      _previewFontId,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: previewTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: previewTheme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live text sample with current font
          Text(
            '"The measure of intelligence is the ability to change."',
            style: previewTheme.textTheme.bodyLarge?.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '— Albert Einstein',
            style: previewTheme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: previewTheme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    final themes = {
      'Light': lightThemeId,
      'Dark': darkThemeId,
      'Sand': sandThemeId,
      'Ink': inkThemeId,
      'Rose': roseThemeId,
      'Noir': noirThemeId,
    };
    final freeThemes = [lightThemeId, darkThemeId];

    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: themes.entries.map((entry) {
          final isPremium = !freeThemes.contains(entry.value);
          return _buildSelectorTile(
            label: entry.key,
            isSelected: _previewThemeId == entry.value,
            isPremium: isPremium,
            featureKey: 'premium_themes',
            onTap: () {
              if (isPremium && !_isPro) {
                _openPaywall('settings_theme');
                return;
              }
              setState(() {
                _previewThemeId = entry.value;
              });

              // For free themes, apply directly without feature gate
              if (!isPremium) {
                ThemeController.instance.setTheme(entry.value);
                Analytics.instance.logEvent('settings.theme_selected', {
                  'themeId': entry.value,
                });
                return;
              }

              // For premium themes, check feature access
              requireFeature(
                context,
                'premium_themes',
                onAllowed: () {
                  ThemeController.instance.setTheme(entry.value);
                  Analytics.instance.logEvent('settings.theme_selected', {
                    'themeId': entry.value,
                  });
                },
                onBlocked: () {
                  Analytics.instance.logEvent('settings.locked_theme_tapped');
                  _openPaywall('settings_theme');
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFontSelector() {
    final fonts = {
      'Garamond': garamondFontId,
      'PT Sans Narrow': ptSansNarrowFontId,
      'Tangerine': tangerineFontId,
    };
    final freeFonts = [garamondFontId];

    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: fonts.entries.map((entry) {
          final isPremium = !freeFonts.contains(entry.value);
          final fontTheme = ThemeRegistry.getTheme(
            _previewThemeId,
            entry.value,
          );

          return _buildFontSelectorTile(
            label: entry.key,
            fontTheme: fontTheme,
            isSelected: _previewFontId == entry.value,
            isPremium: isPremium,
            featureKey: 'premium_fonts',
            onTap: () {
              if (isPremium && !_isPro) {
                _openPaywall('settings_font');
                return;
              }
              setState(() {
                _previewFontId = entry.value;
              });

              // For free fonts, apply directly without feature gate
              if (!isPremium) {
                ThemeController.instance.setFont(entry.value);
                Analytics.instance.logEvent('settings.font_selected', {
                  'fontId': entry.value,
                });
                return;
              }

              // For premium fonts, check feature access
              requireFeature(
                context,
                'premium_fonts',
                onAllowed: () {
                  ThemeController.instance.setFont(entry.value);
                  Analytics.instance.logEvent('settings.font_selected', {
                    'fontId': entry.value,
                  });
                },
                onBlocked: () {
                  Analytics.instance.logEvent('settings.locked_font_tapped');
                  _openPaywall('settings_font');
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectorTile({
    required String label,
    required bool isSelected,
    required bool isPremium,
    required String featureKey,
    required VoidCallback onTap,
  }) {
    return FutureBuilder<bool>(
      future: EntitlementsService.instance.isFeatureActive(featureKey),
      builder: (context, snapshot) {
        final isAllowed = snapshot.data ?? false;
        final showLock = isPremium && !isAllowed && !_isPro;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (showLock)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.lock, size: 14, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFontSelectorTile({
    required String label,
    required ThemeData fontTheme,
    required bool isSelected,
    required bool isPremium,
    required String featureKey,
    required VoidCallback onTap,
  }) {
    return FutureBuilder<bool>(
      future: EntitlementsService.instance.isFeatureActive(featureKey),
      builder: (context, snapshot) {
        final isAllowed = snapshot.data ?? false;
        final showLock = isPremium && !isAllowed && !_isPro;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: fontTheme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (showLock)
                  const Padding(
                    padding: EdgeInsets.only(left: 6.0),
                    child: Icon(Icons.lock, size: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemindersSection() {
    if (_notificationPrefs == null) {
      return const ListTile(
        leading: Icon(Icons.notifications_outlined),
        title: Text('Reminders: Loading...'),
        dense: true,
      );
    }

    final prefs = _notificationPrefs!;

    if (_isPro) {
      // Pro user - show current settings with edit button
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text('Reminders: ${prefs.scheduleDescription}'),
            subtitle: Text(prefs.timesDisplay),
            trailing: TextButton(
              onPressed: _openNotificationEditor,
              child: const Text('Edit'),
            ),
            dense: true,
          ),
          if (prefs.authors.isNotEmpty ||
              prefs.tags.isNotEmpty ||
              prefs.startYear != null)
            Padding(
              padding: const EdgeInsets.only(left: 56, right: 16, bottom: 8),
              child: Text(
                _getSourceDescription(prefs),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ),
        ],
      );
    } else {
      // Free user - show current with Pro nudge
      return ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: Text('Reminders: ${prefs.scheduleDescription}'),
        subtitle: const Text('Customize in Pro'),
        trailing: TextButton(
          onPressed: () {
            Analytics.instance.logEvent(Analytics.notifSettingsOpened);
            _openPaywall('notif_customization');
          },
          child: const Text('See options'),
        ),
        dense: true,
      );
    }
  }

  String _getSourceDescription(NotificationPrefs prefs) {
    final parts = <String>[];

    if (prefs.authors.isNotEmpty) {
      parts.add(
        '${prefs.authors.length} author${prefs.authors.length == 1 ? '' : 's'}',
      );
    }

    if (prefs.tags.isNotEmpty) {
      parts.add('${prefs.tags.length} tag${prefs.tags.length == 1 ? '' : 's'}');
    }

    if (prefs.startYear != null && prefs.endYear != null) {
      parts.add('${prefs.startYear}-${prefs.endYear}');
    }

    if (parts.isEmpty) {
      return 'From all quotes';
    }

    return 'From: ${parts.join(', ')}';
  }

  void _openNotificationEditor() async {
    Analytics.instance.logEvent(Analytics.notifEditOpened);

    if (widget.allQuotes == null || _notificationPrefs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data not available for editing')),
      );
      return;
    }

    final result = await showModalBottomSheet<NotificationPrefs>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationEditorSheet(
        initialPrefs: _notificationPrefs!,
        allQuotes: widget.allQuotes!,
        favoriteQuotes: widget.favoriteQuotes ?? [],
        viewCounts: widget.viewCounts ?? {},
      ),
    );

    if (result != null) {
      // Refresh the preferences
      _loadNotificationPrefs();
    }
  }

  Widget _buildAccountSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.star_outline),
          title: const Text('Rewards & Passes'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProfileRewardsPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Restore Purchases'),
          onTap: _handleRestore,
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          onTap: () => launchUrl(
            Uri.parse('https://singhalkrishiv.wixsite.com/literature-bites'),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy & Terms'),
          onTap: () => launchUrl(
            Uri.parse(
              'https://singhalkrishiv.wixsite.com/literature-bites/privacy-policys',
            ),
          ),
        ),
      ],
    );
  }
}
