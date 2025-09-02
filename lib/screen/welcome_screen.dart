import 'package:flutter/material.dart';
import 'package:fyp25/screen/login.dart';
import 'package:fyp25/screen/register.dart';
import 'package:fyp25/widgets/welcome_button.dart';
import 'package:fyp25/widgets/custom_scaffold.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;

    return CustomScaffold(
      showBackArrow: false,
      child: Column(
        children: [
          Flexible(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome Back!\n',
                        style: TextStyle(
                          fontSize: isPhone ? 32 : 46,
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // Always set color
                        ),
                      ),
                      TextSpan(
                        text:
                        '\nPlease fill your information before entering the application',
                        style: TextStyle(
                          fontSize: isPhone ? 16 : 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  Expanded(
                    child: WelcomeButton(
                      buttonText: 'Log In',
                      onTap: const LoginScreen(),
                      color: const Color.fromRGBO(41, 70, 158, 1.0),
                      textColor: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(50),
                      ),
                      isPhone: isPhone,
                    ),
                  ),
                  Expanded(
                    child: WelcomeButton(
                      buttonText: 'Register',
                      onTap: const RegisterScreen(),
                      color: Colors.white,
                      textColor: const Color.fromRGBO(41, 70, 158, 1.0),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(50),
                      ),
                      isPhone: isPhone,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
