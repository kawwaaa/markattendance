import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Navigate to QR Scanner screen on successful login
      Navigator.pushReplacementNamed(context, '/qrScanner');
    } catch (e) {
      // Handle login error
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/background_imagee.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Manually positioned 'Mark Me' text
          Positioned(
            top: 70,  // Adjust this value to change vertical position
            left: 30, // Adjust this value to change horizontal position
            right: 30, // Adjust this value to set horizontal constraints
            child: Text(
              'Mark Me',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.grey,
                    offset: Offset(5.0, 5.0),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Positioned Column for other elements
          Positioned(
            top: 150, // Adjust this value for the vertical positioning of the column
            left: 30,
            right: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage: AssetImage('assets/user_profile.jpeg'),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.black,  // Border color
                        width: 2.0,           // Border width (thickness)
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.black,  // Border color when not focused
                        width: 2.0,           // Border width (thickness)
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.blue,   // Border color when focused
                        width: 2.0,           // Border width (thickness) when focused
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.black,  // Border color
                        width: 2.0,           // Border width (thickness)
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.black,  // Border color when not focused
                        width: 2.0,           // Border width (thickness)
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.blue,   // Border color when focused
                        width: 2.0,           // Border width (thickness) when focused
                      ),
                    ),
                  ),
                  obscureText: true,
                ),

                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    '         Continue         ',
                    style: TextStyle(fontSize: 18,color: Colors.white,),

                  ),
                ),
              ],
            ),
          ),
          // Manually positioned 'Forgot your password?' button
          Positioned(
            top: 500,  // Adjust this value to change vertical position
            left: 30,
            right: 30,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot_password');
              },
              child: Text(
                'Forgot your password?',
                style: TextStyle(
                  color: Colors.black,
                  //decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          // Manually positioned 'Create an Account' button
          Positioned(
            top: 520,  // Adjust this value to change vertical position
            left: 30,
            right: 30,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text(
                'Create an Account',
                style: TextStyle(
                  color: Colors.black,
                  //decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
