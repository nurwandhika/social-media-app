import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:minimalsocialmedia/models/post_model.dart';

class FirestoreDatabase {
  // Avoid storing Firebase Auth as a field
  final CollectionReference posts = FirebaseFirestore.instance.collection(
    "Posts",
  );

  Future<void> addPost(PostModel post) async {
    await posts.doc(post.postId).set(post.toMap());
  }

  Future<void> toggleLike(String postId) async {
    // Get current user
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final String userEmail = user.email!;
    DocumentReference postRef = posts.doc(postId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(postRef);
        if (!snapshot.exists) {
          print("Post does not exist: $postId");
          return;
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final postAuthorEmail = data['authorEmail'];

        // Convert likedBy to List<String>
        List<String> likedBy = [];
        if (data.containsKey('likedBy') && data['likedBy'] is List) {
          likedBy = List<String>.from(data['likedBy']);
        }

        bool hasLiked = likedBy.contains(userEmail);

        if (hasLiked) {
          // Unlike the post
          transaction.update(postRef, {
            'likedBy': FieldValue.arrayRemove([userEmail]),
            'likes': FieldValue.increment(-1),
          });

          // Update author's total likes
          if (postAuthorEmail != null) {
            final userDocRef = FirebaseFirestore.instance
                .collection("Users")
                .doc(postAuthorEmail);
            transaction.update(userDocRef, {
              'totalLikes': FieldValue.increment(-1),
            });
          }
        } else {
          // Like the post
          transaction.update(postRef, {
            'likedBy': FieldValue.arrayUnion([userEmail]),
            'likes': FieldValue.increment(1),
          });

          // Update author's total likes
          if (postAuthorEmail != null) {
            final userDocRef = FirebaseFirestore.instance
                .collection("Users")
                .doc(postAuthorEmail);
            transaction.update(userDocRef, {
              'totalLikes': FieldValue.increment(1),
            });
          }
        }
      });
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  // Add this method for proper post deletion
  Future<void> deletePost(String postId) async {
    try {
      // Get the post first to know its likes count
      DocumentSnapshot postDoc = await posts.doc(postId).get();

      if (!postDoc.exists) return;

      final data = postDoc.data() as Map<String, dynamic>;
      final postAuthorEmail = data['authorEmail'];
      final int likesCount = data['likes'] ?? 0;

      // Update author's total likes by decreasing the likes count of deleted post
      if (postAuthorEmail != null && likesCount > 0) {
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(postAuthorEmail)
            .update({'totalLikes': FieldValue.increment(-likesCount)});
      }

      // Delete the post
      await posts.doc(postId).delete();
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  Future<void> addReply(String postId, Map<String, dynamic> replyData) async {
    await posts.doc(postId).collection('comments').add(replyData);
  }

  Stream<QuerySnapshot> getPostsStream() {
    return posts.orderBy('createdAt', descending: true).snapshots();
  }
}
