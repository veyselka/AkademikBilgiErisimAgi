import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfilDuzenlePage extends StatefulWidget {
  const ProfilDuzenlePage({super.key});

  @override
  State<ProfilDuzenlePage> createState() => _ProfilDuzenlePageState();
}

class _ProfilDuzenlePageState extends State<ProfilDuzenlePage> {
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference kullaniciRef;
  late DatabaseReference universiteRef;

  final _isimController = TextEditingController();
  final _bioController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  String? email;
  String? universiteAdi;
  String? bolumAdi;

  @override
  void initState() {
    super.initState();
    kullaniciRef =
        FirebaseDatabase.instance.ref().child('kullanicilar/${user!.uid}');
    universiteRef = FirebaseDatabase.instance.ref().child('universiteler');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final snapshot = await kullaniciRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final String uniId = data['universiteId'];
    final String bolumId = data['bolumId'];

    final uniSnapshot = await universiteRef.child(uniId).get();
    final bolumSnapshot =
        await universiteRef.child('$uniId/bolumler/$bolumId').get();

    setState(() {
      _isimController.text = data['isim'] ?? '';
      _bioController.text = data['bio'] ?? '';
      _avatarUrlController.text = data['avatarUrl'] ?? '';
      email = data['email'];
      universiteAdi = uniSnapshot.child('name').value as String?;
      bolumAdi = bolumSnapshot.child('name').value as String?;
    });
  }

  Future<void> _saveChanges() async {
    await kullaniciRef.update({
      'isim': _isimController.text.trim(),
      'bio': _bioController.text.trim(),
      'avatarUrl': _avatarUrlController.text.trim(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil başarıyla güncellendi.")),
      );
      Navigator.pop(context); // geri dön
    }
  }

  @override
  void dispose() {
    _isimController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profili Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: _avatarUrlController,
              decoration:
                  const InputDecoration(labelText: "Profil Fotoğrafı URL"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _isimController,
              decoration: const InputDecoration(labelText: "Adınız"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: "Biyografi"),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            if (email != null) Text("E-posta: $email"),
            if (universiteAdi != null) Text("Üniversite: $universiteAdi"),
            if (bolumAdi != null) Text("Bölüm: $bolumAdi"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text("Değişiklikleri Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}
