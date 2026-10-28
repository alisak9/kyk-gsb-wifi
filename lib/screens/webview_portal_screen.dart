import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../services/secure_storage_service.dart';

class WebviewPortalScreen extends StatefulWidget {
  const WebviewPortalScreen({super.key});

  @override
  State<WebviewPortalScreen> createState() => _WebviewPortalScreenState();
}

class _WebviewPortalScreenState extends State<WebviewPortalScreen> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  String _currentUrl = 'https://wifi.gsb.gov.tr';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialUrl();
  }

  Future<void> _loadInitialUrl() async {
    final storage = context.read<SecureStorageService>();
    final url = await storage.getPortalUrl();
    setState(() {
      _currentUrl = url;
    });
  }

  /// Sayfa yüklendiğinde T.C. Kimlik No ve Şifreyi otomatik dolduran JavaScript kodu
  Future<void> _injectCredentials() async {
    final storage = context.read<SecureStorageService>();
    final tc = await storage.getTcKimlik() ?? '';
    final pass = await storage.getPassword() ?? '';

    if (tc.isEmpty || pass.isEmpty || _webViewController == null) return;

    final jsCode = """
      (function() {
        var userFields = document.querySelectorAll("input[name='j_username'], input[name='username'], input[id='username'], input[id='j_username'], input[type='text']");
        var passFields = document.querySelectorAll("input[name='j_password'], input[name='password'], input[id='password'], input[id='j_password'], input[type='password']");

        if (userFields.length > 0) {
          userFields[0].value = '$tc';
          userFields[0].dispatchEvent(new Event('input', { bubbles: true }));
          userFields[0].dispatchEvent(new Event('change', { bubbles: true }));
        }

        if (passFields.length > 0) {
          passFields[0].value = '$pass';
          passFields[0].dispatchEvent(new Event('input', { bubbles: true }));
          passFields[0].dispatchEvent(new Event('change', { bubbles: true }));
        }

        // Eğer captcha veya güvenlik kodu alanı varsa odaklan
        var captchaField = document.querySelector("input[name*='captcha'], input[id*='captcha'], input[name*='code'], input[id*='code']");
        if (captchaField) {
          captchaField.focus();
        }
      })();
    """;

    await _webViewController?.evaluateJavascript(source: jsCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GSB Akıllı Web Portalı', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Bilgileri Otomatik Doldur',
            onPressed: _injectCredentials,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () => _webViewController?.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              javaScriptEnabled: true,
              cacheEnabled: false,
              clearCache: true,
              supportZoom: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() => _isLoading = true);
            },
            onLoadStop: (controller, url) async {
              setState(() => _isLoading = false);
              // Sayfa bitince otomatik form doldur
              await _injectCredentials();
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
            },
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              // GSB portalının SSL sertifika sorununu yoksay
              return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
            },
          ),
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              color: const Color(0xFFE53935),
              backgroundColor: Colors.transparent,
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.grey.shade100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'T.C. ve Şifreniz otomatik dolduruldu. Varsa güvenlik kodunu girip Giriş\'e basın.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _injectCredentials,
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('Doldur', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
