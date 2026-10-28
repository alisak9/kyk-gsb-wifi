import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/secure_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tcController = TextEditingController();
  final _passController = TextEditingController();
  final _portalController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _autoConnect = false;
  bool _isLoading = true;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = context.read<SecureStorageService>();
    final tc = await storage.getTcKimlik() ?? '';
    final pass = await storage.getPassword() ?? '';
    final auto = await storage.isAutoConnectEnabled();
    final portal = await storage.getPortalUrl();

    setState(() {
      _tcController.text = tc;
      _passController.text = pass;
      _autoConnect = auto;
      _portalController.text = portal;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final storage = context.read<SecureStorageService>();
    await storage.saveCredentials(_tcController.text, _passController.text);
    await storage.setAutoConnect(_autoConnect);
    await storage.setPortalUrl(_portalController.text);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('Giriş bilgileri güvenli kasaya kaydedildi!'),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _clearCredentials() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bilgileri Sil'),
        content: const Text('Kayıtlı T.C. Kimlik No ve şifreniz silinecektir. Onaylıyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = context.read<SecureStorageService>();
      await storage.clearCredentials();
      setState(() {
        _tcController.clear();
        _passController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilgileriniz cihazdan güvenle temizlendi.')),
        );
      }
    }
  }

  Future<void> _openEDevlet() async {
    final uri = Uri.parse('https://www.turkiye.gov.tr/gsb-wifi-sifre-islemleri');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _tcController.dispose();
    _passController.dispose();
    _portalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar & Giriş Bilgileri'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Güvenlik Bildirimi
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security, color: Color(0xFF2E7D32)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bilgileriniz hiçbir uzak sunucuya aktarılmaz. Yalnızca cihazınızın şifreli donanım kasasında (Keychain/Keystore) saklanır.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // T.C. Kimlik No Girişi
              TextFormField(
                controller: _tcController,
                keyboardType: TextInputType.number,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: 'T.C. Kimlik Numarası',
                  hintText: '11 haneli T.C. Kimlik No',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
                validator: (val) {
                  if (val == null || val.trim().length != 11) {
                    return 'Lütfen 11 haneli T.C. Kimlik numaranızı girin';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Şifre Girişi
              TextFormField(
                controller: _passController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'GSB Wi-Fi Şifresi',
                  hintText: 'e-Devlet üzerinden aldığınız şifre',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Lütfen şifrenizi girin';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Otomatik Bağlanma Seçeneği
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: const Text('Otomatik Bağlan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text(
                    'GSB_WIFI ağı algılandığında arka planda otomatik giriş yapmayı dene.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  value: _autoConnect,
                  activeColor: const Color(0xFFE53935),
                  onChanged: (val) => setState(() => _autoConnect = val),
                ),
              ),

              const SizedBox(height: 24),

              // Bilgileri Kaydet Butonu
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Bilgileri Güvenle Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 16),

              // e-Devlet Şifre Alma / Yenileme Butonu
              OutlinedButton.icon(
                onPressed: _openEDevlet,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('e-Devlet GSB Wi-Fi Şifresi Al / Değiştir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 20),

              // Gelişmiş Ayarlar (Özel Portal URL)
              InkWell(
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAdvanced ? 'Gelişmiş Ayarları Gizle' : 'Gelişmiş Ağ Ayarları',
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    Icon(_showAdvanced ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),

              if (_showAdvanced) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _portalController,
                  decoration: InputDecoration(
                    labelText: 'Portal URL Adresi',
                    hintText: 'https://wifi.gsb.gov.tr',
                    helperText: 'Yurdunuzda SSL hatası oluyorsa http://wifi.gsb.gov.tr deneyebilirsiniz.',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Bilgileri Sil
              Center(
                child: TextButton.icon(
                  onPressed: _clearCredentials,
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  label: const Text('Kayıtlı Bilgileri Cihazdan Sil', style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
