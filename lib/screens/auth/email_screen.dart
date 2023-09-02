import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

import '../../models/app_colors.dart';
import '../../providers/authentication_service.dart';
import '../../widgets/email_verification_dialog.dart';
import '../onboarding_screens/location_access_screen.dart';
import 'login_screen.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({Key? key}) : super(key: key);

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final Widget _defaultHome = const LocationAccessScreen();

  // Login form keys
  final _loginFormKey = GlobalKey<FormBuilderState>();
  final _emailLoginFieldKey = GlobalKey<FormBuilderFieldState>();
  final _passwordLoginFieldKey = GlobalKey<FormBuilderFieldState>();
  final _forgotPasswordEmailFieldKey = GlobalKey<FormBuilderFieldState>();

  // Register form keys
  final _registerFormKey = GlobalKey<FormBuilderState>();
  final _nameFieldKey = GlobalKey<FormBuilderFieldState>();
  final _emailRegisterFieldKey = GlobalKey<FormBuilderFieldState>();
  final _passwordRegisterFieldKey = GlobalKey<FormBuilderFieldState>();

  bool _isLogin = true;
  bool _isLoginPasswordVisible = false;
  bool isRegisterPasswordVisible = true;
  bool _isLoading = false;

  void onLoginBtnPress() async {
    setState(() {
      _isLoading = true;
    });
    _loginFormKey.currentState!.saveAndValidate();
    if (_loginFormKey.currentState!.isValid) {
      AuthenticationService()
          .loginUserWithEmail(
        _emailLoginFieldKey.currentState!.value,
        _passwordLoginFieldKey.currentState!.value,
      )
          .then(
        (err) async {
          if (err == null) {
            setState(() {
              _isLoading = false;
            });
            if (context.read<User>().emailVerified) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => _defaultHome,
                ),
                (Route<dynamic> route) => false,
              );
            } else {
              showDialog(
                context: context,
                builder: (context) => const EmailVerificationDialog(),
              );
            }
          } else {
            setState(() {
              _isLoading = false;
            });
            switch (err) {
              case 'user-not-found':
                _emailLoginFieldKey.currentState!.invalidate("No user found with this email");
                break;
              case 'wrong-password':
                _passwordLoginFieldKey.currentState!.invalidate("Incorrect password");
                break;
              case 'user-disabled':
                _emailLoginFieldKey.currentState!.invalidate("This account has been disabled");
                break;
              default:
                _emailLoginFieldKey.currentState!
                    .invalidate("Oops, something went wrong on our end");
                _passwordLoginFieldKey.currentState!
                    .invalidate("Oops, something went wrong on our end");
                break;
            }
          }
        },
      );
    } else {
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _isLoading = false;
        });
        _loginFormKey.currentState!.validate();
      });
    }
  }

  void showForgetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => forgetPasswordDialog(context),
    );
  }

  void onSendPasswordResetBtnPress() async {
    _forgotPasswordEmailFieldKey.currentState!.save();
    _forgotPasswordEmailFieldKey.currentState!.validate();
    if (_forgotPasswordEmailFieldKey.currentState!.isValid) {
      await AuthenticationService()
          .sendPasswordResetEmail(_forgotPasswordEmailFieldKey.currentState!.value)
          .then(
        (err) {
          if (err == null) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Check your email for a password reset link'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            switch (err) {
              case 'user-not-found':
                _forgotPasswordEmailFieldKey.currentState!
                    .invalidate("No user found with this email");
                break;
              default:
                _forgotPasswordEmailFieldKey.currentState!
                    .invalidate("Oops, something went wrong on our end");
                break;
            }
          }
        },
      );
    }
  }

  void onRegisterBtnPress() {
    setState(() {
      _isLoading = true;
    });
    _registerFormKey.currentState!.saveAndValidate();
    if (_registerFormKey.currentState!.validate()) {
      AuthenticationService()
          .registerUserWithEmail(
        _nameFieldKey.currentState!.value,
        _emailRegisterFieldKey.currentState!.value,
        _passwordRegisterFieldKey.currentState!.value,
      )
          .then((err) {
        if (err == null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (Route<dynamic> route) => false,
          );
          showDialog(
            context: context,
            builder: (context) => const EmailVerificationDialog(),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          switch (err) {
            case 'email-already-in-use':
              _emailRegisterFieldKey.currentState!.invalidate('Email already in use');
              break;
            case 'weak-password':
              _passwordRegisterFieldKey.currentState!.invalidate('Password is too weak');
              break;
          }
        }
      });
    } else {
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var registerForm = FormBuilder(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormBuilderTextField(
            key: _nameFieldKey,
            name: 'name',
            scrollPadding: const EdgeInsets.symmetric(vertical: 50),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            key: _emailRegisterFieldKey,
            name: 'email',
            scrollPadding: const EdgeInsets.symmetric(vertical: 50),
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.email(),
            ]),
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            key: _passwordRegisterFieldKey,
            name: 'password',
            scrollPadding: const EdgeInsets.symmetric(vertical: 50),
            obscureText: !isRegisterPasswordVisible,
            keyboardType: TextInputType.visiblePassword,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            valueTransformer: (value) => value?.trim(),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(8, errorText: 'Enter at least 8 characters'),
            ]),
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(isRegisterPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                iconSize: 24,
                splashRadius: 1,
                onPressed: () {
                  setState(() {
                    isRegisterPasswordVisible = !isRegisterPasswordVisible;
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21.0, vertical: 16),
            child: OutlinedButton(
              onPressed: () => onRegisterBtnPress(),
              child: AnimatedSwitcher(
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                duration: const Duration(milliseconds: 125),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Text('Register'),
              ),
            ),
          )
        ],
      ),
    );
    var loginForm = FormBuilder(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormBuilderTextField(
            key: _emailLoginFieldKey,
            name: 'email',
            scrollPadding: const EdgeInsets.symmetric(vertical: 50),
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.email(),
            ]),
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            key: _passwordLoginFieldKey,
            name: 'password',
            scrollPadding: const EdgeInsets.symmetric(vertical: 50),
            obscureText: !_isLoginPasswordVisible,
            keyboardType: TextInputType.visiblePassword,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: FormBuilderValidators.compose([FormBuilderValidators.required()]),
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_isLoginPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                iconSize: 24,
                splashRadius: 1,
                color: Colors.white70,
                onPressed: () {
                  setState(() {
                    _isLoginPasswordVisible = !_isLoginPasswordVisible;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21.0),
            child: OutlinedButton(
              onPressed: () => onLoginBtnPress(),
              child: AnimatedSwitcher(
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                duration: const Duration(milliseconds: 175),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Text('Login'),
              ),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => showForgetPasswordDialog(),
            child: Text(
              'Forgot password?',
              style: TextStyle(fontSize: 14, color: AppColors.accentColour),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Sign in'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: SvgPicture.asset('assets/images/logo.svg'),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Simply login and never miss a bus again!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: AppColors.kindaGrey),
                        ),
                      ],
                    ),
                    const Spacer(flex: 1),
                    Container(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 264),
                          child: AnimatedSwitcher(
                            transitionBuilder: (child, animation) => ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                            duration: const Duration(milliseconds: 175),
                            child: _isLogin ? loginForm : registerForm,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isLogin = !_isLogin;
                        }),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _isLogin
                              ? [
                                  const Text(
                                    'New Here?',
                                    style: TextStyle(fontSize: 14, color: AppColors.kindaGrey),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Register!',
                                    style: TextStyle(fontSize: 14, color: AppColors.accentColour),
                                  ),
                                ]
                              : [
                                  const Text(
                                    'Already have an account?',
                                    style: TextStyle(fontSize: 14, color: AppColors.kindaGrey),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Login!',
                                    style: TextStyle(fontSize: 14, color: AppColors.accentColour),
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AlertDialog forgetPasswordDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Forgot Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Please enter your email address and we will send you a link to reset your password.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.kindaGrey,
              )),
          const SizedBox(height: 18),
          FormBuilderTextField(
            key: _forgotPasswordEmailFieldKey,
            name: 'email',
            decoration: const InputDecoration(
              labelText: 'Email',
              fillColor: Colors.white10,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: FormBuilderValidators.compose(
              [
                FormBuilderValidators.email(),
                FormBuilderValidators.required(),
              ],
            ),
          )
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Send'),
          onPressed: () => onSendPasswordResetBtnPress(),
        ),
      ],
    );
  }
}
