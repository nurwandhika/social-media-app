import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/my_back_buttton.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  //future to fetch user details
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    print("Current user email: ${currentUser.email}");
    final doc =
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(currentUser.email)
            .get();
    if (!doc.exists) {
      print("No document found for user: ${currentUser.email}");
    }
    return doc;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Profile"),
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   elevation: 0,
      // ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getUserDetails(),
        builder: (context, snapshot) {
          //loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          //error
          else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          //data received
          else if (snapshot.hasData) {
            //extract data
            Map<String, dynamic>? user = snapshot.data!.data();
            if (user == null) {
              return const Text("No user data found");
            }
            return Center(
              child: Column(
                children: [
                  //back button
                  const Padding(
                    padding: const EdgeInsets.only(top: 50.0, left: 25.0),
                    child: Row(children: [MyBackButton()]),
                  ),

                  const SizedBox(height: 25),

                  //profile pic
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),

                    padding: const EdgeInsets.all(25.0),
                    child: const Icon(Icons.person, size: 64),
                  ),

                  const SizedBox(height: 25),

                  //username
                  Text(
                    user!['username'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  //email
                  Text(
                    user['email'],
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
