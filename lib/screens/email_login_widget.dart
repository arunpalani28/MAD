import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:milk_delivery_assist/screens/main_wrapper.dart';
import 'package:provider/provider.dart';
import '../models/auth/user_session.dart';
import '../providers/app_state.dart';
import 'package:flutter/animation.dart';

class EmailLoginWidget extends StatefulWidget {
  const EmailLoginWidget({super.key});

  @override
  State<EmailLoginWidget> createState() => _EmailLoginWidgetState();
}

class _EmailLoginWidgetState extends State<EmailLoginWidget> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();  // Mobile controller
  bool _loading = false;
  bool isLoginMode = true;

  // Wave animation controller
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {});
      });
    _waveController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _nameController.dispose();  // Dispose of controllers to avoid memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
  

  Future<void> _loginOrSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // final url = isLoginMode
    //     ? 'http://localhost:8067/mad-be/api/auth/login'  // Login endpoint
    //     : 'http://localhost:8067/mad-be/api/auth/signup'; // Signup endpoint
final url = isLoginMode
        ? 'http://madbackend-env.eba-7mxiyptt.ap-south-1.elasticbeanstalk.com/mad-be/api/auth/login'  // Login endpoint
        : 'http://madbackend-env.eba-7mxiyptt.ap-south-1.elasticbeanstalk.com/mad-be/api/auth/signup'; // Signup endpoint

    try {
      // For Signup, we send name, email, mobile, and password
      final body = isLoginMode
          ? jsonEncode({
              'email': _emailController.text.trim(),
              'password': _passwordController.text.trim(),
            })
          : jsonEncode({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'mobile': _mobileController.text.trim(),
              'password': _passwordController.text.trim(),
            });

      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final session = UserSession(
          userId: data['userId'],
          name: data['name'],
          email: data['email'],
          role: data['role'],
          isKycComplete: data['isKycComplete'],
          mobile:data['mobile'],
          token:data['token']
        );

        await UserSession.saveUser(
          userId: session.userId,
          name: session.name,
          email: session.email,
          role: session.role,
          isKycComplete: session.isKycComplete,
          mobile:session.mobile,
          token:session.token,
        );

        if (!mounted) return;
        Provider.of<AppState>(context, listen: false).setUser(session);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainWrapper()),
        );
      } else {
        final error = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Request failed')),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong, please try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 62, 191, 15),
      body: Stack(
        children: [
      // Gradient background
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF81D4FA), // Light blue top
                Color(0xFF0288D1), // Darker blue bottom
              ],
            ),
          ),
        ),
      ),
          // Full screen blue wave animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(double.infinity, double.infinity),
                  painter: BlueWavePainter(_waveAnimation.value),
                );
              },
            ),
          ),
          // Main form content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 15,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLoginMode ? 'Login' : 'Signup',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Name input (only for Signup)
                        if (!isLoginMode)
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 16),
                        // Email input
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Mobile number input (only for Signup)
                        if (!isLoginMode)
                          TextFormField(
                            controller: _mobileController,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your mobile number';
                              }
                              // Mobile number validation (basic)
                              final RegExp mobileRegExp = RegExp(r'^[0-9]{10}$');
                              if (!mobileRegExp.hasMatch(value)) {
                                return 'Please enter a valid 10-digit mobile number';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 16),
                        // Password input
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _loading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _loginOrSignup,
                                child: Text(isLoginMode ? 'Sign In' : 'Sign Up'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 48),
                                  backgroundColor: Colors.blueAccent,
                                ),
                              ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isLoginMode = !isLoginMode;
                            });
                          },
                          child: Text(
                            isLoginMode
                                ? "Don't have an account? Sign Up"
                                : "Already have an account? Sign In",
                            style: const TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- BLUE WAVE PAINTER ----------------
class BlueWavePainter extends CustomPainter {
  final double animationValue;
  BlueWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFFFF8E7).withOpacity(0.8) // Milk-like color
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0xFFFFF8E7).withOpacity(0.6) // Slightly lighter milk layer
      ..style = PaintingStyle.fill;

    // Draw two layers of wave
    _drawWave(canvas, size, paint1, animationValue, 30.0, 20.0);
    _drawWave(canvas, size, paint2, animationValue, 50.0, 15.0);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, double anim,
      double offsetY, double amplitude) {
    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      double y = size.height * 0.5 +
          amplitude * sin(i / size.width * 2 * pi + anim * 2 * pi) +
          offsetY;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BlueWavePainter oldDelegate) => true;
}
