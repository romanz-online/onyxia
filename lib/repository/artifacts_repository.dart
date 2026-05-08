import 'package:onyxia/export.dart';

class ArtifactsRepository extends BaseSupabaseRepository<Artifact> {
  ArtifactsRepository({required super.projectId});

  @override
  String get tableName => 'artifacts';

  @override
  String get scopeField => 'project_id';

  @override
  String get defaultOrderBy => 'created_at';

  @override
  Artifact fromMap(Map<String, dynamic> map) => Artifact.factory(map);

  @override
  Map<String, dynamic> toMap(Artifact item) => item.toMap();

  @override
  String getIdFromItem(Artifact item) => item.id;

  Stream<List<CanvasModel>> getCanvasesStream() =>
      _streamByType<CanvasModel>(ArtifactType.canvas);

  Stream<List<T>> _streamByType<T extends Artifact>(ArtifactType type) {
    // Base scopes by project_id; post-filter by Dart type.
    return getStream().map((items) => items.whereType<T>().toList());
  }

  @override
  Future<void> add(List<Artifact> items) async {
    if (items.isEmpty) return;

    // Fetch only existing titles that could collide with this batch's bases.
    final taken = <String>{};
    for (final base in items.map((e) => e.title).toSet()) {
      final colliding = await query(field: 'name', startsWith: base);
      taken.addAll(colliding.map((e) => e.title));
    }

    final updatedList = items.map((e) {
      final uniqueTitle = _uniqueTitle(e.title, taken);
      taken.add(uniqueTitle);
      final id = e.id.isEmpty ? const Uuid().v4() : e.id;
      return e.copyWith(id: id, title: uniqueTitle);
    }).toList();

    return super.add(updatedList);
  }

  String _uniqueTitle(String baseTitle, Set<String> taken) {
    if (!taken.contains(baseTitle)) return baseTitle;
    int counter = 1;
    String candidate;
    do {
      candidate = '$baseTitle ($counter)';
      counter++;
    } while (taken.contains(candidate));
    return candidate;
  }
}
