import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'screen/add.dart'; // SayacEklemeSayfasi için
import 'screen/settings.dart'; // AyarlarSayfasi için

class Sayac {
  final String id;
  final String isim;
  final DateTime tarihSaat;
  final String kategori;
  final Color? flatColor;
  final List<Color>? gradientColors;
  final String? not;
  final IconData? categoryIcon;

  Sayac({
    required this.id,
    required this.isim,
    required this.tarihSaat,
    required this.kategori,
    this.flatColor,
    this.gradientColors,
    this.not,
    this.categoryIcon,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isim': isim,
      'tarihSaat': tarihSaat.toIso8601String(),
      'kategori': kategori,
      'flatColor': flatColor?.value,
      'gradientColors': gradientColors?.map((color) => color.value).toList(),
      'not': not,
      'categoryIcon': categoryIcon?.codePoint,
    };
  }

  factory Sayac.fromJson(Map<String, dynamic> json) {
    DateTime tarihSaat;
    try {
      tarihSaat = DateTime.parse(json['tarihSaat']);
    } catch (e) {
      tarihSaat = DateTime.now();
    }

    return Sayac(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      isim: json['isim'] ?? 'Bilinmeyen',
      tarihSaat: tarihSaat,
      kategori: json['kategori'] ?? 'Diğer',
      flatColor: json['flatColor'] != null ? Color(json['flatColor']) : null,
      gradientColors: json['gradientColors'] != null
          ? (json['gradientColors'] as List).map((value) => Color(value)).toList()
          : null,
      not: json['not'],
      categoryIcon: json['categoryIcon'] != null
          ? IconData(json['categoryIcon'], fontFamily: 'MaterialIcons')
          : null,
    );
  }

  static Sayac ornekSayac() {
    return Sayac(
      id: '1',
      isim: 'Yaz Tatili',
      tarihSaat: DateTime(2025, 7, 1, 9, 0),
      kategori: 'Etkinlik',
      flatColor: Color(0xFFFF8C00),
      categoryIcon: Icons.event,
      not: 'Denize gitmeyi unutma!',
    );
  }
}

class TemaYonetici extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  TemaYonetici() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TemaYonetici(),
      child: GeriSayimApp(),
    ),
  );
}

class GeriSayimApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final temaYonetici = Provider.of<TemaYonetici>(context);
    return MaterialApp(
      title: 'Geri Sayım',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      themeMode: temaYonetici._themeMode,
      home: AnaSayfa(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AnaSayfa extends StatefulWidget {
  @override
  _AnaSayfaState createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<Sayac> sayaclar = [];

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final String? sayaclarJson = prefs.getString('sayaclar');
      if (sayaclarJson != null) {
        final List<dynamic> decoded = jsonDecode(sayaclarJson);
        setState(() {
          sayaclar = decoded.map((json) => Sayac.fromJson(json)).toList();
        });
      } else {
        final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
        if (isFirstLaunch) {
          _ornekVerileriYukle();
          await prefs.setBool('isFirstLaunch', false);
        }
      }
    } catch (e) {
      setState(() {
        sayaclar = [];
      });
    }
  }

  Future<void> _verileriKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sayaclar', jsonEncode(sayaclar.map((sayac) => sayac.toJson()).toList()));
  }

  void _ornekVerileriYukle() {
    sayaclar = [
      Sayac.ornekSayac(),
    ];
    _verileriKaydet();
  }

  void _yeniSayacEkle(Sayac yeniSayac) {
    setState(() {
      sayaclar.add(yeniSayac);
      _verileriKaydet();
    });
  }

  void _sayaciSil(Sayac sayac) {
    setState(() {
      sayaclar.removeWhere((s) => s.id == sayac.id);
      _verileriKaydet();
    });
  }

  // Yeni fonksiyon: Tüm sayaçları temizle
  void _tumSayaclariTemizle() {
    setState(() {
      sayaclar.clear();
      _verileriKaydet(); // Sayaçlar listesi temizlendikten sonra SharedPreferences'ı güncelle
    });
  }

  void _sayacMenuGoster(BuildContext context, Sayac sayac) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _sayaciSilOnay(sayac);
              },
            ),
          ],
        );
      },
    );
  }

  void _sayaciSilOnay(Sayac sayac) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sayacı Sil'),
          content: Text('${sayac.isim} sayacını silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _sayaciSil(sayac);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geri Sayım'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AyarlarSayfasi()),
              ).then((result) {
                // Ayarlar sayfasından dönüldüğünde, temizleme işlemi yapıldıysa sayaçları güncelle
                if (result == 'temizle') {
                  _tumSayaclariTemizle();
                }
              });
            },
          ),
        ],
      ),
      body: sayaclar.isEmpty ? _bosEkranWidgeti() : _listeGorunumu(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SayacEklemeSayfasi()),
          ).then((yeniSayac) {
            if (yeniSayac != null) {
              _yeniSayacEkle(yeniSayac);
            }
          });
        },
      ),
    );
  }

  Widget _bosEkranWidgeti() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_off, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            "Henüz sayaç bulunmuyor",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            "İlk sayacını eklemek için + düğmesine bas",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }




  Widget _listeGorunumu() {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: sayaclar.length,
      itemBuilder: (context, index) {
        final sayac = sayaclar[index];
        final kalanSure = sayac.tarihSaat.difference(DateTime.now());
        final dateFormat = DateFormat('dd/MM/yyyy');

        final gunler = kalanSure.inDays;
        final saatler = kalanSure.inHours % 24;
        final dakikalar = kalanSure.inMinutes % 60;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: sayac.gradientColors != null
                  ? LinearGradient(colors: sayac.gradientColors!)
                  : null,
              color: sayac.flatColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(sayac.categoryIcon ?? Icons.event),
              ),
              title: Text(
                sayac.isim,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTimeUnit(gunler, 'gün'),
                      SizedBox(width: 12),
                      _buildTimeUnit(saatler, 'saat'),
                      SizedBox(width: 12),
                      _buildTimeUnit(dakikalar, 'dakika'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    dateFormat.format(sayac.tarihSaat),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _sayacMenuGoster(context, sayac),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeUnit(int value, String unit) {
    return Row(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 4),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 23,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
