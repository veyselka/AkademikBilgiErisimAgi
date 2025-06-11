import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AnasayfaPage extends StatefulWidget {
  const AnasayfaPage({super.key});

  @override
  State<AnasayfaPage> createState() => _AnasayfaPageState();
}

class _AnasayfaPageState extends State<AnasayfaPage> {
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference kullaniciRef;
  late DatabaseReference takipRef;

  List<Map<String, dynamic>> takipEdilenKullanicilar = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    kullaniciRef =
        FirebaseDatabase.instance.ref().child('kullanicilar/${user!.uid}');
    takipRef = kullaniciRef.child('takip');

    _loadTakipEdilenler();
  }

  Future<void> _loadTakipEdilenler() async {
    setState(() {
      loading = true;
    });

    final takipSnapshot = await takipRef.get();
    if (!takipSnapshot.exists) {
      setState(() {
        takipEdilenKullanicilar = [];
        loading = false;
      });
      return;
    }

    final Map<dynamic, dynamic> takipData =
        takipSnapshot.value as Map<dynamic, dynamic>;
    List<String> takipEdilenIds = takipData.keys.cast<String>().toList();

    List<Map<String, dynamic>> loadedKullanicilar = [];

    for (String takipId in takipEdilenIds) {
      final kullaniciSnapshot =
          await FirebaseDatabase.instance.ref('kullanicilar/$takipId').get();
      if (kullaniciSnapshot.exists) {
        Map<String, dynamic> kullaniciMap =
            Map<String, dynamic>.from(kullaniciSnapshot.value as Map);

        // Kütüphaneler
        final kutuphaneSnapshot = await FirebaseDatabase.instance
            .ref('kullanicilar/$takipId/kutuphaneler')
            .get();
        List<Map<String, dynamic>> kutuphaneler = [];
        if (kutuphaneSnapshot.exists) {
          Map<dynamic, dynamic> kutuphaneData =
              kutuphaneSnapshot.value as Map<dynamic, dynamic>;
          kutuphaneData.forEach((key, value) {
            Map<String, dynamic> k = Map<String, dynamic>.from(value);
            k['id'] = key;
            kutuphaneler.add(k);
          });
        }

        // Gönderiler
        final gonderiSnapshot = await FirebaseDatabase.instance
            .ref('kullanici_paylasimlari/$takipId')
            .get();
        List<Map<String, dynamic>> gonderiler = [];
        if (gonderiSnapshot.exists) {
          Map<dynamic, dynamic> gonderiMap =
              gonderiSnapshot.value as Map<dynamic, dynamic>;

          for (var postId in gonderiMap.keys) {
            final postSnapshot = await FirebaseDatabase.instance
                .ref('paylasimlar/$postId')
                .get();
            if (postSnapshot.exists) {
              Map<String, dynamic> post =
                  Map<String, dynamic>.from(postSnapshot.value as Map);
              post['id'] = postId;
              gonderiler.add(post);
            }
          }
        }

        kullaniciMap['kutuphaneler'] = kutuphaneler;
        kullaniciMap['gonderiler'] = gonderiler;

        loadedKullanicilar.add(kullaniciMap);
      }
    }

    setState(() {
      takipEdilenKullanicilar = loadedKullanicilar;
      loading = false;
    });
  }

  Future<void> _toggleBegeni(String postId, bool begendiMi) async {
    final currentUserId = user!.uid;
    final begeniRef = FirebaseDatabase.instance.ref('begeni/$postId');

    if (begendiMi) {
      await begeniRef.child(currentUserId).remove();
    } else {
      await begeniRef.child(currentUserId).set(true);
    }
    setState(() {});
  }

  Widget _kutuphaneCard(Map<String, dynamic> kutuphane) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: const Icon(Icons.library_books, color: Colors.blue),
        title: Text(kutuphane['isim'] ?? 'İsimsiz Kütüphane'),
        subtitle: Text('Dosya sayısı: ${kutuphane['dosyalar']?.length ?? 0}'),
      ),
    );
  }

  Widget _gonderiCard(Map<String, dynamic> gonderi) {
    final currentUserId = user!.uid;
    final postId = gonderi['id'];

    return FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance.ref('begeni/$postId').get(),
      builder: (context, snapshot) {
        bool begendiMi = false;
        int begeniSayisi = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          Map<dynamic, dynamic> begeniMap =
              snapshot.data!.value as Map<dynamic, dynamic>;
          begeniSayisi = begeniMap.length;
          begendiMi = begeniMap.containsKey(currentUserId);
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: const Icon(Icons.post_add, color: Colors.green),
            title: Text(gonderi['content'] ?? 'Başlıksız Gönderi'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        begendiMi ? Icons.favorite : Icons.favorite_border,
                        color: begendiMi ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleBegeni(postId, begendiMi),
                    ),
                    Text('$begeniSayisi beğeni'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Yorum özelliği yakında")),
                        );
                      },
                      icon: const Icon(Icons.comment, size: 18),
                      label: const Text("Yorum yap"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (takipEdilenKullanicilar.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Henüz kimseyi takip etmiyorsunuz.\nTakip ettiklerinizin gönderi ve kütüphaneleri burada görünecek.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTakipEdilenler,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: takipEdilenKullanicilar.length,
        itemBuilder: (context, index) {
          final kullanici = takipEdilenKullanicilar[index];

          final kutuphaneler = (kullanici['kutuphaneler'] as List?) ?? [];
          final gonderiler = (kullanici['gonderiler'] as List?) ?? [];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanıcı adı ve email
                  Row(
                    children: [
                      const Icon(Icons.person, size: 28, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          kullanici['isim'] ??
                              kullanici['email'] ??
                              'Bilinmeyen Kullanıcı',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Kütüphaneler başlığı ve listesi
                  if (kutuphaneler.isNotEmpty) ...[
                    const Text(
                      'Kütüphaneler:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 4),
                    ...kutuphaneler.map((k) => _kutuphaneCard(k)).toList(),
                    const SizedBox(height: 8),
                  ],

                  // Gönderiler başlığı ve listesi
                  if (gonderiler.isNotEmpty) ...[
                    const Text(
                      'Gönderiler:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    ...gonderiler.map((g) => _gonderiCard(g)).toList(),
                  ],

                  // Kütüphane ve gönderi yoksa uyarı
                  if (kutuphaneler.isEmpty && gonderiler.isEmpty) ...[
                    const Text('Henüz paylaşım yok.'),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
