import 'package:flutter/material.dart';

// Universal color
const efficialsBlue = Colors.blue;

// Text styles
const TextStyle headlineStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle homeTextStyle = TextStyle( // New style for Home screen
  fontSize: 20, // Reduced from 28 to fit on one line
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle buttonTextStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: Colors.white, // Ensure white text on buttons
);

const TextStyle secondaryTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.black54,
);

const TextStyle linkTextStyle = TextStyle(
  fontSize: 16, // Match secondary text size for consistency
  color: efficialsBlue,
);

const TextStyle footerTextStyle = TextStyle(
  fontSize: 12,
  color: Colors.grey,
);

const TextStyle signInButtonTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.white, // Ensure white text on Sign In button
);

// AppBar text style (moved here for universal application)
const TextStyle appBarTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 22,
  fontWeight: FontWeight.bold,
);

// Button style with consistent size
ButtonStyle elevatedButtonStyle({
  Color? backgroundColor,
  EdgeInsetsGeometry? padding, // Optional padding override
}) =>
    ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? efficialsBlue,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
      minimumSize: const Size(200, 50), // Ensure minimum width and height
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

// Text field decoration
InputDecoration textFieldDecoration(String hintText, {Widget? suffixIcon}) =>
    InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey), // Add this
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: efficialsBlue, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: efficialsBlue, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: efficialsBlue, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
    );