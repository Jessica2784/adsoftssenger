import 'dart:typed_data';

class ProfileStatus {
  final String id;
  final String note;
  final Uint8List? imageBytes;
  final String? imageName;
  final DateTime createdAt;

  ProfileStatus({
    String? id,
    this.note = '',
    this.imageBytes,
    this.imageName,
    DateTime? createdAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now();

  bool get hasNote => note.trim().isNotEmpty;
  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;
  bool get isEmpty => !hasNote && !hasImage;
}

class User {
  final String id;
  String name;
  String profileUrl;
  bool isOnline;
  String? description;
  final List<ProfileStatus> statuses;
  Uint8List? avatarBytes;

  User({
    required this.id,
    required this.name,
    required this.profileUrl,
    this.isOnline = false,
    this.description,
    String? statusNote,
    List<ProfileStatus>? statuses,
    this.avatarBytes,
  }) : statuses = _initialStatuses(statusNote, statuses);

  static List<ProfileStatus> _initialStatuses(
    String? statusNote,
    List<ProfileStatus>? statuses,
  ) {
    return [
      if (statuses != null) ...statuses.where((status) => !status.isEmpty),
      if (statusNote != null && statusNote.trim().isNotEmpty)
        ProfileStatus(note: statusNote.trim()),
    ];
  }

  ProfileStatus? get latestStatus {
    for (final status in statuses.reversed) {
      if (!status.isEmpty) return status;
    }
    return null;
  }

  String? get statusNote {
    for (final status in statuses.reversed) {
      if (status.hasNote) return status.note.trim();
    }
    return null;
  }

  set statusNote(String? value) {
    final trimmedValue = value?.trim() ?? '';
    statuses.removeWhere((status) => status.hasNote && !status.hasImage);
    if (trimmedValue.isNotEmpty) {
      addStatus(ProfileStatus(note: trimmedValue));
    }
  }

  bool get hasStatuses => statuses.any((status) => !status.isEmpty);
  bool get hasPhotoStatus => statuses.any((status) => status.hasImage);
  int get statusCount => statuses.where((status) => !status.isEmpty).length;

  String get statusPreview {
    final status = latestStatus;
    if (status == null) return '';
    if (status.hasNote) return status.note.trim();
    if (status.hasImage) return 'Foto';
    return '';
  }

  void addStatus(ProfileStatus status) {
    if (!status.isEmpty) statuses.add(status);
  }

  void clearStatuses() {
    statuses.clear();
  }
}
