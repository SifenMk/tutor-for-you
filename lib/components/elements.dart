import 'package:flutter/material.dart';

class SimpleComponents {
  static Widget buildTextField(
      TextEditingController controller, String label, String hint,
      {bool isEmail = false,
      bool isPassword = false,
      bool isPhone = false,
      bool isLongText = false}) {
    bool obscureText = true;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return TextFormField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          keyboardType: isEmail
              ? TextInputType.emailAddress
              : (isPhone
                  ? TextInputType.phone
                  : (isLongText
                      ? TextInputType.multiline
                      : TextInputType.text)),
          maxLines: isLongText ? null : 1,
          minLines: isLongText ? 4 : 1,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Colors.blue,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Colors.blue,
                width: 2.0,
              ),
            ),
            labelStyle: TextStyle(
              color: Colors.grey[700],
              fontSize: 18,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                  )
                : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (isEmail &&
                !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}').hasMatch(value)) {
              return 'Enter a valid email';
            }
            if (isPassword && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        );
      },
    );
  }

  static Widget buildSocialButton(String text, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {
        // Implement Google/Facebook sign-in functionality
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static Widget buildButton(
      {required bool isLoading,
      required VoidCallback onTap,
      required String buttonText}) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                buttonText,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ),
          );
  }
}
