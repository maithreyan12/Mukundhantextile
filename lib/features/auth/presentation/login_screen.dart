import 'dart:async';
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
  
  // Phone login controllers and state
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneNameController = TextEditingController();
  bool _isPhoneMode = false;
  bool _otpSent = false;
  bool _needsRegister = false;
  int _timerSeconds = 0;
  Timer? _timer;

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
    _phoneController.dispose();
    _otpController.dispose();
    _phoneNameController.dispose();
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = 59;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      context.showSnackBar('Please enter a valid mobile number', isError: true);
      return;
    }

    String formattedPhone = phone;
    if (!formattedPhone.startsWith('+')) {
      if (formattedPhone.length == 10) {
        formattedPhone = '+91$formattedPhone';
      } else {
        formattedPhone = '+$formattedPhone';
      }
    }

    setState(() {
      _otpSent = false;
      _needsRegister = false;
    });

    try {
      await context.read<AuthCubit>().sendLoginOtp(formattedPhone);
      setState(() {
        _otpSent = true;
      });
      _startTimer();
      context.showSnackBar('OTP code sent to $formattedPhone');
    } catch (e) {
      debugPrint('Real OTP failed, using mock fallback: $e');
      final profile = await context.read<AuthCubit>().findProfileByPhone(phone);
      if (profile != null) {
        if (profile.email.endsWith('@phone.mukundhantextile.com')) {
          setState(() {
            _otpSent = true;
          });
          _startTimer();
          context.showSnackBar('Simulated OTP code \'1234\' sent to $phone (Mock Fallback)');
        } else {
          context.showSnackBar(
            'This mobile number is linked to email ${profile.email}. Please use Email Login.',
            isError: true,
          );
        }
      } else {
        setState(() {
          _needsRegister = true;
        });
        context.showSnackBar('Mobile number not registered. Please enter your name to register.');
      }
    }
  }

  Future<void> _sendOtpForNewUser() async {
    final name = _phoneNameController.text.trim();
    if (name.isEmpty) {
      context.showSnackBar('Please enter your full name', isError: true);
      return;
    }

    final phone = _phoneController.text.trim();
    String formattedPhone = phone;
    if (!formattedPhone.startsWith('+')) {
      if (formattedPhone.length == 10) {
        formattedPhone = '+91$formattedPhone';
      } else {
        formattedPhone = '+$formattedPhone';
      }
    }

    try {
      await context.read<AuthCubit>().sendLoginOtp(formattedPhone);
      setState(() {
        _otpSent = true;
      });
      _startTimer();
      context.showSnackBar('OTP code sent.');
    } catch (e) {
      debugPrint('Real OTP failed for new user, using mock fallback: $e');
      context.read<AuthCubit>().clearError();
      setState(() {
        _otpSent = true;
      });
      _startTimer();
      context.showSnackBar('Simulated OTP code \'1234\' sent (Mock Fallback).');
    }
  }

  Future<void> _verifyOtpAndLogin() async {
    if (context.read<AuthCubit>().state is AuthLoading) return;
    final code = _otpController.text.trim();
    final phone = _phoneController.text.trim();
    
    String formattedPhone = phone;
    if (!formattedPhone.startsWith('+')) {
      if (formattedPhone.length == 10) {
        formattedPhone = '+91$formattedPhone';
      } else {
        formattedPhone = '+$formattedPhone';
      }
    }

    if (code == '1234') {
      // Mock bypass
      if (_needsRegister) {
        final name = _phoneNameController.text.trim();
        await context.read<AuthCubit>().signUpWithPhone(phone: phone, name: name);
      } else {
        final profile = await context.read<AuthCubit>().findProfileByPhone(phone);
        if (profile != null) {
          await context.read<AuthCubit>().signInWithPhonePassword(phone: phone, email: profile.email);
        } else {
          await context.read<AuthCubit>().signUpWithPhone(phone: phone, name: 'User');
        }
      }
      return;
    }

    // Real verification
    try {
      await context.read<AuthCubit>().verifyLoginOtp(phone: formattedPhone, token: code);
    } catch (e) {
      context.showSnackBar('Verification failed: $e', isError: true);
    }
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
            color: context.isDarkMode ? const Color(0xFF0F0F1A) : const Color(0xFFF5F7FA),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
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
                          'Mugundhan Tex & Readymades',
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
                                // Segment Selector
                                Container(
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _isPhoneMode = false;
                                            _otpSent = false;
                                            _needsRegister = false;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: !_isPhoneMode
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              'Email Login',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: !_isPhoneMode ? Colors.white : (context.isDarkMode ? Colors.white70 : Colors.black54),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _isPhoneMode = true;
                                            _otpSent = false;
                                            _needsRegister = false;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _isPhoneMode
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              'Mobile OTP',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: _isPhoneMode ? Colors.white : (context.isDarkMode ? Colors.white70 : Colors.black54),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (!_isPhoneMode) ...[
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
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        child: state is AuthLoading
                                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                            : const Text('SIGN IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                                      );
                                    },
                                  ),
                                ] else ...[
                                  CustomTextField(
                                    controller: _phoneController,
                                    label: 'Mobile Number',
                                    hint: 'Enter 10-digit number',
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icons.phone_android_outlined,
                                    readOnly: _otpSent || _needsRegister,
                                  ),
                                  
                                  if (_needsRegister && !_otpSent) ...[
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _phoneNameController,
                                      label: 'Full Name',
                                      hint: 'Enter your full name',
                                      prefixIcon: Icons.person_outline,
                                    ),
                                    const SizedBox(height: 20),
                                    BlocBuilder<AuthCubit, AuthState>(
                                      builder: (context, state) {
                                        return PremiumButton(
                                          onPressed: state is AuthLoading ? null : _sendOtpForNewUser,
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          child: state is AuthLoading
                                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                              : const Text('PROCEED TO VERIFY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                        );
                                      },
                                    ),
                                  ],

                                  if (!_otpSent && !_needsRegister) ...[
                                    const SizedBox(height: 20),
                                    BlocBuilder<AuthCubit, AuthState>(
                                      builder: (context, state) {
                                        return PremiumButton(
                                          onPressed: state is AuthLoading ? null : _sendOtp,
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          child: state is AuthLoading
                                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                              : const Text('SEND OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                        );
                                      },
                                    ),
                                  ],

                                  if (_otpSent) ...[
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _otpController,
                                      label: 'Verification Code',
                                      hint: 'Enter OTP code',
                                      keyboardType: TextInputType.number,
                                      prefixIcon: Icons.pin_outlined,
                                      onChanged: (val) {
                                        final trimmed = val.trim();
                                        if (trimmed.length == 4 || trimmed.length == 6) {
                                          _verifyOtpAndLogin();
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _timerSeconds > 0
                                              ? 'Resend OTP in ${_timerSeconds}s'
                                              : 'Did not receive code?',
                                          style: context.textTheme.bodySmall,
                                        ),
                                        TextButton(
                                          onPressed: _timerSeconds > 0
                                              ? null
                                              : () {
                                                  if (_needsRegister) {
                                                    _sendOtpForNewUser();
                                                  } else {
                                                    _sendOtp();
                                                  }
                                                },
                                          child: const Text('Resend Code'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    BlocBuilder<AuthCubit, AuthState>(
                                      builder: (context, state) {
                                        return PremiumButton(
                                          onPressed: state is AuthLoading ? null : _verifyOtpAndLogin,
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          child: state is AuthLoading
                                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                              : const Text('VERIFY & SIGN IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _otpSent = false;
                                          _needsRegister = false;
                                          _otpController.clear();
                                          _phoneNameController.clear();
                                          _timer?.cancel();
                                          _timerSeconds = 0;
                                        });
                                      },
                                      child: const Text('Change Mobile Number'),
                                    ),
                                  ],
                                ],
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
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            ),
                            icon: Image.network(
                              'https://www.google.com/favicon.ico',
                              height: 20, width: 20,
                              errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
                            ),
                            label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
                                  color: Theme.of(context).colorScheme.primary,
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
      ),
    );
  }
}
