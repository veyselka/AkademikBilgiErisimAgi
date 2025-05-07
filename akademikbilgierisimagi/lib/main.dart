import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: RegisterPage(),
  ));
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedUniversity;
  String? selectedDepartment;

  final List<String> universities = [
    'Üniversite 1',
    'Üniversite 2',
    'Üniversite 3'
  ];
  final List<String> departments = [
    'Bilgisayar Müh.',
    'Elektrik-Elektronik',
    'Makine Müh.'
  ];

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
                  const Text(
                    'Yeni Hesap Oluştur',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      hintText: 'ornek@universite.edu.tr',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Üniversite'),
                    value: selectedUniversity,
                    onChanged: (value) {
                      setState(() {
                        selectedUniversity = value;
                      });
                    },
                    items: universities
                        .map((uni) =>
                            DropdownMenuItem(value: uni, child: Text(uni)))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Bölüm'),
                    value: selectedDepartment,
                    onChanged: (value) {
                      setState(() {
                        selectedDepartment = value;
                      });
                    },
                    items: departments
                        .map((dep) =>
                            DropdownMenuItem(value: dep, child: Text(dep)))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Şifre'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Şifre Tekrar'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[600],
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Kayıt işlemi
                        }
                      },
                      child: const Text('Kayıt Ol'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Zaten hesabınız var mı?'),
                      TextButton(
                        onPressed: () {
                          // Giriş ekranına yönlendirme
                        },
                        child: const Text('Giriş Yap'),
                      ),
                    ],
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
