class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final DateTime? createdAt;
  final int trackCount;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.createdAt,
    this.trackCount = 0,
  });

  Playlist copyWith({
    String? name,
    String? description,
    String? coverUrl,
    int? trackCount,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt,
      trackCount: trackCount ?? this.trackCount,
    );
  }
}
