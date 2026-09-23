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

// Shared adaptive design tokens. Configured before each app theme rebuild.
class C {
  static bool light=false;
  static String accent='blue';
  static void configure(bool isLight,String selected){light=isLight;accent=selected;}
  static Color get bg=>Color(light?0xFFF5F5F7:0xFF000000);
  static Color get card=>Color(light?0xFFFFFFFF:0xFF171719);
  static Color get card2=>Color(light?0xFFEEEEF2:0xFF232326);
  static Color get sep=>Color(light?0x1F000000:0x26FFFFFF);
  static Color get label=>Color(light?0xFF19191C:0xFFFFFFFF);
  static Color get label2=>Color(light?0xFF626269:0xFFAAAAAF);
  static Color get label3=>Color(light?0xFF707078:0xFF87878F);
  static Color get blue=>Color(switch(accent){
    'teal'=>light?0xFF18786B:0xFF66C9B5,
    'violet'=>light?0xFF6850BF:0xFFB09CFF,
    'rose'=>light?0xFFAD4268:0xFFF28EAE,
    _=>light?0xFF0067CC:0xFF0A84FF,
  });
  static Color get green=>Color(light?0xFF20763A:0xFF30D158);
  static Color get red=>Color(light?0xFFBE302B:0xFFFF453A);
  static Color get orange=>Color(light?0xFF985500:0xFFFF9F0A);
  static const indigo=Color(0xFF5E5CE6),pink=Color(0xFFFF375F),teal=Color(0xFF40C8E0);
  static const tileTints=[Color(0x330A84FF),Color(0x3330D158),Color(0x33FF453A),Color(0x33FF9F0A),Color(0x335E5CE6),Color(0x33FF375F),Color(0x3340C8E0)];
}
