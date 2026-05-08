import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/presentation/artifact_editor/note/note_title_field.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:onyxia/export.dart';

class NoteEditorView extends ConsumerStatefulWidget {
  final SaveMode saveMode;
  final NoteStateProvider? provider;

  const NoteEditorView({
    super.key,
    this.saveMode = SaveMode.auto,
    this.provider,
  });

  @override
  ConsumerState<NoteEditorView> createState() => _EditorState();
}

class _EditorState extends ConsumerState<NoteEditorView> {
  NoteStateProvider get _provider => widget.provider ?? selectedNoteStateProvider;
  Note? get _artifact => ref.read(_provider).value?.note;
  String get _selectedNoteId => _artifact?.id ?? '';

  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Comment state
  bool _showComment = false;
  Comment? _currentComment;
  String? _selectedCommentId;
  Offset? _localPosition;
  final GlobalKey _commentWidgetKey = GlobalKey();

  // Hover state
  bool _showHoverContainer = false;
  Offset? _hoverPosition;
  String? _hoveredCommentId;

  // Drag state
  bool _isDragOver = false;

  String? _currentNoteId;
  Comment? _previousSelectedComment;

  // TODO: handle inserting images
  // static const _imageFormats = [Formats.png, Formats.jpeg, Formats.bmp, Formats.gif];

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
      _showComment = false;
      _currentComment = null;
      _selectedCommentId = null;
      _localPosition = null;
      _showHoverContainer = false;
      _hoverPosition = null;
      _hoveredCommentId = null;
      _isDragOver = false;
      _previousSelectedComment = null;
    });
    ref.read(commentsProvider(_selectedNoteId).notifier).setSelectedComment(null);
  }

  void _handleCommentCreate([Offset? contextMenuPosition]) {
    final position = contextMenuPosition ?? _localPosition ?? const Offset(100, 100);
    final newComment = Comment(
      id: const Uuid().v4(),
      text: '',
      authorId: ref.read(currentUserProvider).id,
      position: position,
      color: ThemeHelper.yellow(),
      subComments: [],
      createdAt: DateTime.now(),
    );
    setState(() {
      _showComment = true;
      _currentComment = newComment;
      _localPosition = position;
    });
    ref.read(commentsProvider(_selectedNoteId).notifier).setSelectedComment(newComment);
  }

  void _clearCommentSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _showComment = false;
          _currentComment = null;
          _localPosition = null;
          _selectedCommentId = null;
        });
        ref.read(commentsProvider(_selectedNoteId).notifier).setSelectedComment(null);
      }
    });
  }

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

    final authState = ref.watch(authProvider);
    final noteState = ref.watch(_provider);

    final item = ref.watch(_provider.select((state) => state.value?.note));
    if (item == null) {
      return const Center(child: Text('No item selected', style: NarwhalTextStyle()));
    }

    final selectedComment =
        ref.watch(commentsProvider(_selectedNoteId).select((state) => state.selectedComment));

    if (selectedComment != _previousSelectedComment) {
      _previousSelectedComment = selectedComment;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleExternalCommentSelection(selectedComment);
      });
    }

    authState.whenData((user) {
      if (user == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.invalidate(_provider);
            _resetEditorState();
            _currentNoteId = null;
          }
        });
      }
    });

    return noteState.when(
      loading: () => Center(child: NarwhalSpinner()),
      error: (error, _) => _ErrorView(
        error: error,
        onRetry: () => ref.invalidate(_provider),
      ),
      data: (state) {
        final controller = state.bardController;
        if (controller == null) {
          return const Center(child: Text('Document not initialized'));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(_provider.notifier).setFocusNode(_focusNode);
          }
        });

        return SizedBox.expand(
          child: _EditorContent(
            controller: controller,
            state: state,
            focusNode: _focusNode,
            scrollController: _scrollController,
            showComment: _showComment,
            currentComment: _currentComment,
            localPosition: _localPosition,
            showHoverContainer: _showHoverContainer,
            hoverPosition: _hoverPosition,
            hoveredCommentId: _hoveredCommentId,
            isDragOver: _isDragOver,
            commentWidgetKey: _commentWidgetKey,
            selectedComment: selectedComment,
            provider: _provider,
            onCommentCreate: _handleCommentCreate,
            onCommentClose: _clearCommentSelection,
            onDragOver: (over) => setState(() => _isDragOver = over),
            onImageDrop: _handleImageDrop,
            onTapDown: (details) {
              setState(() => _localPosition = details.localPosition);
              _focusNode.requestFocus();
            },
            onCommentTapOutside: () {
              if (_showComment && _currentComment != null) {
                _clearCommentSelection();
              }
            },
          ),
        );
      },
    );
  }

  void _handleExternalCommentSelection(Comment selectedComment) {
    if (selectedComment.id.isNotEmpty) {
      if (_currentComment == null || _currentComment!.id != selectedComment.id) {
        if (mounted) {
          setState(() {
            _showComment = true;
            _currentComment = selectedComment;
            _localPosition = selectedComment.position ?? _localPosition ?? const Offset(100, 100);
            _selectedCommentId = selectedComment.id;
          });
        }
      } else if (_currentComment != null && _currentComment!.id == selectedComment.id) {
        _currentComment = selectedComment;
      }
    } else if (_selectedCommentId != null) {
      if (mounted) _clearCommentSelection();
    }
  }
}

class _ErrorView extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EditorContent extends StatefulWidget {
  final BardController controller;
  final NoteState state;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool showComment;
  final Comment? currentComment;
  final Offset? localPosition;
  final bool showHoverContainer;
  final Offset? hoverPosition;
  final String? hoveredCommentId;
  final bool isDragOver;
  final GlobalKey commentWidgetKey;
  final Comment selectedComment;
  final NoteStateProvider provider;
  final void Function([Offset?]) onCommentCreate;
  final VoidCallback onCommentClose;
  final void Function(bool) onDragOver;
  final Future<void> Function(PerformDropEvent) onImageDrop;
  final void Function(TapDownDetails) onTapDown;
  final VoidCallback onCommentTapOutside;

  const _EditorContent({
    required this.controller,
    required this.state,
    required this.focusNode,
    required this.scrollController,
    required this.showComment,
    required this.currentComment,
    required this.localPosition,
    required this.showHoverContainer,
    required this.hoverPosition,
    required this.hoveredCommentId,
    required this.isDragOver,
    required this.commentWidgetKey,
    required this.selectedComment,
    required this.provider,
    required this.onCommentCreate,
    required this.onCommentClose,
    required this.onDragOver,
    required this.onImageDrop,
    required this.onTapDown,
    required this.onCommentTapOutside,
  });

  @override
  State<_EditorContent> createState() => _EditorContentState();
}

class _EditorContentState extends State<_EditorContent> {
  final GlobalKey _editorKey = GlobalKey();
  double? _editorHeight;
  double? _editorWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateEditorHeight());
  }

  void _updateEditorHeight() {
    final RenderBox? renderBox = _editorKey.currentContext?.findRenderObject() as RenderBox?;
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
          child: EditorContextMenu(
            onComment: widget.onCommentCreate,
            child: LayoutBuilder(
              builder: (context, cardConstraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _updateEditorHeight());

                return DropRegion(
                  key: _editorKey,
                  formats: Formats.standardFormats,
                  hitTestBehavior: HitTestBehavior.opaque,
                  onDropOver: (event) {
                    widget.onDragOver(true);
                    return event.session.allowedOperations.firstOrNull ?? DropOperation.none;
                  },
                  onPerformDrop: widget.onImageDrop,
                  onDropLeave: (_) => widget.onDragOver(false),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _EditorField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        scrollController: widget.scrollController,
                        selectedComment: widget.selectedComment,
                        provider: widget.provider,
                        onTapDown: widget.onTapDown,
                        showComment: widget.showComment,
                        currentComment: widget.currentComment,
                        commentWidgetKey: widget.commentWidgetKey,
                        onCommentTapOutside: widget.onCommentTapOutside,
                      ),
                      _DragOverlay(isDragOver: widget.isDragOver),
                      if (widget.showHoverContainer &&
                          !widget.showComment &&
                          widget.hoverPosition != null &&
                          widget.hoveredCommentId != null)
                        Positioned(
                          left: widget.hoverPosition!.dx + 10.0,
                          top: widget.hoverPosition!.dy + -40.0,
                          child: IgnorePointer(
                            child: HoverCommentContainer(
                              hoveredCommentId: widget.hoveredCommentId!,
                            ),
                          ),
                        ),
                      if (widget.showComment && widget.currentComment != null && widget.localPosition != null)
                        Builder(
                          builder: (context) {
                            return ArtifactComment(
                              key: widget.commentWidgetKey,
                              comment: widget.currentComment!,
                              localPosition: widget.localPosition,
                              onClose: widget.onCommentClose,
                              editorHeight: _editorHeight,
                              editorWidth: _editorWidth,
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _EditorField extends ConsumerWidget {
  final BardController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final Comment selectedComment;
  final NoteStateProvider provider;
  final void Function(TapDownDetails) onTapDown;
  final bool showComment;
  final Comment? currentComment;
  final GlobalKey commentWidgetKey;
  final VoidCallback onCommentTapOutside;

  const _EditorField({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.selectedComment,
    required this.provider,
    required this.onTapDown,
    required this.showComment,
    required this.currentComment,
    required this.commentWidgetKey,
    required this.onCommentTapOutside,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalMargin = ((constraints.maxWidth - 800.0) / 2).clamp(0.0, double.infinity);
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  left: (horizontalMargin - 5).clamp(0.0, double.infinity),
                  right: horizontalMargin,
                ),
                child: NoteTitleField(provider: provider, nextFocusNode: focusNode),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
                child: BardEditor(
                  controller: controller,
                  style: NarwhalTextStyle(),
                  autofocus: true,
                  focusNode: focusNode,
                  availableWikiTargets: ref.watch(wikiLinkTitlesProvider),
                  onWikiLinkTapped: (title) {
                    final projectId = ref.read(projectsProvider).selectedProject.id;
                    context.go('/project/$projectId/$title');
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
