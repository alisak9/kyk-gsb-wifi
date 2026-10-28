# KYK Yurtları GSB Wi-Fi Kolay Bağlantı Mobil Uygulaması 🚀

Bu mobil uygulama, Gençlik ve Spor Bakanlığı (GSB) Kredi ve Yurtlar Kurumu (KYK) yurtlarında kalan öğrencilerin kablosuz ağa (**GSB_WIFI**) bağlanırken yaşadığı captive portal takılmalarını, DNS hatalarını ve sürekli oturum düşmelerini çözmek amacıyla geliştirilmiş **çift platformlu (iOS & Android)** modern bir mobil uygulamadır.

---

## 🌟 Öne Çıkan Özellikler

1. **⚡ Tek Dokunuşla Hızlı Giriş (One-Tap Fast Login)**
   - Hantal tarayıcı sayfalarının yüklenmesini beklemeden, doğrudan ağ geçidine optimize edilmiş arka plan HTTP POST istekleri göndererek milisaniyeler içinde internet erişimini aktif eder.

2. **🚪 Tek Dokunuşla Oturumu Kapat (One-Tap Logout)**
   - KYK yurtlarında en sık karşılaşılan *"Aktif bir oturumunuz bulunmaktadır / Cihaz kotası doldu"* hatasını çözmek için eski veya diğer cihazlardaki oturumu anında sonlandırır.

3. **🔒 Donanımsal Şifreli Güvenlik Kasası**
   - T.C. Kimlik Numaranız ve şifreniz **asla** üçüncü taraf bir sunucuya gitmez.
   - iOS'ta **Apple Keychain**, Android'de **Android Keystore (AES EncryptedSharedPreferences)** ile cihazın kendi güvenli çipinde saklanır.

4. **🌐 Akıllı Web Girişi & Otomatik Form Doldurucu (Smart WebView Fallback)**
   - Eğer bulunduğunuz yurttaki portal Güvenlik Kodu (Captcha) veya SMS onayı talep ediyorsa, gömülü akıllı tarayıcı otomatik olarak T.C. ve şifrenizi doldurur; size yalnızca güvenlik kodunu girmek kalır.

5. **📡 Canlı Ağ Durumu & Gerçek İnternet Testi**
   - Bağlı olunan Wi-Fi SSID (`GSB_WIFI`, `KYK_WIFI`) ve IP adresini gösterir.
   - Google 204 HTTP testi ile internetin gerçekten açık olup olmadığını anlık doğrular.

6. **🛠️ Kapsamlı Sorun Çözüm Rehberi (Troubleshooting)**
   - Mobil veri çakışması, SSL sertifika uyarıları, 8 saatlik oturum süresi ve e-Devlet şifre yenileme gibi konularda adım adım rehberlik sunar.

---

## 📁 Proje Dizin Yapısı

```text
kyk_gsb_wifi_app/
├── lib/
│   ├── main.dart                          # Uygulama başlangıcı ve tema yapılandırması
│   ├── models/
│   │   └── connection_state.dart          # Ağ durumları ve oturum sonuç modelleri
│   ├── services/
│   │   ├── gsb_wifi_service.dart          # HTTP POST login/logout & captive portal servisi
│   │   ├── network_monitor_service.dart   # Canlı Wi-Fi SSID ve internet kontrolcüsü
│   │   └── secure_storage_service.dart    # Keychain/Keystore şifreli depolama servisi
│   └── screens/
│       ├── home_screen.dart               # Ana kontrol paneli & hızlı işlem butonları
│       ├── settings_screen.dart           # Kimlik yönetimi & otomatik bağlanma ayarları
│       ├── webview_portal_screen.dart     # JS enjeksiyonlu gömülü web portalı
│       └── troubleshoot_screen.dart       # Sık karşılaşılan sorunlar ve çözümleri
├── android/
│   └── app/src/main/AndroidManifest.xml   # Android Wi-Fi ve ağ izinleri
├── ios/
│   └── Runner/Info.plist                  # iOS SSID ve ağ izinleri
├── pubspec.yaml                           # Flutter paket bağımlılıkları
└── README.md
```

---

## 🚀 Kurulum ve Çalıştırma Adımları

### 1. Gereksinimler
- Bilgisayarınızda [Flutter SDK](https://docs.flutter.dev/get-started/install) yüklü olmalıdır.
- Android için: Android Studio veya VS Code & Android Cihaz/Emülatör.
- iOS için: macOS & Xcode & iPhone/Simülatör.

### 2. Projeyi Çalıştırma

Terminal veya komut istemcisinde proje dizinine gidin:

```bash
cd "C:\Users\Özgür\.gemini\antigravity\scratch\kyk_gsb_wifi_app"
```

Paketleri indirin:
```bash
flutter pub get
```

Cihazınız bağlıyken uygulamayı başlatın:
```bash
flutter run
```

### 3. Android APK Çıktısı Alma (Kurulum Dosyası)
Kendi Android telefonunuza direkt yükleyebileceğiniz APK dosyasını üretmek için:
```bash
flutter build apk --release
```
Oluşan dosya: `build/app/outputs/flutter-apk/app-release.apk`

### 4. iOS IPA / Runner Çıktısı Alma
macOS ortamında:
```bash
flutter build ipa --release
```
veya Xcode ile `ios/Runner.xcworkspace` dosyasını açıp imzalama yaparak kendi iPhone cihazınıza yükleyebilirsiniz.

---

## 💡 KYK Wi-Fi İpuçları
* **Hücresel Veriyi Kapatın:** Giriş yaparken mutlaka telefonunuzun mobil verisini (4.5G) kapatıp yalnızca GSB_WIFI ağına bağlı olun. Bu sayede telefonunuz portal adresini sorunsuz çözer.
* **Aktif Oturum Uyarısı:** Başka cihazdan açık kalan oturumlar için ana ekrandaki **"Oturumu Kapat (Çıkış Yap)"** butonuna basarak eski oturumunuzu güvenle düşürebilirsiniz.
