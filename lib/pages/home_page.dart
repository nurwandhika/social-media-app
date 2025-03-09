import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/components/my_drawer.dart';
import 'package:minimalsocialmedia/components/my_post_button.dart';
import 'package:minimalsocialmedia/components/my_textfield.dart';
import 'package:minimalsocialmedia/database/firestore.dart';

import '../components/my_list_tile.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  //firestore access
  final FirestoreDatabase database = FirestoreDatabase();

  //Text Controller
  final TextEditingController newPostController = TextEditingController();

  //post message
  void postMessage() {
    //only post message if there is something in the text field
    if (newPostController.text.isNotEmpty) {
      String message = newPostController.text;
      database.addPost(message);
    }

    //clear the controller
    newPostController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("Timeline"),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      drawer: MyDrawer(),
      body: Column(
        children: [
          //TEXTFIELD BOX FOR USER TO POST
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              children: [
                //textfield
                Expanded(
                  child: MyTextfield(
                    hintText: "What's on your mind?",
                    obscureText: false,
                    controller: newPostController,
                  ),
                ),

                //post button
                PostButton(onTap: postMessage),
              ],
            ),
          ),

          //POSTS
          StreamBuilder(
            stream: database.getPostsStream(),
            builder: (context, snapshot) {
              //if show loading circle
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              //get all posts
              final posts = snapshot.data!.docs;

              //no data?
              if (snapshot.data == null || posts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(25.0),
                    child: Text("No posts yet"),
                  ),
                );
              }

              //return as a list
              return Expanded(
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    //get each individual post
                    final post = posts[index];

                    //get data from each post
                    String message = post['PostMessage'];
                    String userEmail = post['UserEmail'];
                    String timestamp = post['Timestamp'].toString();

                    //return as a list title
                    return MyListTile(title: message, subTitle: userEmail);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
