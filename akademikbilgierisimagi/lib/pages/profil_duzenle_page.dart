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

  String? seciliUniversiteId;
  String? seciliBolumId;

  String? universiteAdi;
  String? bolumAdi;

  Map<String, dynamic> universitelerMap = {};
  Map<String, dynamic> bolumlerMap = {};

  @override
  void initState() {
    super.initState();
    kullaniciRef =
        FirebaseDatabase.instance.ref().child('kullanicilar/${user!.uid}');
    universiteRef = FirebaseDatabase.instance.ref().child('universiteler');
    _loadUniversiteler();
    _loadUserData();
  }

  Future<void> _loadUniversiteler() async {
    final snapshot = await universiteRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    setState(() {
      universitelerMap = data;
    });
  }

  Future<void> _loadUserData() async {
    final snapshot = await kullaniciRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    final String? uniId = data['universiteId']?.toString();
    final String? bolumId = data['bolumId']?.toString();

    setState(() {
      _isimController.text = data['isim']?.toString() ?? '';
      _bioController.text = data['bio']?.toString() ?? '';
      _avatarUrlController.text = data['avatarUrl']?.toString() ?? '';
      email = data['email']?.toString();
      seciliUniversiteId = uniId;
      seciliBolumId = bolumId;
    });

    if (seciliUniversiteId != null) {
      await _loadBolumler(seciliUniversiteId!);
    }

    if (universitelerMap.isNotEmpty) {
      setState(() {
        universiteAdi =
            universitelerMap[seciliUniversiteId]?['name']?.toString() ?? '';
        bolumAdi = bolumlerMap[seciliBolumId]?['name']?.toString() ?? '';
      });
    }
  }

  Future<void> _loadBolumler(String universiteId) async {
    final snapshot = await universiteRef.child('$universiteId/bolumler').get();
    if (!snapshot.exists) {
      setState(() {
        bolumlerMap = {};
        seciliBolumId = null;
        bolumAdi = null;
      });
      return;
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    setState(() {
      bolumlerMap = data;

      if (!bolumlerMap.containsKey(seciliBolumId)) {
        seciliBolumId = null;
        bolumAdi = null;
      } else {
        bolumAdi = bolumlerMap[seciliBolumId]?['name']?.toString();
      }
    });
  }

  Future<void> _saveChanges() async {
    if (seciliUniversiteId == null || seciliBolumId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen üniversite ve bölüm seçiniz.")),
      );
      return;
    }

    await kullaniciRef.update({
      'isim': _isimController.text.trim(),
      'bio': _bioController.text.trim(),
      'avatarUrl': _avatarUrlController.text.trim(),
      'universiteId': seciliUniversiteId,
      'bolumId': seciliBolumId,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil başarıyla güncellendi.")),
      );
      Navigator.pop(context);
    }
  }

  // Profil foto URL geçerliyse önizleme göster
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
            const SizedBox(height: 25),
            // Üniversite Dropdown
            universitelerMap.isNotEmpty
                ? DropdownButtonFormField<String>(
                    decoration: _inputDecoration("Üniversite"),
                    value: universitelerMap.containsKey(seciliUniversiteId)
                        ? seciliUniversiteId
                        : null,
                    items: universitelerMap.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value['name']?.toString() ?? ''),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() {
                        seciliUniversiteId = value;
                        seciliBolumId = null;
                        bolumlerMap = {};
                        bolumAdi = null;
                      });
                      await _loadBolumler(value);
                    },
                  )
                : const Text("Üniversite verisi yok"),
            const SizedBox(height: 25),
            // Bölüm Dropdown
            bolumlerMap.isNotEmpty
                ? DropdownButtonFormField<String>(
                    decoration: _inputDecoration("Bölüm"),
                    value: bolumlerMap.containsKey(seciliBolumId)
                        ? seciliBolumId
                        : null,
                    items: bolumlerMap.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value['name']?.toString() ?? ''),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        seciliBolumId = value;
                        bolumAdi = bolumlerMap[value]?['name']?.toString();
                      });
                    },
                  )
                : const Text("Bölüm verisi yok"),
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
