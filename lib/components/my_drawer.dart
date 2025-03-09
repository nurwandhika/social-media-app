import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  //logout user
  void logout(){
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //drawer header
          Column(
            children: [
              DrawerHeader(
                child: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),

              const SizedBox(height: 25),

              //home tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.home,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  title: Text("Home"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              //profile tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  title: const Text("Profile"),
                  onTap: () {
                    //pop drawer
                    Navigator.pop(context);

                    //navigate to profile page
                    Navigator.pushNamed(context, "/profile_page");

                  },
                ),
              ),
              //users tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.group,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  title: const Text("Users"),
                  onTap: () {
                    //pop drawer
                    Navigator.pop(context);

                    //navigate to users page
                    Navigator.pushNamed(context, "/users_page");
                  },
                ),
              ),
            ],
          ),

          //logout tile
          Padding(
            padding: const EdgeInsets.only(left: 25.0, bottom: 25.0),
            child: ListTile(
              leading: Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              title: Text("Logout"),
              onTap: () {
                //pop drawer
                Navigator.pop(context);

                //logout user
                logout();
              },
            ),
          ),

        ],
      ),
    );
  }
}
