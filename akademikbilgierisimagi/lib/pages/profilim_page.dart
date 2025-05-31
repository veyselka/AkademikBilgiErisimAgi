import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'profil_duzenle_page.dart';
import '../login_page.dart';

// Takipçi Listesi Sayfası
class TakipcilerPage extends StatelessWidget {
  final String uid;
  const TakipcilerPage({required this.uid, super.key});

  @override
  Widget build(BuildContext context) {
    final takipciRef =
        FirebaseDatabase.instance.ref('kullanici_takipciler/$uid');
    return Scaffold(
      appBar: AppBar(title: const Text("Takipçiler")),
      body: StreamBuilder(
        stream: takipciRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Takipçi yok"));
          }
          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final takipciUids = data.keys.toList();
          return ListView.builder(
            itemCount: takipciUids.length,
            itemBuilder: (context, index) {
              final takipciUid = takipciUids[index];
              return ListTile(
                title: Text(takipciUid),
              );
            },
          );
        },
      ),
    );
  }
}

// Takip Edilenler Listesi Sayfası
class TakipEdilenlerPage extends StatelessWidget {
  final String uid;
  const TakipEdilenlerPage({required this.uid, super.key});

  @override
  Widget build(BuildContext context) {
    final takipEdilenRef =
        FirebaseDatabase.instance.ref('kullanici_takipler/$uid');
    return Scaffold(
      appBar: AppBar(title: const Text("Takip Edilenler")),
      body: StreamBuilder(
        stream: takipEdilenRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Takip edilen yok"));
          }
          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final takipEdilenUids = data.keys.toList();
          return ListView.builder(
            itemCount: takipEdilenUids.length,
            itemBuilder: (context, index) {
              final takipEdilenUid = takipEdilenUids[index];
              return ListTile(
                title: Text(takipEdilenUid),
              );
            },
          );
        },
      ),
    );
  }
}

class ProfilimPage extends StatefulWidget {
  const ProfilimPage({super.key});

  @override
  State<ProfilimPage> createState() => _ProfilimPageState();
}

class _ProfilimPageState extends State<ProfilimPage> {
  final user = FirebaseAuth.instance.currentUser!;
  late DatabaseReference kullaniciRef;
  late DatabaseReference universiteRef;
  late DatabaseReference paylasimRef;
  late DatabaseReference takipciRef;
  late DatabaseReference takiplerRef;

  Map<String, dynamic>? userData;
  String? universiteAdi;
  String? bolumAdi;

  int gonderiSayisi = 0;
  int takipciSayisi = 0;
  int takipEdilenSayisi = 0;

  bool isFollowing = false;

  @override
  void initState() {
    super.initState();

    kullaniciRef =
        FirebaseDatabase.instance.ref().child('kullanicilar/${user.uid}');
    universiteRef = FirebaseDatabase.instance.ref().child('universiteler');
    paylasimRef = FirebaseDatabase.instance
        .ref()
        .child('kullanici_paylasimlari/${user.uid}');
    takipciRef = FirebaseDatabase.instance
        .ref()
        .child('kullanici_takipciler/${user.uid}');
    takiplerRef =
        FirebaseDatabase.instance.ref().child('kullanici_takipler/${user.uid}');

    _loadUserData();
    _listenTakipciSayisi();
    _listenTakipEdilenSayisi();
    _checkIfFollowing();
  }

  Future<void> _loadUserData() async {
    final snapshot = await kullaniciRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final String? uniId = data['universiteId'] ?? data['universite'];
    final String? bolumId = data['bolumId'] ?? data['bolum'];

    final uniSnapshot = await universiteRef.child(uniId ?? '').get();
    final bolumSnapshot =
        await universiteRef.child('$uniId/bolumler/$bolumId').get();

    final paylasimSnapshot = await paylasimRef.get();

    setState(() {
      userData = data;
      universiteAdi = uniSnapshot.child('name').value as String?;
      bolumAdi = bolumSnapshot.child('name').value as String?;
      gonderiSayisi = paylasimSnapshot.children.length;
    });
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _sifreSifirla() {
    final email = userData?['email'];
    if (email != null && email.toString().contains('@')) {
      FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre sıfırlama e-postası gönderildi.')),
      );
    }
  }

  void _checkIfFollowing() async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    if (currentUserUid == user.uid) {
      setState(() {
        isFollowing = false;
      });
      return;
    }

    final currentUserTakiplerRef = FirebaseDatabase.instance
        .ref('kullanici_takipler/$currentUserUid/${user.uid}');
    final snapshot = await currentUserTakiplerRef.get();
    setState(() {
      isFollowing = snapshot.exists;
    });
  }

  void _toggleFollow() async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final takipciRefForUser = FirebaseDatabase.instance
        .ref('kullanici_takipciler/${user.uid}/$currentUserUid');
    final takiplerRefForCurrentUser = FirebaseDatabase.instance
        .ref('kullanici_takipler/$currentUserUid/${user.uid}');

    if (isFollowing) {
      // Takipten çık
      await takipciRefForUser.remove();
      await takiplerRefForCurrentUser.remove();
    } else {
      // Takip et
      await takipciRefForUser.set(true);
      await takiplerRefForCurrentUser.set(true);
    }
    setState(() {
      isFollowing = !isFollowing;
    });
  }

  void _listenTakipciSayisi() {
    final takipciCountRef =
        FirebaseDatabase.instance.ref('kullanici_takipciler/${user.uid}');
    takipciCountRef.onValue.listen((event) {
      final data = event.snapshot.value;
      setState(() {
        takipciSayisi = (data != null && data is Map) ? data.length : 0;
      });
    });
  }

  void _listenTakipEdilenSayisi() {
    final takipEdilenCountRef =
        FirebaseDatabase.instance.ref('kullanici_takipler/${user.uid}');
    takipEdilenCountRef.onValue.listen((event) {
      final data = event.snapshot.value;
      setState(() {
        takipEdilenSayisi = (data != null && data is Map) ? data.length : 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final isOwnProfile = currentUserUid == user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilim"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Çıkış Yap",
            onPressed: _signOut,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(userData!['avatarUrl'] ?? ''),
                ),
                const SizedBox(height: 16),
                Text(
                  userData!['isim'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userData!['email'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStat("Gönderi", gonderiSayisi),
                    const SizedBox(width: 30),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TakipcilerPage(uid: user.uid)),
                        );
                      },
                      child: _buildStat("Takipçi", takipciSayisi),
                    ),
                    const SizedBox(width: 30),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  TakipEdilenlerPage(uid: user.uid)),
                        );
                      },
                      child: _buildStat("Takip Edilen", takipEdilenSayisi),
                    ),
                    if (!isOwnProfile) ...[
                      const SizedBox(width: 30),
                      ElevatedButton(
                        onPressed: _toggleFollow,
                        child: Text(isFollowing ? "Takipten Çık" : "Takip Et"),
                      )
                    ]
                  ],
                ),
                const Divider(height: 32, thickness: 1),
                ListTile(
                  leading: const Icon(Icons.school),
                  title: Text(universiteAdi ?? '-'),
                  subtitle: const Text("Üniversite"),
                ),
                ListTile(
                  leading: const Icon(Icons.computer),
                  title: Text(bolumAdi ?? '-'),
                  subtitle: const Text("Bölüm"),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(userData!['bio'] ?? 'Henüz bio eklenmedi.'),
                  subtitle: const Text("Biyografi"),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfilDuzenlePage()),
                    ).then((_) => _loadUserData());
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Profili Düzenle"),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _sifreSifirla,
                  child: const Text("Şifre Sıfırla"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bu fonksiyon stat widget'larını döndürür
  Widget _buildStat(String baslik, int sayi) {
    return Column(
      children: [
        Text(
          sayi.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          baslik,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
