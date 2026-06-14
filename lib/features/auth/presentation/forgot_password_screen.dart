import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/premium_button.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().resetPassword(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetSent) {
            context.showSuccessSnackBar(
                'Password reset link sent! Check your email.');
            context.pop();
          }
          if (state is AuthError) {
            context.showSnackBar(state.message, isError: true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset Password', style: context.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Enter your email and we\'ll send you a link to reset your password.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.isDarkMode ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                ),
              ),
              const SizedBox(height: 24),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  return PremiumButton(
                    onPressed: state is AuthLoading ? null : _resetPassword,
                    backgroundColor: context.isDarkMode ? Colors.white : Colors.black,
                    child: state is AuthLoading
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: context.isDarkMode ? Colors.black : Colors.white))
                        : Text('SEND RESET LINK', style: TextStyle(color: context.isDarkMode ? Colors.black : Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
