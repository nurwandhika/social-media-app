// dart
class PostModel {
  final String postId;
  final String title; // up to 50 characters
  final String caption; // up to 280 characters
  final List<String> imageUrls; // up to 3
  final String authorUsername; // use username instead of email
  final String group; // for future grouping, e.g., Anime, Game, etc.
  int likes;
  final DateTime createdAt;
  List<String> likedBy; // new field for tracking users who liked the post

  PostModel({
    required this.postId,
    required this.title,
    required this.caption,
    required this.imageUrls,
    required this.authorUsername,
    required this.group,
    this.likes = 0,
    required this.createdAt,
    this.likedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'title': title,
      'caption': caption,
      'imageUrls': imageUrls,
      'authorUsername': authorUsername,
      'group': group,
      'likes': likes,
      'createdAt': createdAt.toIso8601String(),
      'likedBy': likedBy, // include the likedBy field
    };
  }
}