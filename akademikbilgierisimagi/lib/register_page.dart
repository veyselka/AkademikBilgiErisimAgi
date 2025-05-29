import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? selectedUniversityId;
  String? selectedDepartmentId;

  Map<String, String> universityMap = {}; // "Üniversite Adı": "100"
  Map<String, String> departmentMap = {}; // "Bölüm Adı": "405"

  String? errorText;

  @override
  void initState() {
    super.initState();
    fetchUniversities();
  }

  Future<void> fetchUniversities() async {
    final snapshot = await FirebaseDatabase.instance.ref('universiteler').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        universityMap = {
          for (var entry in data.entries) entry.value['name']: entry.key,
        };
      });
    }
  }

  Future<void> fetchDepartments(String universityId) async {
    final snapshot = await FirebaseDatabase.instance
        .ref('universiteler/$universityId/bolumler')
        .get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        departmentMap = {
          for (var entry in data.entries) entry.value['name']: entry.key,
        };
        selectedDepartmentId = null;
      });
    }
  }

  Future<void> registerUser() async {
    setState(() => errorText = null);

    try {
      // Firebase Auth ile kayıt
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // Realtime Database'e kayıt
      await FirebaseDatabase.instance.ref('kullanicilar/$uid').set({
        'isim': nameController.text.trim(),
        'email': emailController.text.trim(),
        'sifre': passwordController.text.trim(),
        'universiteId': selectedUniversityId,
        'bolumId': selectedDepartmentId,
        'avatarUrl': '',
        'bio': '',
        'ayarlar': {
          'bildirimlerAcikMi': true,
          'dil': 'tr',
          'karanlikMod': false,
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı")),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => errorText = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFE0EAFD)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text('Yeni Hesap Oluştur',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Ad Soyad')),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),

                  // Üniversite seçimi
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Üniversite'),
                    value: selectedUniversityId,
                    onChanged: (value) {
                      setState(() {
                        selectedUniversityId = value;
                        departmentMap.clear();
                      });
                      if (value != null) fetchDepartments(value);
                    },
                    items: universityMap.entries
                        .map((e) => DropdownMenuItem(
                            value: e.value, child: Text(e.key)))
                        .toList(),
                  ),
                  const SizedBox(height: 10),

                  // Bölüm seçimi
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Bölüm'),
                    value: selectedDepartmentId,
                    onChanged: (value) =>
                        setState(() => selectedDepartmentId = value),
                    items: departmentMap.entries
                        .map((e) => DropdownMenuItem(
                            value: e.value, child: Text(e.key)))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Şifre')),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Şifre Tekrar')),
                  const SizedBox(height: 10),

                  if (errorText != null)
                    Text(errorText!, style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate() &&
                            passwordController.text ==
                                confirmPasswordController.text) {
                          registerUser();
                        } else {
                          setState(() {
                            errorText = "Şifreler eşleşmiyor";
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue[600]),
                      child: const Text('Kayıt Ol'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // geri dön
                    },
                    child: const Text("Zaten hesabın var mı? Giriş Yap"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
