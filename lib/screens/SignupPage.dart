import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errandsguy_app/Screens/home.dart';
import 'package:errandsguy_app/Screens/verify_mobile_number.dart';
import 'package:errandsguy_app/blocs/auth_bloc.dart';
import 'package:errandsguy_app/services/auth.dart';
import 'package:errandsguy_app/services/helper_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_truecaller/flutter_truecaller.dart';
import 'package:provider/provider.dart';

class SignUpPage extends StatefulWidget {
  final Function toggleView;
  SignUpPage(this.toggleView);
  static final String routeName = '/SignUpPageRoute';

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  FirebaseAuth auth;
  FirebaseFirestore firestore;
  StreamSubscription<User> loginStateSubscription;
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  TextEditingController fnameController = TextEditingController();
  TextEditingController lnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String fname;
  String password;
  String email;
  String city;
  String address;
  String lname;
  String phone;
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

  Future<void> _signUp() async {
    if (formKey.currentState.validate()) {
      setState(() {
        isLoading = true;
      });
      formKey.currentState.save();
      try {
        await auth
            .createUserWithEmailAndPassword(
                email: emailController.text, password: passwordController.text)
            .then((result) {
          if (result != null) {
            firestore.collection('users').doc(result.user.uid).set({
              "uid": result.user.uid,
              "firstname": fnameController.text,
              "email": result.user.email,
              "lastname": lnameController.text,
              "phone": phoneController.text,
              "address": addressController.text,
              "city": cityController.text,
            }).then((value) {
              HelperFunctions.saveUserLoggedInSharedPreference(true);
              HelperFunctions.saveUserNameSharedPreference(
                  fnameController.text);
              HelperFunctions.saveUserEmailSharedPreference(
                  emailController.text);

              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => Home()));
            }).catchError((e) {
              print(e);
            });
          }
        }).catchError((e) {
          print(e);
        });
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          print('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          print('The account already exists for that email.');
        }
      } catch (e) {
        print(e);
      }
    }
    // Navigator.pushNamed(context, SignUpPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    var authbloc = Provider.of<AuthBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(50, 20, 50, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          'Use Your Account on',
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
                              child: MaterialButton(
                                onPressed: () {
                                  AuthService()
                                      .signInWithGoogle()
                                      .whenComplete(() {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => Home()));
                                  });
                                },
                                child: Container(
                                  child: CircleAvatar(
                                    backgroundImage: new NetworkImage(
                                        "https://icon-library.com/images/gmail-circle-icon/gmail-circle-icon-7.jpg"),
                                    backgroundColor: Colors.white,
                                    radius: 20.0,
                                  ),
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
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Enter Your Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Form(
                        key: formKey,
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: TextFormField(
                                controller: fnameController,
                                onSaved: (value) => value = fname,
                                validator: (value) {
                                  if (value.length == null) {
                                    return 'fname cannot be null';
                                  }
                                  return null;
                                },
                                decoration:
                                    InputDecoration(labelText: 'First name'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: TextFormField(
                                controller: lnameController,
                                onSaved: (value) => value = lname,
                                validator: (value) {
                                  if (value.length == null) {
                                    return 'name cannot be empty';
                                  }
                                  return null;
                                },
                                decoration:
                                    InputDecoration(labelText: 'Last Name'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: TextFormField(
                                controller: emailController,
                                onSaved: (value) => value = email,
                                validator: (value) {
                                  return RegExp(
                                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                          .hasMatch(value)
                                      ? null
                                      : "Enter correct email";
                                },
                                decoration: InputDecoration(labelText: 'Email'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: TextFormField(
                                controller: phoneController,
                                onSaved: (value) => value = phone,
                                validator: (value) {
                                  if (value.isEmpty || value.length < 10) {
                                    return 'Phone number cannot be empty';
                                  }
                                  return null;
                                },
                                decoration:
                                    InputDecoration(labelText: 'Phone Number'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: TextFormField(
                                controller: addressController,
                                onSaved: (value) => value = address,
                                validator: (value) {
                                  if (value.length == null) {
                                    return 'Address cannot be null';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                    labelText:
                                        'Address(Street/Estate/Landmark)'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: TextFormField(
                                controller: cityController,
                                onSaved: (value) => value = city,
                                validator: (value) {
                                  if (value.length == null) {
                                    return 'value cannot be null';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                    labelText: 'City of Residence'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: TextFormField(
                                controller: passwordController,
                                obscureText: true,
                                onSaved: (value) => value = password,
                                validator: (value) {
                                  if (value.length < 6) {
                                    return 'Password must be more than six characters';
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
                        padding: const EdgeInsets.only(top: 20.0, bottom: 30.0),
                        child: MaterialButton(
                          onPressed: () => {
                            _signUp(),
                          },
                          child: Text(
                            'Submit',
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
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
