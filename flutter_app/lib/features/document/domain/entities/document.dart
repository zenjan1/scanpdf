import 'package:equatable/equatable.dart';

class Document extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int pageCount;
  final List<String> tags;
  final String filePath;
  final String? thumbnailPath;
  final bool isFavorite;
  final bool isDeleted;
  final String? cloudId;
  final SyncStatus syncStatus;

  const Document({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.pageCount,
    required this.tags,
    required this.filePath,
    this.thumbnailPath,
    this.isFavorite = false,
    this.isDeleted = false,
    this.cloudId,
    this.syncStatus = SyncStatus.local,
  });

  Document copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? pageCount,
    List<String>? tags,
    String? filePath,
    String? thumbnailPath,
    bool? isFavorite,
    bool? isDeleted,
    String? cloudId,
    SyncStatus? syncStatus,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pageCount: pageCount ?? this.pageCount,
      tags: tags ?? this.tags,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
      cloudId: cloudId ?? this.cloudId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'pageCount': pageCount,
      'tags': tags.join(','),
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'isFavorite': isFavorite ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'cloudId': cloudId,
      'syncStatus': syncStatus.name,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      pageCount: map['pageCount'] as int,
      tags: (map['tags'] as String)
          .split(',')
          .where((t) => t.isNotEmpty)
          .toList(),
      filePath: map['filePath'] as String,
      thumbnailPath: map['thumbnailPath'] as String?,
      isFavorite: (map['isFavorite'] as int) == 1,
      isDeleted: (map['isDeleted'] as int) == 1,
      cloudId: map['cloudId'] as String?,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == (map['syncStatus'] as String? ?? 'local'),
        orElse: () => SyncStatus.local,
      ),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        updatedAt,
        pageCount,
        tags,
        filePath,
        thumbnailPath,
        isFavorite,
        isDeleted,
        cloudId,
        syncStatus,
      ];
}

enum SyncStatus { local, syncing, synced, error }

