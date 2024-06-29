import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tradehub/loginscreen.dart';

class SignUPScreen extends StatefulWidget {
  const SignUPScreen({super.key});

  @override
  State<SignUPScreen> createState() => _SignUPScreenState();
}

class _SignUPScreenState extends State<SignUPScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore=FirebaseFirestore.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  User? user=FirebaseAuth.instance.currentUser;

  String _passwordValidationError = "";
  String _emailValidationError = "";
  bool _passwordVisible = false; // Added variable for password visibility

  Future<void> _signUpWithEmailAndPassword(
      String username, String email, String password) async {
    // ... (error handling for empty fields)

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User user = userCredential.user!; // Guaranteed to be non-null

      _firebaseFirestore.collection("users").doc(user.uid).set({
        "username": username,
        "email": email,
        'id': user.uid,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } catch (error) {
      // ... (error handling for signup failures)
    }
  }

  void _validatePassword(String password) {
    // ... (rest of your password validation logic)
  }

  void _validateEmail(String email) {
    // ... (rest of your email validation logic)
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
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff672CBC),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(top: 1, left: 140, right: 140),
                child: Image(image: AssetImage('assets/images/logo.png')),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.only(top: 15, right: 30, left: 30),
                child: TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person_2_rounded,
                      shadows: [BoxShadow(blurRadius: 2)],
                    ),
                    hintText: 'Username',
                    hintStyle: const TextStyle(
                      color: Color(0xff672CBC),
                    ),
                    fillColor: Colors.transparent,
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                      const BorderSide(width: 1, color: Color(0xff672CBC)),
                      borderRadius: BorderRadius.circular(70),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 30, left: 30),
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
                    prefixIcon: const Icon(Icons.email_rounded, shadows: [
                      BoxShadow(
                        blurRadius: 2,
                      )
                    ]),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                      const BorderSide(width: 1, color: Color(0xff672CBC)),
                      borderRadius: BorderRadius.circular(70),
                    ),
                    errorText: _emailValidationError.isNotEmpty
                        ? _emailValidationError
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(top: 15, right: 30, left: 30),
                child: TextFormField(
                  controller: _passwordController,
                  onChanged: (value) {
                    _validatePassword(value);
                  },
                  obscureText: !_passwordVisible, // Toggle password visibility
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, shadows: [
                      BoxShadow(
                        blurRadius: 2,
                      )
                    ]),
                    hintText: 'Password',
                    hintStyle: const TextStyle(
                      color: Color(0xff672CBC),
                    ),
                    fillColor: Colors.transparent,
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                      const BorderSide(width: 1, color: Color(0xff672CBC)),
                      borderRadius: BorderRadius.circular(70),
                    ),
                    errorText: _passwordValidationError.isNotEmpty
                        ? _passwordValidationError
                        : null,
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
                onPressed: () {
                  String username = _usernameController.text;
                  String email = _emailController.text;
                  String password = _passwordController.text;
                  _signUpWithEmailAndPassword(username, email, password);
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 30, left: 30),
                  child: Text('SignUp'),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Login here !',
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
