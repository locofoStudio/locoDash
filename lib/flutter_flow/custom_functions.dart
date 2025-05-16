// Custom functions

import 'dart:math' as math;

class CustomFunctions {
  static int getUniqueUsersCount(List<String> userIds) {
    return userIds.toSet().length;
  }
  
  static String formatNumberWithLeadingZeros(int number, int length) {
    return number.toString().padLeft(length, '0');
  }
} 