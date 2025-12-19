import 'package:cotton/screens/signIn.dart';
import 'package:cotton/screens/signUp.dart';
import 'package:flutter/material.dart';
import 'package:cotton/components/constants.dart';
import 'package:cotton/components/primary_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text("Log In"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: mainDefaultPadding),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(
                "assets/logo.png",
                height: 250,
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                  text: "Sign In",
                  press: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInPage(),
                        ),
                      )),
              const SizedBox(height: mainDefaultPadding * 1.5),
              PrimaryButton(
                color: mainSecondaryColor,
                text: "Sign Up",
                press: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignUpPage(),
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
