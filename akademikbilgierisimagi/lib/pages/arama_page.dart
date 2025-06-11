import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AramaPage extends StatefulWidget {
  const AramaPage({super.key});

  @override
  State<AramaPage> createState() => _AramaPageState();
}

class _AramaPageState extends State<AramaPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> bulunanKullanicilar = [];
  Map<String, String> takipDurumlari = {};
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _aramaYap(String query) async {
    if (query.isEmpty) {
      setState(() {
        bulunanKullanicilar = [];
        takipDurumlari = {};
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final dbRef = FirebaseDatabase.instance.ref();
    final kullaniciRef = dbRef.child('kullanicilar');
    final takipRef = dbRef.child('kullanici_takipleri');
    final currentUserId = _auth.currentUser?.uid;

    try {
      final snapshot = await kullaniciRef.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        final filtrelenmis = data.entries.where((entry) {
          final user = Map<String, dynamic>.from(entry.value);
          final isim = (user['isim'] ?? '').toString().toLowerCase();
          return isim.contains(query.toLowerCase());
        }).map((entry) {
          final user = Map<String, dynamic>.from(entry.value);
          user['id'] = entry.key;
          return user;
        }).toList();

        Map<String, dynamic> takipEdilenler = {};
        if (currentUserId != null) {
          final takipSnapshot = await takipRef.child(currentUserId).get();
          if (takipSnapshot.exists) {
            takipEdilenler =
                Map<String, dynamic>.from(takipSnapshot.value as Map);
          }
        }

        Map<String, String> durumlar = {};
        for (var kullanici in filtrelenmis) {
          final id = kullanici['id'];
          if (id == currentUserId) {
            durumlar[id] = 'kendisi';
          } else if (takipEdilenler.containsKey(id)) {
            durumlar[id] = 'takipte';
          } else {
            durumlar[id] = 'takip_et';
          }
        }

        setState(() {
          bulunanKullanicilar = filtrelenmis;
          takipDurumlari = durumlar;
        });
      }
    } catch (e) {
      debugPrint("Hata: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _takipEt(String takipEdilecekId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final dbRef = FirebaseDatabase.instance.ref();

    try {
      // 1. takip_edilenler/{currentUserId}/{hedefUserId}
      await dbRef
          .child('takip_edilenler/$currentUserId/$takipEdilecekId')
          .set(true);

      // 2. kullanici_takipciler/{hedefUserId}/{currentUserId}
      await dbRef
          .child('kullanici_takipciler/$takipEdilecekId/$currentUserId')
          .set(true);

      setState(() {
        takipDurumlari[takipEdilecekId] = 'takipte';
      });
    } catch (e) {
      debugPrint("Takip etme hatası: $e");
    }
  }

  Future<void> _takipBirak(String takipEdilenId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final dbRef = FirebaseDatabase.instance.ref();

    try {
      // 1. takip_edilenler/{currentUserId}/{hedefUserId}
      await dbRef
          .child('takip_edilenler/$currentUserId/$takipEdilenId')
          .remove();

      // 2. kullanici_takipciler/{hedefUserId}/{currentUserId}
      await dbRef
          .child('kullanici_takipciler/$takipEdilenId/$currentUserId')
          .remove();

      setState(() {
        takipDurumlari[takipEdilenId] = 'takip_et';
      });
    } catch (e) {
      debugPrint("Takipten çıkma hatası: $e");
    }
  }

  void _profilSayfasinaGit(Map<String, dynamic> kullanici) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KullaniciProfilSayfasi(kullanici: kullanici),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kullanıcı Ara"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "İsim ile ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: _aramaYap,
            ),
            const SizedBox(height: 12),
            if (_isLoading) const LinearProgressIndicator(minHeight: 3),
            if (!_isLoading)
              Expanded(
                child: bulunanKullanicilar.isEmpty
                    ? const Center(child: Text("Sonuç bulunamadı."))
                    : ListView.builder(
                        itemCount: bulunanKullanicilar.length,
                        itemBuilder: (context, index) {
                          final kullanici = bulunanKullanicilar[index];
                          final kullaniciId = kullanici['id'];
                          final durum =
                              takipDurumlari[kullaniciId] ?? 'takip_et';

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: kullanici['avatarUrl'] != null
                                    ? NetworkImage(kullanici['avatarUrl'])
                                    : null,
                                child: kullanici['avatarUrl'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(kullanici['isim'] ?? ''),
                              subtitle: Text(kullanici['email'] ?? ''),
                              trailing: durum == 'kendisi'
                                  ? null
                                  : durum == 'takipte'
                                      ? TextButton(
                                          onPressed: () =>
                                              _takipBirak(kullaniciId),
                                          child: const Text('Takibi Bırak'),
                                        )
                                      : TextButton(
                                          onPressed: () =>
                                              _takipEt(kullaniciId),
                                          child: const Text('Takip Et'),
                                        ),
                              onTap: () => _profilSayfasinaGit(kullanici),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class KullaniciProfilSayfasi extends StatelessWidget {
  final Map<String, dynamic> kullanici;
  const KullaniciProfilSayfasi({super.key, required this.kullanici});

  Future<String> _getUniversiteAdi(String uniId) async {
    final ref = FirebaseDatabase.instance.ref('universiteler/$uniId/name');
    final snapshot = await ref.get();
    return snapshot.exists ? snapshot.value.toString() : 'Bilinmiyor';
  }

  Future<String> _getBolumAdi(String uniId, String bolumId) async {
    final ref = FirebaseDatabase.instance
        .ref('universiteler/$uniId/bolumler/$bolumId/name');
    final snapshot = await ref.get();
    return snapshot.exists ? snapshot.value.toString() : 'Bilinmiyor';
  }

  @override
  Widget build(BuildContext context) {
    final uniId = kullanici['universiteId'] ?? '';
    final bolumId = kullanici['bolumId'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(kullanici['isim'] ?? 'Profil'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: kullanici['avatarUrl'] != null
                  ? NetworkImage(kullanici['avatarUrl'])
                  : null,
              child: kullanici['avatarUrl'] == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(kullanici['isim'] ?? '', style: const TextStyle(fontSize: 22)),
            Text(kullanici['email'] ?? '',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _getUniversiteAdi(uniId),
              builder: (context, snapshot) => Text(
                "Üniversite: ${snapshot.data ?? ''}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            FutureBuilder<String>(
              future: _getBolumAdi(uniId, bolumId),
              builder: (context, snapshot) => Text(
                "Bölüm: ${snapshot.data ?? ''}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
