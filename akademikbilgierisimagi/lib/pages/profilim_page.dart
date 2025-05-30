import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'profil_duzenle_page.dart';
import '../login_page.dart';

class ProfilimPage extends StatefulWidget {
  const ProfilimPage({super.key});

  @override
  State<ProfilimPage> createState() => _ProfilimPageState();
}

class _ProfilimPageState extends State<ProfilimPage> {
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference kullaniciRef;
  late DatabaseReference universiteRef;
  late DatabaseReference paylasimRef;
  late DatabaseReference takipciRef;

  Map<String, dynamic>? userData;
  String? universiteAdi;
  String? bolumAdi;

  int gonderiSayisi = 0;
  int takipciSayisi = 0;

  @override
  void initState() {
    super.initState();
    final uid = user!.uid;

    kullaniciRef = FirebaseDatabase.instance.ref().child('kullanicilar/$uid');
    universiteRef = FirebaseDatabase.instance.ref().child('universiteler');
    paylasimRef =
        FirebaseDatabase.instance.ref().child('kullanici_paylasimlari/$uid');
    takipciRef =
        FirebaseDatabase.instance.ref().child('kullanici_takipciler/$uid');

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final snapshot = await kullaniciRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final String? uniId = data['universite'];
    final String? bolumId = data['bolum'];

    final uniSnapshot = await universiteRef.child(uniId ?? '').get();
    final bolumSnapshot =
        await universiteRef.child('$uniId/bolumler/$bolumId').get();

    final paylasimSnapshot = await paylasimRef.get();
    final takipciSnapshot = await takipciRef.get();

    setState(() {
      userData = data;
      universiteAdi = uniSnapshot.child('name').value as String?;
      bolumAdi = bolumSnapshot.child('name').value as String?;
      gonderiSayisi = paylasimSnapshot.children.length;
      takipciSayisi = takipciSnapshot.children.length;
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

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                    const SizedBox(width: 40),
                    _buildStat("Takipçi", takipciSayisi),
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
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _sifreSifirla,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text("Şifreyi Sıfırla"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          "$value",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
