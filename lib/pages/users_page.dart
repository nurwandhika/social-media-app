import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/components/my_list_tile.dart';
import 'package:minimalsocialmedia/helper/helper_functions.dart';

import '../components/my_back_buttton.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text("Users"),
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   elevation: 0,
      // ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("Users").snapshots(),
        builder: (context, snapshot) {
          //any errors
          if (snapshot.hasError) {
            displayMessageToUser("Something went wrong", context);
          }

          //show loading circle
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null) {
            return const Text("No Data");
          }
          //get all users
          final users = snapshot.data!.docs;

          return Column(
            children: [
              //back button
              const Padding(
                padding: const EdgeInsets.only(top: 50.0, left: 25.0),
                child: Row(children: [MyBackButton()]),
              ),

              //list of users in the app
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.all(0),
                  itemBuilder: (context, index) {
                    //get individual user
                    final user = users[index];

                    //get data from each user
                    String username = user['username'];
                    String email = user['email'];

                    return MyListTile(title: username, subTitle: email);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
