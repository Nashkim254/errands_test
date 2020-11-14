import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errandsguy_app/Screens/SignUpPage.dart';
import 'package:errandsguy_app/Screens/home.dart';
import 'package:errandsguy_app/Screens/verify_mobile_number.dart';
import 'package:errandsguy_app/blocs/auth_bloc.dart';
import 'package:errandsguy_app/services/auth.dart';
import 'package:errandsguy_app/services/helper_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_truecaller/flutter_truecaller.dart';
import 'package:provider/provider.dart';

import '../Models/AppConstants.dart';

class LoginPage extends StatefulWidget {
  static final String routeName = '/loginPageRoute';
  final Function toggleView;

  LoginPage(this.toggleView);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  StreamSubscription<User> loginStateSubscription;
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String email;
  String password;
  final FlutterTruecaller truecaller = FlutterTruecaller();
  @override
  void initState() {
    var authBloc = Provider.of<AuthBloc>(context, listen: false);
    loginStateSubscription = authBloc.currentUser.listen((fbUser) {
      if (fbUser != null) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) => Home()));
      }
    });
    super.initState();
    getTrueCaller();
  }

  @override
  void dispose() {
    loginStateSubscription.cancel();
    super.dispose();
  }

  Future getTrueCaller() async {
    await truecaller.initializeSDK(
      sdkOptions: FlutterTruecallerScope.SDK_OPTION_WITH_OTP,
      footerType: FlutterTruecallerScope.FOOTER_TYPE_ANOTHER_METHOD,
      consentMode: FlutterTruecallerScope.CONSENT_MODE_POPUP,
    );
  }

  void _login() {
    if (formKey.currentState.validate()) {
      setState(() {
        isLoading = true;
      });
      formKey.currentState.save();
      AuthService()
          .signIn(emailController.text, passwordController.text)
          .then((result) async {
        if (result != null) {
          QuerySnapshot userInfoSnapshot =
              await AuthService().getUserInfo(emailController.text);

          HelperFunctions.saveUserLoggedInSharedPreference(true);
          HelperFunctions.saveUserNameSharedPreference(
              userInfoSnapshot.docs[0].data()["userName"]);
          HelperFunctions.saveUserEmailSharedPreference(
              userInfoSnapshot.docs[0].data()["userEmail"]);

          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Home()));
        } else {
          setState(() {
            isLoading = false;
            //show snackbar
          });
        }
      });
    }
    // Navigator.pushNamed(context, ProductHomePage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    var authbloc = Provider.of<AuthBloc>(context);
    return Scaffold(
      body: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(50, 100, 50, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Welcome to ${AppConstants.appName}!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Form(
                      key: formKey,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 25.0),
                            child: TextFormField(
                              controller: emailController,
                              onSaved: (value) {
                                value = email;
                              },
                              validator: (value) {
                                return RegExp(
                                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                        .hasMatch(value)
                                    ? null
                                    : "Enter correct email";
                              },
                              decoration: InputDecoration(labelText: 'email'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 25.0),
                            child: TextFormField(
                              controller: passwordController,
                              onSaved: (value) {
                                value = password;
                              },
                              validator: (value) {
                                if (value.length < 6) {
                                  return 'Password cannot be less than six characters';
                                }
                                return null;
                              },
                              decoration:
                                  InputDecoration(labelText: 'Password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30.0),
                      child: MaterialButton(
                        onPressed: () => {
                          _login(),
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        color: Color(0xFF08D294),
                        height: MediaQuery.of(context).size.height / 15,
                        minWidth: double.infinity,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Text(
                        'Login with',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Row(
                        //Social Media accounts- Facebook, gmail, truecaller here
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(13.0),
                            child: Container(
                              child: CircleAvatar(
                                backgroundImage: new NetworkImage(
                                    "https://icon-library.com/images/gmail-circle-icon/gmail-circle-icon-7.jpg"),
                                backgroundColor: Colors.white,
                                radius: 20.0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(11.0),
                            child: MaterialButton(
                              onPressed: () {
                                authbloc.loginFacebook();
                              },
                              child: Container(
                                child: CircleAvatar(
                                  backgroundImage: new NetworkImage(
                                      "https://assets.stickpng.com/thumbs/58e91965eb97430e819064f5.png"),
                                  backgroundColor: Colors.white,
                                  radius: 20.0,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(9.0),
                            child: MaterialButton(
                              onPressed: () async {
                                await truecaller.getProfile();
                                FlutterTruecaller.manualVerificationRequired
                                    .listen((isRequired) {
                                  if (isRequired) {
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                VerifyMobileNumber()));
                                  } else {
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (context) => Home()));
                                  }
                                });
                              },
                              child: Container(
                                child: CircleAvatar(
                                  backgroundImage: new NetworkImage(
                                      "https://image.winudf.com/v2/image/ZnJlZS5uZXdhcHBzLm5ld3RydWVjYWxsZXJpZGJsb2NrZnJlZV9pY29uXzE1MDk5MTc4MDdfMDk3/icon.png?w=170&fakeurl=1"),
                                  backgroundColor: Colors.white,
                                  radius: 18.0,
                                ),
                              ),
                            ),
                          ),
                        ]),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: MaterialButton(
                        onPressed: () {
                          widget.toggleView();
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        color: Colors.grey,
                        height: MediaQuery.of(context).size.height / 15,
                        minWidth: double.infinity,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
