import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  required bool isLoading,
  bool useCustomStyle = false,
}) {
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
