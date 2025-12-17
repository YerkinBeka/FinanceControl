import 'package:flutter/material.dart';


const primaryColor = Color(0xFF4F46E5);
const backgroundColor = Color(0xFFF5F6FA);


const TextStyle titleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold,
);

const TextStyle subtitleStyle = TextStyle(
  fontSize: 14,
  color: Colors.grey,
);


const TextStyle buttonTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.white, 
);


final cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: const [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 10,
      offset: Offset(0, 6),
    ),
  ],
);


InputDecoration inputStyle(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}


final buttonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryColor,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  padding: const EdgeInsets.symmetric(vertical: 14),
);
