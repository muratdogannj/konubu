import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/hashtag_stat_model.dart';
import 'package:dedikodu_app/data/repositories/hashtag_repository.dart';

class HashtagTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;

  const HashtagTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.maxLines,
    this.maxLength,
    this.validator,
    this.onChanged,
  });

  @override
  State<HashtagTextField> createState() => _HashtagTextFieldState();
}

class _HashtagTextFieldState extends State<HashtagTextField> {
  final _hashtagRepo = HashtagRepository();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<HashtagStatModel> _suggestions = [];
  String _currentHashtag = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    widget.onChanged?.call();

    final text = widget.controller.text;
    final selection = widget.controller.selection;

    // Find if cursor is after a # symbol
    if (selection.baseOffset > 0) {
      final textBeforeCursor = text.substring(0, selection.baseOffset);
      final lastHashIndex = textBeforeCursor.lastIndexOf('#');

      if (lastHashIndex != -1) {
        // Check if there's a space after the last #
        final textAfterHash = textBeforeCursor.substring(lastHashIndex + 1);
        if (!textAfterHash.contains(' ') && !textAfterHash.contains('\n')) {
          // We're typing a hashtag
          _currentHashtag = textAfterHash;
          _searchHashtags(_currentHashtag);
          return;
        }
      }
    }

    // Hide suggestions if not typing a hashtag
    _removeOverlay();
  }

  Future<void> _searchHashtags(String query) async {
    print('Searching hashtags for: $query');
    
    if (query.isEmpty) {
      // Show popular hashtags when just typed #
      final popular = await _hashtagRepo.getPopularHashtags(limit: 10);
      print('Popular hashtags: ${popular.length}');
      if (popular.isNotEmpty) {
        setState(() => _suggestions = popular);
        _showOverlay();
      }
    } else {
      // Search for matching hashtags
      final results = await _hashtagRepo.searchHashtags(query);
      print('Search results for "$query": ${results.length}');
      if (results.isNotEmpty) {
        setState(() => _suggestions = results);
        _showOverlay();
      } else {
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      print('RenderBox is null, cannot show overlay');
      return;
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    print('Showing overlay at: $offset with ${_suggestions.length} suggestions');

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return InkWell(
                  onTap: () => _selectHashtag(suggestion.hashtag),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tag,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '#${suggestion.hashtag}',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${suggestion.count} kişi',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectHashtag(String hashtag) {
    print('Selected hashtag: $hashtag');
    
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    // Find the position of the current hashtag being typed
    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final lastHashIndex = textBeforeCursor.lastIndexOf('#');

    if (lastHashIndex != -1) {
      // Replace the partial hashtag with the selected one
      final before = text.substring(0, lastHashIndex);
      final after = text.substring(selection.baseOffset);
      final newText = '$before#$hashtag $after';

      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: lastHashIndex + hashtag.length + 2, // +2 for # and space
        ),
      );
    }

    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        validator: widget.validator,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          helperText: 'İstersen anonim.',
          helperStyle: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
        ),
      ),
    );
  }
  
  // Helper method to build text with highlighted hashtags
  TextSpan _buildTextSpan(String text) {
    final List<TextSpan> spans = [];
    final RegExp hashtagRegex = RegExp(r'#\w+');
    int lastMatchEnd = 0;

    for (final match in hashtagRegex.allMatches(text)) {
      // Add normal text before hashtag
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: const TextStyle(color: Colors.black),
        ));
      }

      // Add hashtag in blue
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: const TextStyle(color: Colors.black),
      ));
    }

    return TextSpan(children: spans);
  }
}
