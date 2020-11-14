import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errandsguy_app/Screens/home.dart';
import 'package:errandsguy_app/services/auth.dart';
import 'package:errandsguy_app/services/helper_functions.dart';
import 'package:errandsguy_app/widgets/authenticate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
    final Future<FirebaseApp> _initialization = Firebase.initializeApp(
       name: 'db2',
    options: Platform.isIOS || Platform.isMacOS
        ? FirebaseOptions(
      appId: '1:446662006558:ios:80eb0b1b4166d6e0c41b0f',
      apiKey: 'AIzaSyAqwMiDIIikoKHIdDtG0v7sU5mGRWV2yek',
      projectId: 'errandsguyapp',
      messagingSenderId: '446662006558',
      databaseURL: 'https://errandsguyapp.firebaseio.com',
    )
        : FirebaseOptions(
      appId: '1:446662006558:android:ad9558ff23fea2b7c41b0f',
      apiKey: 'AIzaSyBNa9EOjwryfthR7QfmlhJV-K24jyJZgQc',
      messagingSenderId: '446662006558',
      projectId: 'errandsguyapp',
      databaseURL: 'https://errandsguyapp.firebaseio.com',
    ),
    );


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color(0xFF08D294),
        accentColor: Color(0xFF08D294),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      title: 'ErrandsGuy',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        // Initialize FlutterFire:
        future: _initialization,
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text("Something went wrong!"),
              ),
            );
          }

          // Once complete, show your application
          if (snapshot.connectionState == ConnectionState.done) {
            return Root();
          }

          // Otherwise, show something whilst waiting for initialization to complete
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}

class Root extends StatefulWidget {
  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root> {
  bool userIsLoggedIn;

  @override
  void initState() {
    getLoggedInState();
    super.initState();
  }

  getLoggedInState() async {
    await HelperFunctions.getUserLoggedInSharedPreference().then((value) {
      setState(() {
        userIsLoggedIn = value;
      });
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().user,
      builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data?.uid == null) {
            return Authenticate();
          } else {
            return Home(
              auth: _auth,
              firestore: _firestore,
            );
          }
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      }, //Auth stream
    );
  }
}