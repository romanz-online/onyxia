import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import '../services/services.dart';

class CanvasSearchOverlay extends ConsumerStatefulWidget {
  const CanvasSearchOverlay({super.key});

  @override
  ConsumerState<CanvasSearchOverlay> createState() =>
      _CanvasSearchOverlayState();
}

class _CanvasSearchOverlayState extends ConsumerState<CanvasSearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  OutlineInputBorder get _commonInputBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ThemeHelper.neutral300(context)),
      );

  @override
  void initState() {
    super.initState();

    // Listen to text changes for real-time filtering
    _controller.addListener(() {
      setState(() {}); // Trigger rebuild for clear button visibility
    });

    // Auto-focus the search field when overlay appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
  }

  void _closeOverlay() {
    _clearSearch();
    ref.read(dragOffDropPositionProvider.notifier).set(null);
    ref.read(canvasSettingsProvider(Setting.showSearchOverlay).notifier).set(false);
  }

  void _createArtifact(Artifact item) async {
    await CanvasInteractionService.createArtifactObject(
      ref: ref,
      position: ref.read(dragOffDropPositionProvider) ??
          ref.read(canvasViewportProvider.notifier).getViewportCenter(),
      artifact: item,
    );

    // Clear drop position after creating the item
    ref.read(dragOffDropPositionProvider.notifier).set(null);
  }

  List<Artifact> _getFilteredItems() {
    final items = ref.watch(artifactsProvider);
    final searchText = _controller.text;

    if (searchText.isEmpty) return items;

    return items
        .where((e) => e.name.toLowerCase().contains(searchText.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _getFilteredItems();

    return GestureDetector(
      onTap: _closeOverlay, // Close when clicking on background
      child: Container(
        color: ThemeHelper.neutral900(context).withValues(alpha: 0.6),
        child: GestureDetector(
          onTap: () {}, // Prevent closing when clicking on search content
          child: Column(
            children: [
              // Search bar section
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event.logicalKey == LogicalKeyboardKey.escape) {
                        _closeOverlay();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Search Artifacts...',
                        hintStyle: NarwhalTextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.normal,
                          color: ThemeHelper.neutral500(context),
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: NarwhalIcon(NarwhalIcons.search, size: 20),
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: NarwhalIconButton(
                                  icon: NarwhalIcons.close,
                                  onPressed: _clearSearch,
                                  size: 20,
                                ),
                              )
                            : null,
                        isDense: false,
                        border: _commonInputBorder,
                        focusedBorder: _commonInputBorder.copyWith(
                          borderSide: BorderSide(
                            color: ThemeHelper.blue400(context),
                            width: 2,
                          ),
                        ),
                        enabledBorder: _commonInputBorder,
                        filled: true,
                        fillColor: ThemeHelper.white(context),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                      ),
                      style: const NarwhalTextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(12),
              if (filteredNotes.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      decoration: BoxDecoration(
                        color: ThemeHelper.white(context),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeHelper.neutral900(context)
                                .withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: Scrollbar(
                          controller: _scrollController,
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: filteredNotes.length,
                            separatorBuilder: (context, index) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Divider(
                                height: 1,
                                color: ThemeHelper.neutral300(context),
                              ),
                            ),
                            itemBuilder: (context, index) {
                              final note = filteredNotes[index];
                              return HoverBuilder(
                                builder: (context, isHovering) => InkWell(
                                  onTap: () {
                                    _createArtifact(note);
                                    _closeOverlay();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: isHovering
                                          ? ThemeHelper.neutral300(context)
                                          : Colors.transparent,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                note.name,
                                                style: const NarwhalTextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
