import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/components/my_button.dart';
import 'package:minimalsocialmedia/components/my_textfield.dart';
import 'package:minimalsocialmedia/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  RegisterPage({
    Key? key,
    required this.onTap,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : this.auth = auth ?? FirebaseAuth.instance,
       this.firestore = firestore ?? FirebaseFirestore.instance,
       super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //text controller
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  //register method
  void registerUser() async {
    //show loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    //make user passwords match
    if (passwordController.text != confirmPwController.text) {
      //pop loading circle
      Navigator.pop(context);

      //show error message to user
      displayMessageToUser("Passwords do not match", context);
    } else if (passwordController.text.length < 8) {
      //pop loading circle
      Navigator.pop(context);

      //show error message to user
      displayMessageToUser(
        "Password must be at least 8 characters long.",
        context,
      );
    } else {
      //try creating the user
      try {
        // In registerUser method, replace:
        UserCredential? userCredential = await widget.auth
            .createUserWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );

        // In createUserDocument method, replace:
        await widget.firestore
            .collection("Users")
            .doc(userCredential.user!.email)
            .set({
              "email": userCredential.user!.email,
              "username": usernameController.text,
            });

        //create a user document and add to firestore
        createUserDocument(userCredential);

        //pop loading circle
        if (context.mounted) {
          Navigator.pop(context); // Menutup dialog loading

          //navigate to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(onTap: widget.onTap),
            ), // Mengarahkan pengguna ke halaman login
          );
        }
      } on FirebaseAuthException catch (e) {
        //pop loading circle
        Navigator.pop(context);

        //display error message to user
        displayMessageToUser(e.code, context);
      }
    }
  }

  void displayMessageToUser(String code, BuildContext context) {
    String message;
    switch (code) {
      case 'email-already-in-use':
        message = 'The email address is already in use by another account.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password accounts are not enabled.';
        break;
      case 'weak-password':
        message =
            'The password is too weak. It should be at least 8 characters long and include a combination of letters and numbers.';
        break;
      default:
        message = 'An unknown error occurred.';
    }
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Registration Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  //create a user document and collect them into firestore
  Future<void> createUserDocument(UserCredential? userCredential) async {
    if (userCredential != null && userCredential.user != null) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(userCredential.user!.email)
          .set({
            "email": userCredential.user!.email,
            "username": usernameController.text,
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //logo
              Icon(
                Icons.person,
                size: 80,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),

              const SizedBox(height: 10),
              //app name
              Text("Q U I C K T A L E", style: TextStyle(fontSize: 20)),

              const SizedBox(height: 25),

              //username textfield
              MyTextfield(
                hintText: "Username",
                obscureText: false,
                controller: usernameController,
              ),

              const SizedBox(height: 10),

              //email textfield
              MyTextfield(
                hintText: "Email",
                obscureText: false,
                controller: emailController,
              ),

              const SizedBox(height: 10),

              //password textfield
              MyTextfield(
                hintText: "Password",
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 10),

              //confirm password textfield
              MyTextfield(
                hintText: "Confirm Password",
                obscureText: true,
                controller: confirmPwController,
              ),
              const SizedBox(height: 10),
              //forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              //register button
              MyButton(text: "Register", onTap: registerUser),

              const SizedBox(height: 25),

              //already have an account login here
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account ?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "  Login Here",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
