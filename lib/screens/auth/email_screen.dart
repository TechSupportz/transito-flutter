import 'dart:async';

import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

import '../../global/services/authentication_service.dart';
import '../../widgets/auth/email_verification_dialog.dart';
import '../onboarding/location_access_screen.dart';
import 'login_screen.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

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
              settings: const RouteSettings(name: 'LoginScreen'),
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
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
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
                          child: SvgPicture.asset('assets/images/logo.svg', height: 200),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'The last bus timing app you\'ll ever need.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 264),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 185),
                          switchInCurve: Curves.easeInExpo,
                          transitionBuilder: (child, animation) => FadeScaleTransition(
                            animation: animation,
                            child: child,
                          ),
                          child: _isLogin ? renderLoginForm() : renderRegisterForm(),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isLogin = !_isLogin;
                        }),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) => FadeScaleTransition(
                            animation: animation,
                            child: child,
                          ),
                          child: _isLogin
                              ? Row(
                                  key: const ValueKey<bool>(true),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      'New Here?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      'Register!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  key: const ValueKey<bool>(false),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      'Already have an account?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      'Login!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
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

  FormBuilder renderRegisterForm() {
    return FormBuilder(
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => onRegisterBtnPress(),
            child: AnimatedSwitcher(
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              duration: const Duration(milliseconds: 125),
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Text('Register'),
            ),
          )
        ],
      ),
    );
  }

  FormBuilder renderLoginForm() {
    return FormBuilder(
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
                onPressed: () {
                  setState(() {
                    _isLoginPasswordVisible = !_isLoginPasswordVisible;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => onLoginBtnPress(),
            child: AnimatedSwitcher(
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              duration: const Duration(milliseconds: 175),
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Text('Login'),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => showForgetPasswordDialog(),
            child: Text(
              'Forgot password?',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  AlertDialog forgetPasswordDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Forgot Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              'Please enter your email address and we will send you a link to reset your password.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 16),
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
