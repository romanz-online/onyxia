import 'package:onyxia/export.dart';

class Note extends Artifact {
  final String content;

  Note({
    super.id,
    super.type = ArtifactType.note,
    super.name = 'Untitled',
    super.parentFolderId,
    //
    super.createdAt,
    super.createdBy,
    super.updatedAt,
    super.updatedBy,
    //
    this.content = '',
  });

  @override
  Note copyWith({
    String? id, 
    String? name,
    String? parentFolderId,
    String? content,
  }) {
    return Note(
      id: id ?? this.id,
      name: name ?? this.name, 
      parentFolderId: parentFolderId ?? this.parentFolderId,
      //
      content: content ?? this.content,
    );
  }

  @override
  Map<String, dynamic> toMapSub() {
    return {'content': content};
  }

  Note.fromMap(super.map)
      : content =
            ((map['body'] as Map<String, dynamic>?)?['content'] as String?) ??
                '',
        super.fromMap();

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
