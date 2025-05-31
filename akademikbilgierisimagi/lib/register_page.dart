import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_page.dart';

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

  Map<String, String> universityMap = {}; // { "100": "İstanbul Üniversitesi" }
  Map<String, String> departmentMap =
      {}; // { "400": "Bilgisayar Mühendisliği" }

  String? errorText;

  @override
  void initState() {
    super.initState();
    fetchUniversities();
  }

  Future<void> fetchUniversities() async {
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('universiteler').get();
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          Map<String, String> fetchedUniversities = {};
          data.forEach((key, val) {
            if (val is Map && val['name'] != null) {
              fetchedUniversities[key] = val['name'].toString();
            }
          });

          setState(() {
            universityMap = fetchedUniversities;
          });
        }
      }
    } catch (e) {
      debugPrint('fetchUniversities hatası: $e');
    }
  }

  Future<void> fetchDepartments(String universityId) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('universiteler/$universityId/bolumler')
          .get();

      if (snapshot.exists) {
        final data = snapshot.value;

        if (data is Map) {
          Map<String, String> fetchedDepartments = {};
          data.forEach((key, val) {
            if (val is Map && val['name'] != null) {
              fetchedDepartments[key] = val['name'].toString();
            }
          });

          setState(() {
            departmentMap = fetchedDepartments;
            selectedDepartmentId = null;
          });
        } else {
          setState(() {
            departmentMap = {};
            selectedDepartmentId = null;
          });
        }
      } else {
        setState(() {
          departmentMap = {};
          selectedDepartmentId = null;
        });
      }
    } catch (e) {
      debugPrint('fetchDepartments hatası: $e');
    }
  }

  Future<void> registerUser() async {
    setState(() => errorText = null);

    if (selectedUniversityId == null || selectedDepartmentId == null) {
      setState(() {
        errorText = "Lütfen üniversite ve bölüm seçiniz.";
      });
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorText = "Şifreler eşleşmiyor.";
      });
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      await FirebaseDatabase.instance.ref('kullanicilar/$uid').set({
        'isim': nameController.text.trim(),
        'email': emailController.text.trim(),
        'universite': selectedUniversityId,
        'bolum': selectedDepartmentId,
        'avatarUrl': '',
        'bio': '',
        'ayarlar': {
          'bildirimlerAcikMi': true,
          'dil': 'tr',
          'karanlikMod': false,
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
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
                    decoration: const InputDecoration(labelText: 'Ad Soyad'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ad Soyad giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta giriniz';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Geçerli bir e-posta giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Üniversite'),
                    value: selectedUniversityId,
                    onChanged: (value) {
                      setState(() {
                        selectedUniversityId = value;
                        departmentMap.clear();
                        selectedDepartmentId = null;
                      });
                      if (value != null) fetchDepartments(value);
                    },
                    items: universityMap.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key, // üniversiteId
                              child: Text(e.value), // üniversiteAdı
                            ))
                        .toList(),
                    validator: (value) =>
                        value == null ? 'Üniversite seçiniz' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Bölüm'),
                    value: selectedDepartmentId,
                    onChanged: (value) =>
                        setState(() => selectedDepartmentId = value),
                    items: departmentMap.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key, // bolumId
                              child: Text(e.value), // bolumAdı
                            ))
                        .toList(),
                    validator: (value) =>
                        value == null ? 'Bölüm seçiniz' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Şifre'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre giriniz';
                      }
                      if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalı';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Şifre Tekrar'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre tekrar giriniz';
                      }
                      if (value != passwordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  if (errorText != null)
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          registerUser();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[600],
                      ),
                      child: const Text('Kayıt Ol'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Geri dön
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
