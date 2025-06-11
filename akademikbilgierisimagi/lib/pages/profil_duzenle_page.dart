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

  final _isimController = TextEditingController();
  final _bioController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  String? email;

  @override
  void initState() {
    super.initState();
    kullaniciRef =
        FirebaseDatabase.instance.ref().child('kullanicilar/${user!.uid}');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final snapshot = await kullaniciRef.get();
    if (!snapshot.exists) return;

    final dataRaw = snapshot.value;
    if (dataRaw == null) return;

    final data = Map<String, dynamic>.from(
      (dataRaw as Map).map((key, value) => MapEntry(key.toString(), value)),
    );

    setState(() {
      _isimController.text = data['isim']?.toString() ?? '';
      _bioController.text = data['bio']?.toString() ?? '';
      _avatarUrlController.text = data['avatarUrl']?.toString() ?? '';
      email = data['email']?.toString();
    });
  }

  Future<void> _saveChanges() async {
    await kullaniciRef.update({
      'isim': _isimController.text.trim(),
      'bio': _bioController.text.trim(),
      'avatarUrl': _avatarUrlController.text.trim(),
      // Üniversite ve bölüm bilgileri güncellenmiyor
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil başarıyla güncellendi.")),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildAvatarPreview() {
    final url = _avatarUrlController.text.trim();
    if (url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.network(
          url,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 120,
              height: 120,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child:
                  const Icon(Icons.broken_image, size: 48, color: Colors.grey),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profili Düzenle"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ListView(
          children: [
            _buildAvatarPreview(),
            TextField(
              controller: _avatarUrlController,
              decoration: _inputDecoration("Profil Fotoğrafı URL"),
              keyboardType: TextInputType.url,
              onChanged: (_) {
                setState(() {}); // Fotoğraf önizlemesi güncelle
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _isimController,
              decoration: _inputDecoration("Adınız"),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bioController,
              decoration: _inputDecoration("Biyografi"),
              maxLines: 4,
            ),
            const SizedBox(height: 25),
            if (email != null && email!.isNotEmpty)
              Text(
                "E-posta: $email",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey[700]),
              ),
            const SizedBox(height: 35),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                onPressed: _saveChanges,
                child: const Text("Değişiklikleri Kaydet"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
