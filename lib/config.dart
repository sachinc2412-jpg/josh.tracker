import 'package:flutter/material.dart';

class Config {
  static const supabaseUrl = 'https://xthtlvrqkfmkvoscpzxv.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0aHRsdnJxa2Zta3Zvc2Nwenh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5NzUyMTQsImV4cCI6MjEwNTU1MTIxNH0.ocd5ptpHDc3LsB2pJhuyn7LS_3FU0Y5_o76gbrUVSww';

  // The WEB OAuth client ID from Google Cloud (NOT the Android one).
  // Needed so google_sign_in returns an idToken Supabase will accept.
  // e.g. 1234-abcd.apps.googleusercontent.com  — see README.
  static const googleServerClientId = '265368730090-hvt2oltohgobl47upbs0p14e5amvll2n.apps.googleusercontent.com';
}

// iOS-style dark tokens.
class C {
  static const bg = Color(0xFF000000);
  static const card = Color(0xFF171719);
  static const card2 = Color(0xFF232326);
  static const sep = Color(0x26FFFFFF);
  static const label = Color(0xFFFFFFFF);
  static const label2 = Color(0xFFAAAAAF);
  static const label3 = Color(0xFF87878F);
  static const blue = Color(0xFF0A84FF);
  static const green = Color(0xFF30D158);
  static const red = Color(0xFFFF453A);
  static const orange = Color(0xFFFF9F0A);
  static const indigo = Color(0xFF5E5CE6);
  static const pink = Color(0xFFFF375F);
  static const teal = Color(0xFF40C8E0);

  static const tileTints = [
    Color(0x330A84FF),
    Color(0x3330D158),
    Color(0x33FF453A),
    Color(0x33FF9F0A),
    Color(0x335E5CE6),
    Color(0x33FF375F),
    Color(0x3340C8E0),
  ];
}
