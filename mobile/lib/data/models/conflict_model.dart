import 'note_model.dart';

class ConflictInfoModel {
  final String noteId;
  final NoteModel local;
  final NoteModel remote;

  ConflictInfoModel({
    required this.noteId,
    required this.local,
    required this.remote,
  });

  factory ConflictInfoModel.fromJson(Map<String, dynamic> json) {
    return ConflictInfoModel(
      noteId: json['note_id'] as String,
      local: NoteModel.fromJson(json['local'] as Map<String, dynamic>),
      remote: NoteModel.fromJson(json['remote'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'note_id': noteId,
      'local': local.toJson(),
      'remote': remote.toJson(),
    };
  }
}

enum ConflictResolution {
  local,
  remote,
  both,
}

class ConflictResolvePayload {
  final String noteId;
  final ConflictResolution keep;

  ConflictResolvePayload({
    required this.noteId,
    required this.keep,
  });

  Map<String, dynamic> toJson() {
    return {
      'note_id': noteId,
      'keep': keep.name,
    };
  }
}
