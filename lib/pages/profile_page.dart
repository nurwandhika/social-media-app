// dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/my_back_buttton.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    final docRef =
    FirebaseFirestore.instance.collection("Users").doc(currentUser.email);
    final doc = await docRef.get();
    if (!doc.exists) {
      // Create new user document with totalLikes field initialized to 0.
      await docRef.set({
        'username': currentUser.displayName ?? 'Anonymous',
        'email': currentUser.email,
        'totalLikes': 0,
      });
      return await docRef.get();
    } else {
      // Ensure the totalLikes field is not null.
      if (doc.data()!['totalLikes'] == null) {
        await docRef.update({'totalLikes': 0});
        return await docRef.get();
      }
    }
    return doc;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else if (snapshot.hasData) {
            Map<String, dynamic>? user = snapshot.data!.data();
            if (user == null) {
              return const Text("No user data found");
            }
            return Center(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 50.0, left: 25.0),
                    child: Row(children: [MyBackButton()]),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(25.0),
                    child: const Icon(Icons.person, size: 64),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    user['username'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user['email'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Total Likes: ${user['totalLikes'] ?? 0}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          } else {
            return const Text("No data");
          }
        },
      ),
    );
  }
}