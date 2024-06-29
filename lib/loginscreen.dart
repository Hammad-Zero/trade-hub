import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradehub/admin.dart';
import 'package:tradehub/adminlogin.dart';
import 'package:tradehub/choosemodule.dart';
import 'package:tradehub/detaileditemsexchangescreen.dart';
import 'package:tradehub/signupscreen.dart';
import 'package:tradehub/spalshscreen.dart';
import 'package:tradehub/uploaditem.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _passwordValidationError = "";
  String _emailValidationError = "";
  bool _passwordVisible = false; // Added variable for password visibility

  Future<bool> _loginWithEmailAndPassword(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Input Error'),
            content: const Text('Please enter both email and password.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return false;
    }

    try {
      // Check if user is in Firestore 'users' collection
      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        // User not found in Firestore
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Authentication Error'),
              content: const Text('User not found in the system. Please contact admin.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return false;
      }

      // Proceed to sign in with email and password
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (error) {
      if (error is FirebaseAuthException) {
        if (error.code == 'user-not-found') {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Authentication Error'),
                content: const Text('User not found. Please sign up.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else if (error.code == 'wrong-password') {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Authentication Error'),
                content: const Text('Incorrect password. Please try again.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          print("Authentication error: $error");
        }
      }
      return false;
    }
  }

  void _validatePassword(String password) {
    if (password.length < 6) {
      setState(() {
        _passwordValidationError = "Password must be at least 6 characters";
      });
    } else if (!password.contains(RegExp(r'[A-Z]'))) {
      setState(() {
        _passwordValidationError = "Password must contain at least one capital letter";
      });
    } else if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() {
        _passwordValidationError = "Password must contain at least one number";
      });
    } else {
      setState(() {
        _passwordValidationError = "";
      });
    }
  }

  void _validateEmail(String email) {
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _emailValidationError = "Enter a valid email address";
      });
    } else {
      setState(() {
        _emailValidationError = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  'Trade Hub',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff672CBC),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(left: 140, right: 140),
                child: Image(image: AssetImage('assets/images/logo.png')),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.only(right: 30, left: 30),
                child: TextFormField(
                  controller: _emailController,
                  onChanged: (value) {
                    _validateEmail(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(
                      color: Color(0xff672CBC),
                    ),
                    fillColor: Colors.transparent,
                    filled: true,
                    prefixIcon: const Icon(
                      Icons.email_rounded,
                      shadows: [BoxShadow(blurRadius: 0.1)],
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(width: 1, color: Color(0xff672CBC)),
                      borderRadius: BorderRadius.circular(70),
                    ),
                    errorText: _emailValidationError.isNotEmpty ? _emailValidationError : null,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(right: 30, left: 30),
                child: TextFormField(
                  controller: _passwordController,
                  onChanged: (value) {
                    _validatePassword(value);
                  },
                  obscureText: !_passwordVisible, // Toggle password visibility
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock,
                      shadows: [BoxShadow(blurRadius: 1)],
                    ),
                    hintText: 'Password',
                    hintStyle: const TextStyle(
                      color: Color(0xff672CBC),
                    ),
                    fillColor: Colors.transparent,
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(width: 1, color: Color(0xff672CBC)),
                      borderRadius: BorderRadius.circular(70),
                    ),
                    errorText: _passwordValidationError.isNotEmpty ? _passwordValidationError : null,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff672CBC),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                onPressed: () async {
                  String email = _emailController.text;
                  String password = _passwordController.text;

                  // Perform the login process
                  bool loginSuccessful = await _loginWithEmailAndPassword(email, password);

                  // Check if login was successful
                  if (loginSuccessful) {
                    // Navigate to the UserProfileScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ItemListScreen()),
                    );
                  } else {
                    // Handle login failure (e.g., show a message)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed. Please try again.')),
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 30, left: 30),
                  child: Text('Login'),
                ),
              ),
              const SizedBox(height: 30),
              const Text('OR'),
              const SizedBox(height: 50),
              const Padding(
                padding: EdgeInsets.only(right: 10, left: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Image(
                      width: 30,
                      height: 30,
                      image: AssetImage('assets/images/fb.png'),
                    ),
                    Image(
                      width: 30,
                      height: 30,
                      image: AssetImage('assets/images/google.png'),
                    ),
                    Image(
                      width: 30,
                      height: 30,
                      image: AssetImage('assets/images/apple.png'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUPScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign Up here!',
                      style: TextStyle(
                        color: Color(0xff672CBC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminLogin(),
                        ),
                      );
                    },
                    child: const Text(
                      'Login as Admin',
                      style: TextStyle(
                        color: Color(0xff672CBC),
                        fontWeight: FontWeight.bold,
                      ),
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
