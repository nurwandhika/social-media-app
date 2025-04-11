class PostModel {
  final String postId;
  final String content;          // Renamed from caption
  final String authorUsername;
  final String authorEmail;
  int likes;
  final DateTime createdAt;
  List<String> likedBy;

  PostModel({
    required this.postId,
    required this.content,
    required this.authorUsername,
    required this.authorEmail,
    this.likes = 0,
    required this.createdAt,
    this.likedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'content': content,
      'authorUsername': authorUsername,
      'authorEmail': authorEmail,
      'likes': likes,
      'createdAt': createdAt.toIso8601String(),
      'likedBy': likedBy,
    };
  }
}