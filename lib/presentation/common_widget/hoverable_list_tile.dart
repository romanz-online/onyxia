import 'package:flutter/material.dart';
import 'package:onyxia/helpers/theme_helper.dart';

class HoverableListTile extends StatefulWidget {
  final Widget title;
  final bool selected;
  final Color? selectedTileColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;

  const HoverableListTile({
    super.key,
    required this.title,
    this.selected = false,
    this.selectedTileColor,
    this.onTap,
    this.contentPadding,
  });

  @override
  State<HoverableListTile> createState() => _HoverableListTileState();
}

class _HoverableListTileState extends State<HoverableListTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        decoration: BoxDecoration(
          color: widget.selected 
            ? widget.selectedTileColor
            : _isHovering 
              ? ThemeHelper.blue().withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ListTile(
          title: widget.title,
          selected: widget.selected,
          selectedTileColor: Colors.transparent, // We handle this in Container
          contentPadding: widget.contentPadding,
          onTap: widget.onTap,
          hoverColor: Colors.transparent, // We handle this in Container
        ),
      ),
    );
  }
}