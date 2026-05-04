import 'package:flutter/gestures.dart';
import 'package:onyxia/export.dart';

class EditorContextMenu extends StatefulWidget {
  final void Function(Offset? position) onComment;
  final Widget child;

  const EditorContextMenu({
    super.key,
    required this.onComment,
    required this.child,
  });

  @override
  State<EditorContextMenu> createState() => _EditorContextMenuState();
}

class _EditorContextMenuState extends State<EditorContextMenu> {
  Offset? _contextMenuPosition;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse && event.buttons == kSecondaryMouseButton) {
          setState(() {
            _contextMenuPosition = event.localPosition;
          });
        }
      },
      child: ContextMenuArea(
        builder: (context) => [
          ListTile(
            leading: const Icon(Icons.comment),
            title: const Text('Comment'),
            onTap: () {
              Navigator.of(context).pop();
              widget.onComment(_contextMenuPosition);
            },
          ),
        ],
        child: widget.child,
      ),
    );
  }
}
