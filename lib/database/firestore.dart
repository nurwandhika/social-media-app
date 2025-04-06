// dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:minimalsocialmedia/models/post_model.dart';

class FirestoreDatabase {
  User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference posts =
  FirebaseFirestore.instance.collection("Posts");

  Future<void> addPost(PostModel post) async {
    await posts.doc(post.postId).set(post.toMap());
  }

  Future<void> toggleLike(String postId) async {
    final uid = user!.uid;
    DocumentReference postRef = posts.doc(postId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final postAuthorEmail = data['authorEmail'];
      T getValue<T>(String key, T defaultValue) {
        if (data.toString().contains(key) && data[key] != null) {
          return data[key] as T;
        }
        return defaultValue;
      }
      List<dynamic> likedBy = getValue<List<dynamic>>('likedBy', []);
      int currentLikes = getValue<int>('likes', 0);
      if (likedBy.contains(uid)) {
        transaction.update(postRef, {
          'likedBy': FieldValue.arrayRemove([uid]),
          'likes': currentLikes - 1,
        });
        if (postAuthorEmail != null) {
          final userDocRef =
          FirebaseFirestore.instance.collection("Users").doc(postAuthorEmail);
          transaction.update(userDocRef, {
            'totalLikes': FieldValue.increment(-1),
          });
        }
      } else {
        transaction.update(postRef, {
          'likedBy': FieldValue.arrayUnion([uid]),
          'likes': currentLikes + 1,
        });
        if (postAuthorEmail != null) {
          final userDocRef =
          FirebaseFirestore.instance.collection("Users").doc(postAuthorEmail);
          transaction.update(userDocRef, {
            'totalLikes': FieldValue.increment(1),
          });
        }
      }
    });
  }

  Future<void> addReply(String postId, Map<String, dynamic> replyData) async {
    await posts.doc(postId).collection('comments').add(replyData);
  }

  Stream<QuerySnapshot> getPostsStream() {
    return posts.orderBy('createdAt', descending: true).snapshots();
  }
}