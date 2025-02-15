import 'package:dukaan/auth/signup_page.dart';
import 'package:dukaan/consumer/consumer_home_page.dart';
import 'package:dukaan/profile_page.dart';
import 'package:dukaan/vendor/vendor_home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNavigation(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!mounted) return;

      if (doc.exists) {
        final userData = doc.data();
        final isProfileComplete = userData?['isProfileComplete'] ?? false;
        final userType = userData?['role'] as String?;

        if (isProfileComplete && userType != null) {
          if (userType.toLowerCase() == 'consumer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ConsumerHomePage()),
            );
          } else if (userType.toLowerCase() == 'vendor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const VendorHomePage(),
              ),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Error loading user data. Please try again.');
    }
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (userCredential.user != null) {
          await _handleNavigation(userCredential.user!.uid);
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = 'No user found for that email.';
            break;
          case 'wrong-password':
            message = 'Invalid password. Please try again.';
            break;
          case 'user-disabled':
            message = 'This account has been disabled.';
            break;
          case 'invalid-email':
            message = 'Please enter a valid email address.';
            break;
          default:
            message = 'An error occurred: ${e.message}';
        }
        if (!mounted) return;
        await _showErrorDialog(message);
      } catch (e) {
        if (!mounted) return;
        await _showErrorDialog('An error occurred. Please try again.');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // Sign out from Google first to clear any cached credentials
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // Force show account selection dialog
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        if (!mounted) return;

        if (userCredential.user != null) {
          // Check if user exists in Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (!userDoc.exists) {
            // New user - create document and redirect to profile page
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'email': userCredential.user!.email,
              'isProfileComplete': false,
              'createdAt': FieldValue.serverTimestamp(),
            });

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          } else {
            // Existing user - handle navigation based on profile status
            await _handleNavigation(userCredential.user!.uid);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog(
          'Failed to sign in with Google. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color.fromARGB(255, 255, 153, 0),
                  Color.fromARGB(255, 255, 178, 63),
                  Color.fromARGB(255, 250, 216, 165),
                ],
              ),
            ),
          ),
          // Container(
          //   color: Colors.black.withOpacity(0.5),
          // ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 200),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8F4A3B),
                          fontSize: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      controller: _passwordController,
                      labelText: 'Password',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildButton(
                      text: 'Login',
                      onPressed: _isLoading ? null : _signIn,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(
                            color: Color.fromARGB(255, 249, 228, 196),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Color.fromARGB(255, 249, 228, 196),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Color.fromARGB(255, 249, 228, 196),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildButton(
                      text: 'Continue with Google',
                      onPressed: _isLoading ? null : _signInWithGoogle,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpPage(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Don\'t have an account? Sign up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 153, 0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: Color(0xFF8F4A3B),
        ),
        filled: true,
        fillColor: Color.fromARGB(255, 249, 228, 196),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 249, 228, 196),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 249, 228, 196),
            width: 2,
          ),
        ),
      ),
      validator: validator,
      enabled: !_isLoading,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscureText,
      style: const TextStyle(
        color: Color(0xFF8F4A3B),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: Color(0xFF8F4A3B),
        ),
        filled: true,
        fillColor: Color.fromARGB(255, 249, 228, 196),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 249, 228, 196),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 249, 228, 196),
            width: 2,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF615482),
          ),
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
        ),
      ),
      validator: validator,
      enabled: !_isLoading,
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade400,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: 55.0,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: const Color(0xFF0E0E29),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
