import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin) {
        await _login(
          email: email,
          password: password,
        );
      } else {
        final name = _nameController.text.trim();

        await _register(
          name: name,
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getAuthErrorMessage(e)),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'A Firebase error occurred.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login successful!'),
        duration: Duration(milliseconds: 700),
      ),
    );

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  Future<void> _register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'User account could not be created.',
      );
    }

    await user.updateDisplayName(name);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'photoUrl': '',
      'coverPhotoUrl': '',
      'bio': '',
      'phone': '',
      'location': '',
      'website': '',
      'friendCount': 0,
      'followingCount': 0,
      'followerCount': 0,
      'postCount': 0,
      'isAdmin': false,
      'isBlocked': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account created successfully!',
        ),
        duration: Duration(milliseconds: 700),
      ),
    );

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  String _getAuthErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
        return 'Incorrect password.';

      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'weak-password':
        return 'Password must be at least 6 characters.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email/password login is not enabled in Firebase.';

      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  String? _validateName(String? value) {
    if (_isLogin) {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name.';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email.';
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  void _switchMode() {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLogin = !_isLogin;
      _obscurePassword = true;
    });

    _formKey.currentState?.reset();

    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _isLogin;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius:
                            BorderRadius.circular(26),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Friend Post',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isLogin
                        ? 'Welcome back! Login to continue.'
                        : 'Create your Friend Post account.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  if (!isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      textInputAction:
                          TextInputAction.next,
                      textCapitalization:
                          TextCapitalization.words,
                      validator: _validateName,
                      decoration: InputDecoration(
                        labelText: 'Full name',
                        hintText: 'Enter your name',
                        prefixIcon: const Icon(
                          Icons.person_outline,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    textInputAction:
                        TextInputAction.next,
                    validator: _validateEmail,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction:
                        TextInputAction.done,
                    validator: _validatePassword,
                    onFieldSubmitted: (_) {
                      if (!_isLoading) {
                        _submit();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'At least 6 characters',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isLogin
                                  ? 'Login'
                                  : 'Create Account',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextButton(
                    onPressed:
                        _isLoading ? null : _switchMode,
                    child: Text(
                      isLogin
                          ? "Don't have an account? Create one"
                          : 'Already have an account? Login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
