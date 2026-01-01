import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/utils/hashtag_helper.dart';

class HashtagText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final Function(String hashtag)? onHashtagTap;

  const HashtagText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(
        style: style ?? const TextStyle(color: Colors.black, fontSize: 14),
        children: _buildTextSpans(context),
      ),
    );
  }

  List<InlineSpan> _buildTextSpans(BuildContext context) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(r'#[a-zA-ZğüşıöçĞÜŞİÖÇ0-9_]+');
    final matches = regex.allMatches(text);

    int currentPosition = 0;

    for (final match in matches) {
      // Add text before hashtag
      if (match.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, match.start),
        ));
      }

      // Add hashtag as TextSpan with TapGestureRecognizer
      final hashtag = text.substring(match.start, match.end);
      
      spans.add(TextSpan(
        text: hashtag,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onHashtagTap != null) {
              final hashtagWithoutSymbol = hashtag.substring(1);
              onHashtagTap!(hashtagWithoutSymbol);
            }
          },
      ));

      currentPosition = match.end;
    }

    // Add remaining text after last hashtag
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
      ));
    }

    return spans;
  }
}

/// Selectable version of HashtagText
class SelectableHashtagText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Function(String hashtag)? onHashtagTap;

  const SelectableHashtagText({
    super.key,
    required this.text,
    this.style,
    this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        style: style ?? const TextStyle(color: Colors.black, fontSize: 14),
        children: _buildTextSpans(context),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'#[a-zA-ZğüşıöçĞÜŞİÖÇ0-9_]+');
    final matches = regex.allMatches(text);

    int currentPosition = 0;

    for (final match in matches) {
      // Add text before hashtag
      if (match.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, match.start),
        ));
      }

      // Add hashtag with blue color, underline and tap handler
      final hashtag = text.substring(match.start, match.end);
      spans.add(TextSpan(
        text: hashtag,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: AppTheme.primaryColor,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onHashtagTap != null) {
              // Remove # from hashtag
              final hashtagWithoutSymbol = hashtag.substring(1);
              onHashtagTap!(hashtagWithoutSymbol);
            }
          },
      ));

      currentPosition = match.end;
    }

    // Add remaining text after last hashtag
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
      ));
    }

    return spans;
  }
}
