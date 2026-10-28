import 'package:flutter/material.dart';

class TroubleshootScreen extends StatelessWidget {
  const TroubleshootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final questions = [
      {
        'title': '1. "Aktif bir oturumunuz bulunmaktadır" Hatası',
        'subtitle': 'En sık karşılaşılan oturum kilitlenmesi sorunu',
        'content':
            'Nedeni:\n'
            'GSB Wi-Fi sisteminde genellikle aynı anda yalnızca 1 cihaza (veya kurala göre 2) izin verilir. '
            'Eğer daha önce bilgisayarınızdan, tabletinizden veya eski bir tarayıcı oturumundan çıkış yapmadıysanız sistem yeni girişe izin vermez.\n\n'
            'Çözüm:\n'
            '1. Ana ekrandaki kırmızı "Oturumu Kapat (Çıkış Yap)" butonuna dokunun.\n'
            '2. Bu işlem sunucuya mevcut tüm oturumlarınızı düşürme isteği yollar.\n'
            '3. 5-10 saniye bekledikten sonra tekrar "GSB WiFi\'ye Hızlı Bağlan" butonuna basın.',
      },
      {
        'title': '2. Giriş Sayfası Açılmıyor / Zaman Aşımı (Timeout)',
        'subtitle': 'Mobil veri ve DNS çakışması',
        'content':
            'Nedeni:\n'
            'Telefonunuzda Mobil Veri (Hücresel Ağ) açık olduğunda, telefon internet trafiğini hücresel şebekeden çözmeye çalışır. '
            'Fakat "wifi.gsb.gov.tr" alan adı genel internete kapalıdır ve sadece yurt Wi-Fi ağı içinden erişilebilir.\n\n'
            'Çözüm:\n'
            '1. Telefonunuzun Mobil Verisini (4.5G/5G) tamamen kapatın.\n'
            '2. Wi-Fi bağlantısını kapatıp açarak "GSB_WIFI" ağına bağlanın.\n'
            '3. Ardından uygulamadaki Hızlı Giriş butonunu kullanın.',
      },
      {
        'title': '3. Güvenlik Sertifikası Uyarısı (SSL / HTTPS)',
        'subtitle': 'Captive Portal yönlendirmelerindeki sertifika uyarısı',
        'content':
            'Nedeni:\n'
            'Captive portal (giriş portalları), internet trafiğini giriş yapılana kadar kendi yerel sunucusuna yönlendirdiği için '
            'tarayıcılar bunu sahte sertifika olarak algılayıp engelleyebilir.\n\n'
            'Çözüm:\n'
            '• Uygulamamız bu durumu otomatik algılayacak ve güvenli şekilde atlayacak şekilde kodlanmıştır.\n'
            '• Eğer tarayıcıda takılırsanız, "Gelişmiş"e basıp "Yine de devam et" diyebilir veya Ayarlar menümüzden portal adresini "http://wifi.gsb.gov.tr" (HTTP) olarak belirleyebilirsiniz.',
      },
      {
        'title': '4. İnternet Her 8 Saatte Bir Kopuyor',
        'subtitle': 'KYK sisteminin standart oturum süresi limiti',
        'content':
            'Nedeni:\n'
            'GSB altyapısı, ağda atıl cihaz kalmaması ve adil kullanım amacıyla genellikle 8 saatlik bir oturum süresi (session timeout) uygular. 8 saat sonunda oturum kendiliğinden düşer.\n\n'
            'Çözüm:\n'
            '• Ayarlar bölümünden "Otomatik Bağlan" özelliğini açın.\n'
            '• Oturum düştüğünde ağ tespit edildiğinde uygulama bilgilerinizi kullanarak yeniden oturum açacaktır.',
      },
      {
        'title': '5. e-Devlet Wi-Fi Şifresi Nasıl Alınır / Yenilenir?',
        'subtitle': 'Şifre unutulduğunda veya ilk bağlantıda yapılması gerekenler',
        'content':
            'Adımlar:\n'
            '1. e-Devlet Kapısı\'na (turkiye.gov.tr) giriş yapın.\n'
            '2. Arama çubuğuna "GSB Wifi Şifre İşlemleri" yazın.\n'
            '3. Taahhütnameyi onaylayın ve sistemin size ürettiği şifreyi not edin.\n'
            '4. Bu şifreyi uygulamamızın Ayarlar ekranına kaydederek tek dokunuşla giriş yapabilirsiniz.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorun Çözüm Rehberi'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final item = questions[index];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFFEBEE),
                foregroundColor: const Color(0xFFD32F2F),
                child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(
                item['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
              subtitle: Text(
                item['subtitle']!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                const Divider(),
                Text(
                  item['content']!,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
