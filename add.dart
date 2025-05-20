import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart'; // Sayac sınıfı için

class SayacEklemeSayfasi extends StatefulWidget {
  @override
  _SayacEklemeSayfasiState createState() => _SayacEklemeSayfasiState();
}

class _SayacEklemeSayfasiState extends State<SayacEklemeSayfasi> {
  final _sayacAdiController = TextEditingController();
  final _notController = TextEditingController();
  DateTime? _selectedDateTime;
  String? _selectedKategori;
  Color? _selectedFlatColor;
  List<Color>? _selectedGradient;

  final _kategoriler = [
    {'ad': 'Doğum Günü', 'ikon': Icons.cake},
    {'ad': 'Toplantı', 'ikon': Icons.business_center},
    {'ad': 'Etkinlik', 'ikon': Icons.event},
    {'ad': 'Diğer', 'ikon': Icons.more_horiz},
  ];

  final _duzRenkler = [
    Color(0xFF5A60F3),
    Color(0xFF9ACD32),
    Color(0xFFFF8C00),
    Color(0xFF20B2AA),
  ];

  final _gradyanlar = [
    [Colors.blue, Colors.black],
    [Colors.purple, Colors.pink],
    [Colors.teal, Colors.greenAccent],
  ];

  @override
  void dispose() {
    _sayacAdiController.dispose();
    _notController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
      );
      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        if (newDateTime.isBefore(now)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Geçmiş bir tarih seçilemez')),
          );
          return;
        }
        setState(() {
          _selectedDateTime = newDateTime;
        });
      }
    }
  }

  void _sayacEkle() {
    if (_sayacAdiController.text.isEmpty ||
        _selectedDateTime == null ||
        _selectedKategori == null ||
        (_selectedFlatColor == null && _selectedGradient == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm zorunlu alanları doldurun')),
      );
      return;
    }

    IconData? categoryIcon;
    for (var kategori in _kategoriler) {
      if (kategori['ad'] == _selectedKategori) {
        categoryIcon = kategori['ikon'] as IconData;
        break;
      }
    }

    final yeniSayac = Sayac(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isim: _sayacAdiController.text,
      tarihSaat: _selectedDateTime!,
      kategori: _selectedKategori!,
      flatColor: _selectedFlatColor,
      gradientColors: _selectedGradient,
      not: _notController.text,
      categoryIcon: categoryIcon,
    );

    Navigator.pop(context, yeniSayac);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: Text('Yeni Sayaç Ekle')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _sayacAdiController,
              decoration: InputDecoration(labelText: 'Sayaç Adı'),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: _selectDateTime,
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(labelText: 'Tarih ve Saat'),
                  controller: TextEditingController(
                    text: _selectedDateTime != null ? dateFormat.format(_selectedDateTime!) : '',
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedKategori,
              decoration: InputDecoration(labelText: 'Kategori'),
              items: _kategoriler.map((k) {
                return DropdownMenuItem<String>(
                  value: k['ad'] as String,
                  child: Text(k['ad'] as String),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedKategori = value),
            ),
            SizedBox(height: 16),
            Text('Düz Renkler'),
            Wrap(
              spacing: 10,
              children: _duzRenkler.map((renk) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFlatColor = renk;
                      _selectedGradient = null;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: renk,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedFlatColor == renk ? Colors.black : Colors.transparent,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Text('Gradyan Renkler'),
            Wrap(
              spacing: 10,
              children: _gradyanlar.map((renkler) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGradient = renkler;
                      _selectedFlatColor = null;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: renkler),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedGradient == renkler ? Colors.black : Colors.transparent,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _notController,
              decoration: InputDecoration(labelText: 'Not'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sayacEkle,
              child: Text('Sayaç Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}