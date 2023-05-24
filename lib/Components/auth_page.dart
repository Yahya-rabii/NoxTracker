import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nox_tracker/Pages/login.dart';
import 'package:nox_tracker/Pages/home.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //when user is logged in
          if(snapshot.hasData) {
            return HomePage();
          }
          else{
            return LoginPage();
          }
        },
      ),
    );
  }
}
