import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const TapMeApp());

class TapMeApp extends StatelessWidget {
  const TapMeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Tap Me',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF757575),
            surface: const Color(0xFFF4F4F4),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF4F4F4),
        ),
        home: const ProfilePage(),
      );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _defaults = <String, String>{
    'name': 'Alvin Khoiri',
    'bio': '',
    'whatsapp': 'https://wa.me/ar/6EXVEP5EBVPBP1',
    'instagram': 'https://www.instagram.com/vinz_yc?knvt=MXJlZjJlM2FyN2pnZQ==',
    'tiktok': 'https://www.tiktok.com/@alvinxhound?_r=1&_t=ZS-9Bg7aaJVxnI',
    'profileUrl': '',
  };

  Map<String, String> _values = Map.of(_defaults);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final key in _defaults.keys) {
        _values[key] = prefs.getString(key) ?? _defaults[key]!;
      }
      _loading = false;
    });
  }

  Future<void> _save(Map<String, String> values) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in values.entries) {
      await prefs.setString(entry.key, entry.value.trim());
    }
    if (!mounted) return;
    setState(() => _values = values);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil tersimpan di perangkat ini.')),
    );
  }

  Future<void> _editProfile() async {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      for (final key in _values.keys) key: TextEditingController(text: _values[key]),
    };
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Edit profil', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _field(controllers['name']!, 'Nama'),
              _field(controllers['bio']!, 'Bio (opsional)', required: false),
              _field(controllers['whatsapp']!, 'Link WhatsApp'),
              _field(controllers['instagram']!, 'Link Instagram'),
              _field(controllers['tiktok']!, 'Link TikTok'),
              _field(controllers['profileUrl']!, 'URL profil publik untuk NFC/QR', required: false,
                  hint: 'Isi setelah halaman profil online tersedia'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, {for (final e in controllers.entries) e.key: e.value.text.trim()});
                  }
                },
                child: const Text('Simpan'),
              ),
            ]),
          ),
        ),
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (result != null) await _save(result);
  }

  Widget _field(TextEditingController controller, String label,
      {bool required = true, String? hint}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) return 'Bagian ini wajib diisi';
            if (value != null && value.trim().isNotEmpty &&
                (label.toLowerCase().contains('link') || label.toLowerCase().contains('url')) &&
                Uri.tryParse(value.trim())?.hasAbsolutePath != true) return 'Masukkan URL yang valid';
            return null;
          },
        ),
      );

  Future<void> _openLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link tidak dapat dibuka.')));
    }
  }

  Future<void> _writeNfc() async {
    final url = _values['profileUrl']!.trim();
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tambahkan URL profil HTTPS publik terlebih dahulu di Edit profil.'),
      ));
      return;
    }
    final available = await NfcManager.instance.isAvailable();
    if (!available) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NFC tidak tersedia atau belum diaktifkan.')));
      return;
    }
    await NfcManager.instance.startSession(onDiscovered: (tag) async {
      try {
        final ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          await NfcManager.instance.stopSession(errorMessage: 'Tag bukan NDEF yang dapat ditulis.');
          return;
        }
        await ndef.write(NdefMessage([NdefRecord.createUri(uri)]));
        await NfcManager.instance.stopSession();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL profil berhasil ditulis ke tag NFC.')));
      } catch (e) {
        await NfcManager.instance.stopSession(errorMessage: 'Gagal menulis tag NFC.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Tap Me'), actions: [
        IconButton(onPressed: _editProfile, tooltip: 'Edit profil', icon: const Icon(Icons.edit_outlined)),
      ]),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const CircleAvatar(radius: 42, backgroundColor: Color(0xFFE0E0E0), child: Icon(Icons.person, size: 44, color: Colors.white)),
                const SizedBox(height: 14),
                Text(_values['name']!, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                if (_values['bio']!.isNotEmpty) ...[const SizedBox(height: 6), Text(_values['bio']!, textAlign: TextAlign.center)],
                const SizedBox(height: 20),
                _socialButton('WhatsApp', Icons.chat, const Color(0xFF25D366), _values['whatsapp']!),
                _socialButton('Instagram', Icons.camera_alt_outlined, const Color(0xFFC13584), _values['instagram']!),
                _socialButton('TikTok', Icons.music_note, Colors.black, _values['tiktok']!),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: _writeNfc, icon: const Icon(Icons.nfc), label: const Text('Program tag NFC')),
          OutlinedButton.icon(
            onPressed: _values['profileUrl']!.isEmpty
                ? null
                : () => showDialog<void>(context: context, builder: (context) => AlertDialog(
                      title: const Text('QR profil'),
                      content: SizedBox(width: 240, height: 240, child: QrImageView(data: _values['profileUrl']!, version: QrVersions.auto)),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
                    )),
            icon: const Icon(Icons.qr_code_2), label: const Text('Tampilkan QR profil'),
          ),
          const SizedBox(height: 12),
          const Text('Catatan: saat ini data profil tersimpan di perangkat. URL profil publik harus tersedia agar NFC/QR dapat dibuka oleh ponsel lain.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _socialButton(String title, IconData icon, Color color, String url) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(width: double.infinity, child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: () => _openLink(url), icon: Icon(icon), label: Text(title),
        )),
      );
}
