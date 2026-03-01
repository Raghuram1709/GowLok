import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_validator.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../core/widgets/global_nav_controller.dart';
import 'login_screen.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/password_strength_indicator.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PasswordStrength _passwordStrength = PasswordStrength.empty;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 40),
                    // App logo/title
                    Text(
                      'GOWLOK',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create your account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 40),
                    // Signup form
                    Form(
                      key: _formKey,
                      child: Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return Column(
                            children: [
                              // Full Name field
                              AuthTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                hint: 'John Doe',
                                keyboardType: TextInputType.name,
                                prefixIcon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                                enabled: !authProvider.isLoading,
                              ),
                              const SizedBox(height: 20),
                              // Email field
                              AuthTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'your@email.com',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: AuthValidator.validateEmail,
                                enabled: !authProvider.isLoading,
                              ),
                              const SizedBox(height: 20),
                              // Password field
                              AuthTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Create a strong password',
                                prefixIcon: Icons.lock_outlined,
                                obscureText: _obscurePassword,
                                suffixIcon: _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onSuffixIconPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _passwordStrength =
                                        AuthValidator.checkPasswordStrength(
                                            value);
                                  });
                                },
                                validator: AuthValidator.validatePassword,
                                enabled: !authProvider.isLoading,
                              ),
                              const SizedBox(height: 12),
                              // Password strength indicator
                              if (_passwordController.text.isNotEmpty)
                                PasswordStrengthIndicator(
                                  strength: _passwordStrength,
                                ),
                              const SizedBox(height: 20),
                              // Confirm password field
                              AuthTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                hint: 'Re-enter your password',
                                prefixIcon: Icons.lock_outlined,
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onSuffixIconPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                validator: (value) =>
                                    AuthValidator.validatePasswordConfirmation(
                                  value,
                                  _passwordController.text,
                                ),
                                enabled: !authProvider.isLoading,
                              ),
                              const SizedBox(height: 28),
                              // Error message
                              if (authProvider.errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          authProvider.errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                              // Sign up button
                              AuthButton(
                                label: 'Sign Up',
                                isLoading: authProvider.isLoading,
                                onPressed: () => _handleSignup(context),
                              ),
                              const SizedBox(height: 16),
                              // Google Sign up button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: authProvider.isLoading
                                      ? null
                                        : () async {
                                          GlobalNavController.selectedIndex.value = 0;
                                          final success = await authProvider.signInWithGoogle();
                                          if (success && context.mounted) {
                                            // Navigation handled by AuthGate
                                          }
                                        },
                                  icon: Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                    height: 24,
                                  ),
                                  label: const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    side: const BorderSide(color: Colors.black26),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Just pop to return to LoginScreen since SignupScreen was pushed
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await authProvider.signUpWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text,
    );

    if (!mounted) return;

    if (success) {
      if (authProvider.isAuthenticated) {
        GlobalNavController.selectedIndex.value = 0;
        // Navigation handled by AuthGate, pop current screen
        navigator.pop();
      } else {
        // Need email verification
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Sign up successful! Please verify your email, then sign in.'),
            backgroundColor: Colors.green[600],
          ),
        );

        // Pop back to the login screen
        navigator.pop();
      }
    }
  }
}
