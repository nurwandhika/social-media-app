// dart
class PostModel {
  final String postId;
  // final String title;
  final String caption;
  final List<String> imageUrls;
  final String authorUsername;
  final String authorEmail; // new field for author's email
  // final String group;
  // final String topic;
  int likes;
  final DateTime createdAt;
  List<String> likedBy;

  PostModel({
    required this.postId,
    // required this.title,
    required this.caption,
    required this.imageUrls,
    required this.authorUsername,
    required this.authorEmail,
    // required this.group,
    // required this.topic,
    this.likes = 0,
    required this.createdAt,
    this.likedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      // 'title': title,
      'caption': caption,
      'imageUrls': imageUrls,
      'authorUsername': authorUsername,
      'authorEmail': authorEmail, // include in map
      // 'group': group,
      // 'topic': topic,
      'likes': likes,
      'createdAt': createdAt.toIso8601String(),
      'likedBy': likedBy,
    };
  }
}