import 'package:onyxia/export.dart';

class Note extends Artifact {
  final String content;

  Note({
    super.id,
    super.title = 'Untitled',
    super.parent,
    super.createdAt,
    super.createdBy,
    super.type = ArtifactType.note,
    this.content = '',
  });

  @override
  Note copyWith({
    String? id,
    String? parentId,
    String? title,
    DateTime? createdAt,
    String? createdBy,
    ArtifactType? type,
    String? updatedBy,
    DateTime? updatedAt,
    String? content,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      parent: parentId ?? this.parent,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      type: type ?? this.type,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, dynamic> toMapSub() {
    return {'content': content};
  }

  Note.fromMap(super.map)
      : content = ((map['body'] as Map<String, dynamic>?)?['content'] as String?) ?? '',
        super.fromMap();

  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));

  @override
  String toString() {
    return '${super.toString()}'
        'content: $content, '
        '))';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return super == other && other is Note && other.content == content;
  }

  @override
  int get hashCode => super.hashCode ^ content.hashCode;

  String get plainText => content;
}
