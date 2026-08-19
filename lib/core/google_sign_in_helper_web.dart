// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import 'widgets/google_logo_icon.dart';

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  required bool isLoading,
  bool useCustomStyle = false,
}) {
  if (useCustomStyle) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDADCE0), width: 1),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4285F4)),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoogleLogoIcon(size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      color: Color(0xFF3C4043),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
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
  
  return const SizedBox.shrink();
}
