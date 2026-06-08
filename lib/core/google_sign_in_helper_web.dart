// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  required bool isLoading,
  bool useCustomStyle = false,
}) {
  if (useCustomStyle) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: Image.network(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
        height: 20,
        errorBuilder: (context, error, stackTrace) => const Text(
          'G',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
      label: const Text(
        'Sign in with Google',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  final plugin = GoogleSignInPlatform.instance;
  if (plugin is web.GoogleSignInPlugin) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: Center(
        child: plugin.renderButton(
          configuration: web.GSIButtonConfiguration(
            type: web.GSIButtonType.standard,
            shape: web.GSIButtonShape.pill,
            size: web.GSIButtonSize.large,
            text: web.GSIButtonText.signinWith,
            logoAlignment: web.GSIButtonLogoAlignment.left,
          ),
        ),
      ),
    );
  }
  
  // Fallback if not web plugin (should never happen when HTML library is active)
  return const SizedBox.shrink();
}
