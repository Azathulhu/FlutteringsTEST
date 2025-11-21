import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/sign_in_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://nisssojyxkmiletzqjim.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pc3Nzb2p5eGttaWxldHpxamltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2Nzk1NDEsImV4cCI6MjA3OTI1NTU0MX0.pX0qwuNXvSFXeIt9H_zemGJRbJpnKQFVkIeKZ2c2sxk",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignInPage(),
    );
  }
}
