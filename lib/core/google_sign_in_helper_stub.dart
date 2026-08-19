import 'package:flutter/material.dart';
import 'widgets/google_logo_icon.dart';

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  required bool isLoading,
  bool useCustomStyle = false,
}) {
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
