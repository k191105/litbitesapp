import 'package:flutter/material.dart';
import '../quote.dart';

class DetailsCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onHide;
  final Widget Function(String, {void Function(String)? onTap}) buildTagChip;
  final ScrollController? controller;

  const DetailsCard({
    super.key,
    required this.quote,
    required this.onHide,
    required this.buildTagChip,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${quote.text}"',
              style: TextStyle(
                fontFamily: "EBGaramond",
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).primaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (quote.interpretation != null &&
                quote.interpretation!.isNotEmpty) ...[
              Text(
                'Interpretation',
                style: TextStyle(
                  fontFamily: 'EBGaramond',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                quote.interpretation!,
                style: TextStyle(
                  fontFamily: 'EBGaramond',
                  fontSize: 16,
                  height: 1.6,
                  color: Theme.of(context).primaryColor.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 32),
            ],
            const Divider(),
            const SizedBox(height: 24),
            _buildDetailSection('Author', quote.authorInfo, context),
            if (quote.displaySource.isNotEmpty)
              _buildDetailSection('Source', quote.displaySource, context),
            if (quote.sourceBlurb != null && quote.sourceBlurb!.isNotEmpty)
              _buildDetailSection('Source Note', quote.sourceBlurb!, context),
            const SizedBox(height: 24),
            if (quote.tags.isNotEmpty)
              _buildTagsDetailSection('Tags', quote.tags, context),
            const SizedBox(height: 48),
            Center(
              child: OutlinedButton(
                onPressed: onHide,
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    width: 0.2,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                child: Text(
                  '« Back to Quote',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    String content,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).primaryColor.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'EBGaramond',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 15,
              fontFamily: 'EBGaramond',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsDetailSection(
    String title,
    List<String> tags,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).primaryColor.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'EBGaramond',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: tags.map((tag) => buildTagChip(tag)).toList(),
          ),
        ],
      ),
    );
  }
}
