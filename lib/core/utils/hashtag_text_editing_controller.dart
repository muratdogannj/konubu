import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';

class HashtagTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> children = [];
    final text = value.text;
    final regex = RegExp(r'#[a-zA-ZğüşıöçĞÜŞİÖÇ0-9_]+');
    
    int currentIndex = 0;
    
    // Find all matches
    final matches = regex.allMatches(text);
    
    for (final match in matches) {
      // Add text before the hashtag
      if (match.start > currentIndex) {
        children.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: style,
        ));
      }
      
      // Add the hashtag with custom style
      children.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ) ?? const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      currentIndex = match.end;
    }
    
    // Add remaining text
    if (currentIndex < text.length) {
      children.add(TextSpan(
        text: text.substring(currentIndex),
        style: style,
      ));
    }
    
    return TextSpan(style: style, children: children);
  }
}
