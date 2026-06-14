import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/premium_button.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSnackBar(state.message, isError: true);
          } else if (state is AuthEmailConfirmationRequired) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Check Your Email'),
                content: Text(
                  'A confirmation link has been sent to ${state.email}. '
                  'Please check your email and click the link to verify '
                  'your account before signing in.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<AuthCubit>().resendConfirmation(state.email);
                      context.showSnackBar('Confirmation email resent!');
                    },
                    child: const Text('Resend Email'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: context.isDarkMode
                  ? [
                      const Color(0xFF0D0D0D),
                      const Color(0xFF16213E),
                      const Color(0xFF0F3460),
                    ]
                  : [
                      const Color(0xFFF8F9FD),
                      const Color(0xFFEEF0FB),
                      const Color(0xFFE8EAFC),
                    ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo / Brand
                        Container(
                          width: 112,
                          height: 112,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.isDarkMode
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'ios/logo.jpeg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Mukundhan Textiles',
                          textAlign: TextAlign.center,
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Welcome Back",
                          style: context.textTheme.displaySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign in to continue shopping",
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.isDarkMode
                                ? Colors.white60
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: context.isDarkMode
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                            ),
                            boxShadow: context.isDarkMode
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hint: 'Enter your email',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  obscureText: _obscurePassword,
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: Validators.password,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        context.push('/forgot-password'),
                                    child: const Text('Forgot Password?'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                BlocBuilder<AuthCubit, AuthState>(
                                  builder: (context, state) {
                                    return PremiumButton(
                                      onPressed: state is AuthLoading ? null : _login,
                                      backgroundColor: context.isDarkMode ? Colors.white : Colors.black,
                                      child: state is AuthLoading
                                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: context.isDarkMode ? Colors.black : Colors.white))
                                          : Text('SIGN IN', style: TextStyle(color: context.isDarkMode ? Colors.black : Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade400)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: context.textTheme.bodySmall,
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade400)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Google Sign In
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.read<AuthCubit>().signInWithGoogle(),
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text('Continue with Google'),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: context.textTheme.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: () => context.push('/signup'),
                              child: Text(
                                'Sign Up',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
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
            ),
          ),
        ),
      ),
    );
  }
}
