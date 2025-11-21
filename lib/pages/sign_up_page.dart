import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'sign_in_page.dart';
import '../widgets/auth_text_field.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final username = TextEditingController();
  final supabaseService = SupabaseService();

  bool loading = false;

  void signUp() async {
    setState(() => loading = true);
    try {
      await supabaseService.signUp(
        email.text,
        password.text,
        username.text,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SignInPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Sign Up", style: TextStyle(fontSize: 32)),
            //TextField(controller: username, decoration: InputDecoration(labelText: "Username")),
            //TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
            //TextField(controller: password, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            AuthTextField(
              controller: username,
              label: "Username",
            ),

            AuthTextField(
              controller: email,
              label: "Email",
              keyboardType: TextInputType.emailAddress,
            ),

            AuthTextField(
              controller: password,
              label: "Password",
              obscure: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : signUp,
              child: loading ? CircularProgressIndicator() : Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}

