import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/components/my_button.dart';
import 'package:minimalsocialmedia/components/my_textfield.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  final FirebaseAuth auth;

  // Fixed constructor by using null check instead of default value
  LoginPage({Key? key, required this.onTap, FirebaseAuth? auth})
    : this.auth = auth ?? FirebaseAuth.instance,
      super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //text controller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  //login method - fixed structure
  void login() async {
    //show loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    //try sign in
    try {
      await widget.auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      //pop loading circle
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      //pop loading circle
      if (context.mounted) {
        Navigator.pop(context);
      }
      //display error message to user
      displayMessageToUser(e.code, context);
    }
  }

  void displayMessageToUser(String code, BuildContext context) {
    String message;
    switch (code) {
      case 'user-not-found':
        message = 'No user found for that email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided for that user.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'user-disabled':
        message = 'The user account has been disabled.';
        break;
      default:
        message = 'An unknown error occurred.';
    }
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Login Error'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
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

              const SizedBox(height: 25),
              //app name
              Column(
                children: [
                  Text(
                    "R A M B L E E",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "where nobody stays on topic",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 50),

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

              //sign in button
              MyButton(text: "Login", onTap: login),

              const SizedBox(height: 25),

              //don't have account register here
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account ?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "  Register Here",
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
