import 'package:flutter/material.dart';

// Brand Colors - Friday Night Lights Dark Mode Theme
const Color efficialsBlack = Color(0xFF121212);      // True dark background
const Color efficialsYellow = Color(0xFFFFD700);     // Bright goalpost yellow (gold)
const Color efficialsWhite = Color(0xFFE8E8E8);      // Bright stadium light white
const Color efficialsGreen = Color(0xFF4CAF50);      // Bright football field green
const Color efficialsGray = Color(0xFF9E9E9E);       // Light gray for dark mode

// Legacy compatibility (maps to Friday night theme colors)
const Color efficialsBlue = efficialsYellow;         // Legacy blue now maps to yellow

// Dark Mode Specific Colors
const Color darkBackground = Color(0xFF0A0A0A);      // Deepest black for main background
const Color darkSurface = Color(0xFF1E1E1E);        // Slightly lighter for cards/surfaces
const Color stadiumLightYellow = Color(0xFFFFF176);  // Softer light glow
const Color midnightBlue = Color(0xFF0D1B2A);        // Deep night accent
const Color fieldLineWhite = Color(0xFFFFFFFF);      // Crisp field lines

// Semantic Colors - Dark Mode
const Color primaryTextColor = efficialsWhite;       // Light text on dark backgrounds
const Color secondaryTextColor = efficialsGray;      // Gray text for secondary info
const Color linkColor = efficialsYellow;             // Yellow links for visibility
const Color buttonColor = efficialsYellow;          // Bright yellow primary buttons
const Color borderColor = efficialsYellow;

// Text Styles
const TextStyle appBarTextStyle = TextStyle(
  color: efficialsWhite,
  fontSize: 20,
  fontWeight: FontWeight.bold,
);

const TextStyle headlineStyle = TextStyle(
  color: primaryTextColor,
  fontSize: 24,
  fontWeight: FontWeight.bold,
);

const TextStyle homeTextStyle = TextStyle(
  color: primaryTextColor,
  fontSize: 18,
);

const TextStyle secondaryTextStyle = TextStyle(
  color: secondaryTextColor,
  fontSize: 16,
);

const TextStyle buttonTextStyle = TextStyle(
  color: efficialsBlack,  // Black text on yellow buttons for contrast
  fontSize: 16,
  fontWeight: FontWeight.w600,
);

const TextStyle footerTextStyle = TextStyle(
  color: secondaryTextColor,
  fontSize: 12,
);

const TextStyle linkTextStyle = TextStyle(
  color: linkColor,
  fontSize: 16,
  decoration: TextDecoration.underline,
);

const TextStyle signInButtonTextStyle = TextStyle(
  color: efficialsBlack,  // Black text on yellow buttons for contrast
  fontSize: 16,
  fontWeight: FontWeight.w600,
);

// Input Decoration - Dark Mode
InputDecoration textFieldDecoration(String label, {Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: efficialsGray),
    suffixIcon: suffixIcon,
    fillColor: darkSurface,
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: efficialsGray.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: efficialsGray.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: efficialsYellow, width: 2),
    ),
    floatingLabelStyle: const TextStyle(color: efficialsYellow),
    hintStyle: TextStyle(color: efficialsGray.withOpacity(0.7)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

// Button Styles
ButtonStyle elevatedButtonStyle({EdgeInsetsGeometry? padding, Color? backgroundColor}) {
  return ElevatedButton.styleFrom(
    backgroundColor: backgroundColor ?? buttonColor,
    foregroundColor: efficialsBlack,  // Black text on yellow buttons
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: buttonColor,
  foregroundColor: efficialsBlack,  // Black text on yellow buttons
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
);

final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: darkSurface,
  foregroundColor: buttonColor,
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  side: const BorderSide(color: buttonColor),
);
