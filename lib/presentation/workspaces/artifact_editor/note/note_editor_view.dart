import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/presentation/workspaces/artifact_editor/note/note_title_field.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:onyxia/export.dart';

const String _kGhostLorem =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
    'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
    'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
    'nisi ut aliquip ex ea commodo consequat. ';
const Duration _kGhostTypeDelay = Duration(milliseconds: 80);

class NoteEditorView extends ConsumerStatefulWidget {
  final NoteStateProvider? provider;

  const NoteEditorView({super.key, this.provider});

  @override
  ConsumerState<NoteEditorView> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditorView> {
  NoteStateProvider get _provider =>
      widget.provider ?? selectedNoteStateProvider;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Hover state
  bool _showHoverContainer = false;
  Offset? _hoverPosition;

  // Drag state
  bool _isDragOver = false;

  String? _currentNoteId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkNoteChange();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkNoteChange() {
    final noteState = ref.read(_provider);
    noteState.whenData((state) {
      final newNoteId = state.note?.id;
      if (newNoteId != _currentNoteId) {
        final shouldReset = _currentNoteId != null;
        _currentNoteId = newNoteId;
        if (shouldReset || newNoteId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && shouldReset) _resetEditorState();
          });
        }
      }
    });
  }

  void _resetEditorState() {
    setState(() {
      _showHoverContainer = false;
      _hoverPosition = null;
      _isDragOver = false;
    });
  }

  // TODO: handle inserting images
  Future<void> _handleImageDrop(PerformDropEvent event) async {
    // final item = event.session.items.first;
    // final reader = item.dataReader!;
    // FileFormat? format;
    // for (final f in _imageFormats) {
    //   if (reader.canProvide(f)) {
    //     format = f;
    //     break;
    //   }
    // }
    // if (format != null) {
    //   reader.getFile(
    //     format,
    //     (file) async {
    //       final data = await file.readAll();
    //       final controller = ref.read(_provider).value?.bardController;
    //       if (controller != null) {
    //         await ImageHandler.insertImage(
    //           imageData: data,
    //           controller: controller,
    //           projectId: ref.read(projectsProvider).selectedProject.id,
    //           noteId: _artifact?.title ?? '',
    //           userName: ref.read(currentUserProvider).name,
    //         );
    //       }
    //     },
    //     onError: (error) => debugPrint('Error reading file: $error'),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return Container();

    final noteState = ref.watch(_provider);

    final item = ref.watch(_provider.select((state) => state.value?.note));
    if (item == null) {
      return const Center(
        child: Text(
          'No item selected',
          style: NarwhalTextStyle(),
        ),
      );
    }

    return noteState.when(
      loading: () => Center(child: NarwhalSpinner()),
      error: (error, _) => _ErrorView(
        error: error,
        onRetry: () => ref.invalidate(_provider),
      ),
      data: (state) {
        final controller = state.bardController;
        if (controller == null) {
          return const Center(
            child: Text(
              'Note not initialized',
              style: NarwhalTextStyle(),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(_provider.notifier).setFocusNode(_focusNode);
          }
        });

        return SizedBox.expand(
          child: _NoteEditorContent(
            controller: controller,
            collab: state.collabConfig,
            state: state,
            focusNode: _focusNode,
            scrollController: _scrollController,
            showHoverContainer: _showHoverContainer,
            hoverPosition: _hoverPosition,
            isDragOver: _isDragOver,
            provider: _provider,
            onDragOver: (over) => setState(() => _isDragOver = over),
            onImageDrop: _handleImageDrop,
            onTapDown: (details) {
              _focusNode.requestFocus();
            },
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          Text(
            'Error: $error',
            style: NarwhalTextStyle(
              color: ThemeHelper.errorColor(),
            ),
          ),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry', style: NarwhalTextStyle()),
          ),
        ],
      ),
    );
  }
}

class _NoteEditorContent extends StatefulWidget {
  final BardController controller;
  final BardCollabConfig? collab;
  final NoteState state;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool showHoverContainer;
  final Offset? hoverPosition;
  final bool isDragOver;
  final NoteStateProvider provider;
  final void Function(bool) onDragOver;
  final Future<void> Function(PerformDropEvent) onImageDrop;
  final void Function(TapDownDetails) onTapDown;

  const _NoteEditorContent({
    required this.controller,
    required this.collab,
    required this.state,
    required this.focusNode,
    required this.scrollController,
    required this.showHoverContainer,
    required this.hoverPosition,
    required this.isDragOver,
    required this.provider,
    required this.onDragOver,
    required this.onImageDrop,
    required this.onTapDown,
  });

  @override
  State<_NoteEditorContent> createState() => _NoteEditorContentState();
}

class _NoteEditorContentState extends State<_NoteEditorContent> {
  final GlobalKey _editorKey = GlobalKey();
  double? _editorHeight;
  double? _editorWidth;
  bool _isGhostTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateEditorHeight());
  }

  @override
  void dispose() {
    _isGhostTyping = false;
    super.dispose();
  }

  void _toggleGhostType() {
    if (_isGhostTyping) {
      setState(() => _isGhostTyping = false);
    } else {
      setState(() => _isGhostTyping = true);
      _runGhostType();
    }
  }

  Future<void> _runGhostType() async {
    for (int i = 0; i < _kGhostLorem.length; i++) {
      await Future.delayed(_kGhostTypeDelay);
      if (!mounted || !_isGhostTyping) break;
      final controller = widget.controller;
      controller.text = controller.text + _kGhostLorem[i];
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
    }
    if (mounted && _isGhostTyping) {
      setState(() => _isGhostTyping = false);
    }
  }

  void _updateEditorHeight() {
    final RenderBox? renderBox =
        _editorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final newHeight = renderBox.size.height;
      final newWidth = renderBox.size.width;
      if (_editorHeight != newHeight || _editorWidth != newWidth) {
        setState(() {
          _editorHeight = newHeight;
          _editorWidth = newWidth;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(
            builder: (context, cardConstraints) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _updateEditorHeight());

              return DropRegion(
                key: _editorKey,
                formats: Formats.standardFormats,
                hitTestBehavior: HitTestBehavior.opaque,
                onDropOver: (event) {
                  widget.onDragOver(true);
                  return event.session.allowedOperations.firstOrNull ??
                      DropOperation.none;
                },
                onPerformDrop: widget.onImageDrop,
                onDropLeave: (_) => widget.onDragOver(false),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _NoteEditorField(
                      controller: widget.controller,
                      collab: widget.collab,
                      focusNode: widget.focusNode,
                      scrollController: widget.scrollController,
                      provider: widget.provider,
                      onTapDown: widget.onTapDown,
                    ),
                    _DragOverlay(isDragOver: widget.isDragOver),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: OnyxiaIconButton(
                        icon: LucideIcons.ghost,
                        isSelected: _isGhostTyping,
                        tooltip: 'Ghost-type lorem ipsum (debug)',
                        onPressed: _toggleGhostType,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _NoteEditorField extends ConsumerWidget {
  final BardController controller;
  final BardCollabConfig? collab;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final NoteStateProvider provider;
  final void Function(TapDownDetails) onTapDown;

  const _NoteEditorField({
    required this.controller,
    required this.collab,
    required this.focusNode,
    required this.scrollController,
    required this.provider,
    required this.onTapDown,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalMargin =
            ((constraints.maxWidth - 800.0) / 2).clamp(0.0, double.infinity);
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  left: (horizontalMargin - 5).clamp(0.0, double.infinity),
                  right: horizontalMargin,
                ),
                child: NoteTitleField(
                    provider: provider, nextFocusNode: focusNode),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
                child: BardEditor(
                  controller: controller,
                  collab: collab,
                  style: NarwhalTextStyle(),
                  autofocus: true,
                  focusNode: focusNode,
                  availableWikiTargets: ref.watch(wikiLinkTitlesProvider),
                  onWikiLinkTapped: (title) {
                    final vaultId = ref.read(selectedVaultProvider)?.id;
                    context.go('/vault/$vaultId/$title');
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DragOverlay extends StatelessWidget {
  final bool isDragOver;

  const _DragOverlay({required this.isDragOver});

  @override
  Widget build(BuildContext context) {
    if (!isDragOver) return const SizedBox.shrink();
    return Positioned.fill(
      child: Container(
        color: ThemeHelper.blue500(context).withValues(alpha: 0.1),
        child: Center(
          child: Text(
            'Drop image here',
            style: NarwhalTextStyle(
              fontSize: 18,
              color: ThemeHelper.blue500(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
