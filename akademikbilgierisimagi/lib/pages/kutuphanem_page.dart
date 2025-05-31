import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class KutuphanemPage extends StatefulWidget {
  const KutuphanemPage({super.key});

  @override
  State<KutuphanemPage> createState() => _KutuphanemPageState();
}

class _KutuphanemPageState extends State<KutuphanemPage> {
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference kullaniciRef;
  late DatabaseReference kutuphaneRef;

  List<Map<String, dynamic>> kutuphaneler = [];

  @override
  void initState() {
    super.initState();
    kullaniciRef =
        FirebaseDatabase.instance.ref().child('kullanicilar/${user!.uid}');
    kutuphaneRef = kullaniciRef.child('kutuphaneler');
    _loadKutuphaneler();
  }

  Future<void> _loadKutuphaneler() async {
    final snapshot = await kutuphaneRef.get();
    if (!snapshot.exists) {
      setState(() {
        kutuphaneler = [];
      });
      return;
    }

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    final List<Map<String, dynamic>> loaded = [];

    data.forEach((key, value) {
      final kutuphaneMap = Map<String, dynamic>.from(value);
      kutuphaneMap['id'] = key;
      loaded.add(kutuphaneMap);
    });

    setState(() {
      kutuphaneler = loaded;
    });
  }

  Future<void> _yeniKutuphaneOlustur() async {
    String yeniAdi = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Kütüphane Oluştur'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Kütüphane adı',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) => yeniAdi = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (yeniAdi.trim().isNotEmpty) {
                Navigator.pop(context);
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (yeniAdi.trim().isEmpty) return;

    final yeniKutuphaneRef = kutuphaneRef.push();
    await yeniKutuphaneRef.set({
      'isim': yeniAdi.trim(),
      'dosyalar': {},
    });

    _loadKutuphaneler();
  }

  void _goToKutuphaneDetay(Map<String, dynamic> kutuphane) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KutuphaneDetayPage(
          kutuphaneId: kutuphane['id'],
          kutuphaneAdi: kutuphane['isim'],
        ),
      ),
    ).then((_) => _loadKutuphaneler());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kütüphanem'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Kütüphane Oluştur',
            onPressed: _yeniKutuphaneOlustur,
          ),
        ],
      ),
      body: kutuphaneler.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.library_books,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz kütüphane yok.',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  Text(
                    '+ butonuna tıklayarak oluşturabilirsiniz.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.builder(
                itemCount: kutuphaneler.length,
                itemBuilder: (context, index) {
                  final kutuphane = kutuphaneler[index];
                  return Card(
                    elevation: 4,
                    shadowColor: Colors.blue.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      title: Text(
                        kutuphane['isim'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                      onTap: () => _goToKutuphaneDetay(kutuphane),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class KutuphaneDetayPage extends StatefulWidget {
  final String kutuphaneId;
  final String kutuphaneAdi;

  const KutuphaneDetayPage({
    super.key,
    required this.kutuphaneId,
    required this.kutuphaneAdi,
  });

  @override
  State<KutuphaneDetayPage> createState() => _KutuphaneDetayPageState();
}

class _KutuphaneDetayPageState extends State<KutuphaneDetayPage> {
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference dosyalarRef;

  List<Map<String, dynamic>> dosyalar = [];

  @override
  void initState() {
    super.initState();
    dosyalarRef = FirebaseDatabase.instance.ref().child(
        'kullanicilar/${user!.uid}/kutuphaneler/${widget.kutuphaneId}/dosyalar');
    _loadDosyalar();
  }

  Future<void> _loadDosyalar() async {
    final snapshot = await dosyalarRef.get();
    if (!snapshot.exists) {
      setState(() {
        dosyalar = [];
      });
      return;
    }

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    final List<Map<String, dynamic>> loaded = [];

    data.forEach((key, value) {
      final dosyaMap = Map<String, dynamic>.from(value);
      dosyaMap['id'] = key;
      loaded.add(dosyaMap);
    });

    setState(() {
      dosyalar = loaded;
    });
  }

  Widget _dosyaIcon(String tur) {
    switch (tur.toLowerCase()) {
      case 'pdf':
        return Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 36);
      case 'ppt':
      case 'pptx':
        return Icon(Icons.slideshow, color: Colors.orange.shade700, size: 36);
      case 'doc':
      case 'docx':
        return Icon(Icons.description, color: Colors.blue.shade700, size: 36);
      case 'xls':
      case 'xlsx':
        return Icon(Icons.table_chart, color: Colors.green.shade700, size: 36);
      default:
        return Icon(Icons.insert_drive_file,
            size: 36, color: Colors.grey.shade600);
    }
  }

  Future<void> _dosyaEkle() async {
    String dosyaAdi = '';
    String dosyaTuru = '';
    String dosyaUrl = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dosya Ekle'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Dosya Adı',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (val) => dosyaAdi = val,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Dosya Türü (pdf, ppt, doc, xls vb.)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (val) => dosyaTuru = val,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Dosya URL',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (val) => dosyaUrl = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (dosyaAdi.trim().isNotEmpty &&
                  dosyaTuru.trim().isNotEmpty &&
                  dosyaUrl.trim().isNotEmpty) {
                Navigator.pop(context);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (dosyaAdi.trim().isEmpty ||
        dosyaTuru.trim().isEmpty ||
        dosyaUrl.trim().isEmpty) return;

    final yeniDosyaRef = dosyalarRef.push();
    await yeniDosyaRef.set({
      'ad': dosyaAdi.trim(),
      'tur': dosyaTuru.trim().toLowerCase(),
      'url': dosyaUrl.trim(),
    });

    _loadDosyalar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kutuphaneAdi),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Dosya Ekle',
            onPressed: _dosyaEkle,
          )
        ],
      ),
      body: dosyalar.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz dosya eklenmemiş.',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  Text(
                    '+ butonuna tıklayarak dosya ekleyebilirsiniz.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.builder(
                itemCount: dosyalar.length,
                itemBuilder: (context, index) {
                  final dosya = dosyalar[index];
                  return Card(
                    elevation: 4,
                    shadowColor: Colors.blue.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      leading: _dosyaIcon(dosya['tur']),
                      title: Text(
                        dosya['ad'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      subtitle: Text(dosya['tur'].toUpperCase(),
                          style: TextStyle(color: Colors.grey.shade600)),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new, color: Colors.blue),
                        tooltip: 'Dosyayı Aç',
                        onPressed: () {
                          // İstersen dosya url açılabilir.
                          // launch(dosya['url']) gibi
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
