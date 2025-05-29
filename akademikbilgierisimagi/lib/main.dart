import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'register_page.dart'; // bunu oluşturduysan ekle
import 'home_page.dart'; // giriş sonrası yönlenecek sayfa
import 'firebase_options.dart'; // Firebase yapılandırma dosyası

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akademik Bilgi Ağı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthGate(), // Giriş yaptı mı kontrol eden widget
    );
  }
}

// Kullanıcı giriş yaptıysa ana sayfa, yapmadıysa giriş ekranı
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return const HomePage(); // Giriş yapmış kullanıcı için ana sayfa
        } else {
          return const LoginPage(); // Giriş yapmamışsa giriş ekranı
        }
      },
    );
  }
}
