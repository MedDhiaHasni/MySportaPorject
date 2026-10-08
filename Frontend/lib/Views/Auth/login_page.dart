import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Utils/validators.dart';
import 'package:sporta/Views/Auth/forgot_password_page.dart';
import 'package:sporta/Views/Auth/sign_up_page.dart';
import 'package:sporta/Views/Manager/manager_navigation.dart';
import 'package:sporta/Views/Player/navigation.dart';
import 'package:sporta/Views/Worker/worker_navigation.dart';
import 'package:sporta/Widgets/Inputs/app_input_field.dart';
import 'package:sporta/Widgets/Shared/auth_header.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _remember = false;
  bool _obscure = true;
  bool _isLoading = false;

  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        print('=== LOGIN ATTEMPT ===');
        print('Email: ${_email.text.trim()}');
        print('Password: ${_password.text.trim()}');

        final response = await PlayerManagerAuthService.login(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );

        print('Response received: $response');

        if (response['token'] != null) {
          print('Token received: ${response['token']}');
          final userRole = response['user']['user_role'];
          print('User role: $userRole');
          
          final userId = response['user']['id'].toString();
          final token = response['token'];

          await _storage.write(key: 'jwt_token', value: token);
          await _storage.write(key: 'user_role', value: userRole);
          await _storage.write(key: 'user_id', value: userId);
          
          if (_remember) {
            await _storage.write(key: 'remember_email', value: _email.text.trim());
          } else {
            await _storage.delete(key: 'remember_email');
          }

          // Navigate based on user role
          if (userRole == 'manager') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ManagerNavigation(managerToken: token),
              ),
            );
          } else if (userRole == 'player') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Navigation(playerToken: token),
              ),
            );
          } else if (userRole == 'worker') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => WorkerNavigation(workerToken: token),
              ),
            );
          } else {
            setState(() => _isLoading = false);
            _showErrorDialog('Invalid user role');
          }
        } else {
          print('No token in response');
          setState(() => _isLoading = false);
          _showErrorDialog('No token received');
        }
      } catch (error) {
        print('ERROR: $error');
        setState(() => _isLoading = false);
        _showErrorDialog(error.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Login Failed',
          style: TextStyle(color: kRed, fontWeight: FontWeight.w800),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          const AuthHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Login to continue playing',
                    style: TextStyle(fontSize: 14, color: kTextMid),
                  ),
                  const SizedBox(height: 24),

                  const Text('Email Address', style: _label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: appInputDecoration(
                      'your@email.com',
                      Icons.email_outlined,
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),

                  const Text('Password', style: _label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration:
                        appInputDecoration(
                          '••••••••',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _remember,
                            onChanged: (v) =>
                                setState(() => _remember = v ?? false),
                            activeColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const Text(
                            'Remember me',
                            style: TextStyle(fontSize: 13, color: kTextMid),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 13,
                            color: kPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: TextStyle(
                            fontSize: 11,
                            color: kTextMid,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/google.png',
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(fontSize: 14, color: kTextMid),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 14,
                            color: kPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

const _label = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: kTextDark,
);

























/*import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Utils/validators.dart';
import 'package:sporta/Views/Auth/forgot_password_page.dart';
import 'package:sporta/Views/Auth/sign_up_page.dart';
import 'package:sporta/Views/Manager/manager_navigation.dart';
import 'package:sporta/Views/Player/navigation.dart';
import 'package:sporta/Widgets/Inputs/app_input_field.dart';
import 'package:sporta/Widgets/Shared/auth_header.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _remember = false;
  bool _obscure = true;
  bool _isLoading = false;

  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        print('=== LOGIN ATTEMPT ===');
        print('Email: ${_email.text.trim()}');
        print('Password: ${_password.text.trim()}');

        final response = await PlayerManagerAuthService.login(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );

        print('Response received: $response');

        if (response['token'] != null) {
          print('Token received: ${response['token']}');
          final userRole = response['user']['user_role'];
          print('User role: $userRole');
          
          final userId = response['user']['id'].toString();
          final token = response['token'];

          await _storage.write(key: 'jwt_token', value: token);
          await _storage.write(key: 'user_role', value: userRole);
          await _storage.write(key: 'user_id', value: userId);
          
          if (_remember) {
            await _storage.write(key: 'remember_email', value: _email.text.trim());
          } else {
            await _storage.delete(key: 'remember_email');
          }

          if (userRole == 'manager') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ManagerNavigation(managerToken: token),
              ),
            );
          } else if (userRole == 'player') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Navigation(playerToken: token),
              ),
            );
          } else {
            setState(() => _isLoading = false);
            _showErrorDialog('Invalid user role');
          }
        } else {
          print('No token in response');
          setState(() => _isLoading = false);
          _showErrorDialog('No token received');
        }
      } catch (error) {
        print('ERROR: $error');
        setState(() => _isLoading = false);
        _showErrorDialog(error.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Login Failed',
          style: TextStyle(color: kRed, fontWeight: FontWeight.w800),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          const AuthHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Login to continue playing',
                    style: TextStyle(fontSize: 14, color: kTextMid),
                  ),
                  const SizedBox(height: 24),

                  const Text('Email Address', style: _label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: appInputDecoration(
                      'your@email.com',
                      Icons.email_outlined,
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),

                  const Text('Password', style: _label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration:
                        appInputDecoration(
                          '••••••••',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _remember,
                            onChanged: (v) =>
                                setState(() => _remember = v ?? false),
                            activeColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const Text(
                            'Remember me',
                            style: TextStyle(fontSize: 13, color: kTextMid),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 13,
                            color: kPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: TextStyle(
                            fontSize: 11,
                            color: kTextMid,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/google.png',
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(fontSize: 14, color: kTextMid),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 14,
                            color: kPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

const _label = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: kTextDark,
);*/