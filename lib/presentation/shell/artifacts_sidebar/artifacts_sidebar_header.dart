import 'package:onyxia/export.dart';

class ArtifactsSidebarHeader extends ConsumerWidget {
  const ArtifactsSidebarHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedVault = ref.watch(selectedVaultProvider);
    if (selectedVault == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ThemeHelper.auxiliary(), width: 1),
        ),
      ),
      padding: .symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: .center,
        spacing: 6,
        children: [
          OnyxiaIconButton(
            icon: LucideIcons.filePlus,
            tooltip: 'New note',
            onPressed: () async {
              await ArtifactsRepository(
                vaultId: selectedVault.id,
              ).add([NoteArtifact()]);
            },
          ),
          OnyxiaIconButton(
            icon: LucideIcons.folderPlus,
            tooltip: 'New folder',
            onPressed: () async {
              await ArtifactsRepository(
                vaultId: selectedVault.id,
              ).add([FolderArtifact()]);
            },
          ),
          OnyxiaIconButton(
            icon: LucideIcons.layoutGrid,
            tooltip: 'New canvas',
            onPressed: () async {
              await ArtifactsRepository(
                vaultId: selectedVault.id,
              ).add([CanvasArtifact()]);
            },
          ),
          OnyxiaIconButton(
            icon: LucideIcons.imagePlus,
            tooltip: 'Upload image',
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: .image,
                allowMultiple: true,
                withData: true,
              );
              if (result == null) return;
              for (final file in result.files) {
                if (file.bytes == null) continue;
                await ImageService.uploadImage(
                  file.bytes!,
                  file.name,
                  vaultId: selectedVault.id,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
