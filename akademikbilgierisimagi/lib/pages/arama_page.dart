import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AramaPage extends StatefulWidget {
  const AramaPage({super.key});

  @override
  State<AramaPage> createState() => _AramaPageState();
}

class _AramaPageState extends State<AramaPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> kullanicilar = [];
  List<Map<String, dynamic>> kutuphaneler = [];

  bool _isLoading = false;

  Future<void> _aramaYap(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        kullanicilar = [];
        kutuphaneler = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final dbRef = FirebaseDatabase.instance.ref();

    // Kullanıcı araması
    final kullaniciSnapshot = await dbRef
        .child('kullanicilar')
        .orderByChild('isim')
        .startAt(query)
        .endAt(query + '\uf8ff')
        .get();

    List<Map<String, dynamic>> bulunanKullanicilar = [];
    if (kullaniciSnapshot.exists) {
      final data = kullaniciSnapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final kullanici = Map<String, dynamic>.from(value);
        kullanici['id'] = key;
        bulunanKullanicilar.add(kullanici);
      });
    }

    // Kütüphane araması (basit şekilde)
    List<Map<String, dynamic>> bulunanKutuphaneler = [];
    final kullaniciSnapshotForKutup = await dbRef.child('kullanicilar').get();
    if (kullaniciSnapshotForKutup.exists) {
      final tumKullanicilar =
          kullaniciSnapshotForKutup.value as Map<dynamic, dynamic>;
      for (var userKey in tumKullanicilar.keys) {
        final kullaniciData = tumKullanicilar[userKey] as Map<dynamic, dynamic>;
        if (kullaniciData.containsKey('kutuphaneler')) {
          final kutuphaneData =
              kullaniciData['kutuphaneler'] as Map<dynamic, dynamic>;
          kutuphaneData.forEach((kutuphaneKey, kutuphaneValue) {
            final kutuphaneMap = Map<String, dynamic>.from(kutuphaneValue);
            kutuphaneMap['id'] = kutuphaneKey;
            kutuphaneMap['kullaniciId'] = userKey;
            final isim = (kutuphaneMap['isim'] ?? '').toString().toLowerCase();
            if (isim.contains(query.toLowerCase())) {
              bulunanKutuphaneler.add(kutuphaneMap);
            }
          });
        }
      }
    }

    setState(() {
      kullanicilar = bulunanKullanicilar;
      kutuphaneler = bulunanKutuphaneler;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildListItem(
      {required String title,
      String? subtitle,
      String? avatarUrl,
      required VoidCallback onTap}) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: avatarUrl != null && avatarUrl.isNotEmpty
            ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
            : CircleAvatar(
                backgroundColor: Colors.blue.shade300,
                child: Text(
                  title.isNotEmpty ? title[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arama'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kullanıcı veya kütüphane ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _aramaYap('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (val) {
                _aramaYap(val);
              },
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const LinearProgressIndicator(
                color: Colors.deepPurple,
                minHeight: 3,
              ),
            if (!_isLoading)
              Expanded(
                child: kullanicilar.isEmpty &&
                        kutuphaneler.isEmpty &&
                        _searchController.text.isNotEmpty
                    ? Center(
                        child: Text(
                          'Sonuç bulunamadı :(',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16),
                        ),
                      )
                    : ListView(
                        children: [
                          if (kullanicilar.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6, left: 6),
                              child: Text(
                                'Kullanıcılar',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ...kullanicilar.map((k) => _buildListItem(
                                title: k['isim'],
                                subtitle: k['email'],
                                avatarUrl: k['avatarUrl'] ?? '',
                                onTap: () {
                                  // TODO: Profil sayfasına git
                                },
                              )),
                          if (kutuphaneler.isNotEmpty)
                            const Padding(
                              padding:
                                  EdgeInsets.only(top: 12, bottom: 6, left: 6),
                              child: Text(
                                'Kütüphaneler',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ...kutuphaneler.map((k) => _buildListItem(
                                title: k['isim'],
                                subtitle: 'Sahibi: ${k['kullaniciId']}',
                                onTap: () {
                                  // TODO: Kütüphane detayına git
                                },
                              )),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
