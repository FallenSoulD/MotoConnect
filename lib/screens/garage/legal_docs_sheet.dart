import 'package:flutter/material.dart';

enum LegalDocType { privacyPolicy, termsOfService }

class LegalDocsSheet extends StatelessWidget {
  final LegalDocType docType;

  const LegalDocsSheet({super.key, required this.docType});

  static void show(BuildContext context, {required LegalDocType docType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => LegalDocsSheet(docType: docType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPrivacy = docType == LegalDocType.privacyPolicy;
    final title = isPrivacy ? "Gizlilik Politikası & KVKK" : "Kullanım Koşulları (EULA)";
    final icon = isPrivacy ? Icons.privacy_tip_outlined : Icons.description_outlined;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Tutamaç
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Başlık
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.deepOrange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),

              // Doküman İçeriği
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (isPrivacy) ..._buildPrivacyContent() else ..._buildTermsContent(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPrivacyContent() {
    return [
      _buildSection(
        "1. Veri Sorumlusu ve Genel Bakış",
        "MotoConnect olarak kullanıcılarımızın gizliliğine ve kişisel verilerinin korunmasına büyük önem veriyoruz. Bu Gizlilik Politikası, 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) ve Avrupa Genel Veri Koruma Tüzüğü (GDPR) kapsamında düzenlenmiştir.",
      ),
      _buildSection(
        "2. Konum Verilerinin İşlenmesi (GPS & Radar)",
        "MotoConnect, çevrenizdeki motorcu arkadaşlarını haritada görebilmeniz, kesişen yolları tespit edebilmeniz ve grup gazlama odalarına katılabilmeniz için konum verilerinizi (ön planda ve sürüş esnasında) işler. Konum verileriniz asla 3. taraf reklam şirketlerine satılmaz veya pazarlama amaçlı paylaşılmaz.",
      ),
      _buildSection(
        "3. Fotoğraf ve Kamera İzinleri",
        "Garajınıza motosiklet görselleri eklemek ve profil fotoğrafınızı güncellemek amacıyla kamera ve galeri erişimi istenir. Yalnızca sizin seçtiğiniz görseller Firebase Storage güvenli bulut altyapısında şifreli olarak saklanır.",
      ),
      _buildSection(
        "4. Mesajlaşma ve İletişim Güvenliği",
        "Kullanıcılar arasındaki birebir sohbetler Firebase Firestore üzerinde şifreli olarak aktarılır. Topluluk kurallarını korumak amacıyla zararlı ifadeler otomatik filtre sistemimiz tarafından taranır.",
      ),
      _buildSection(
        "5. Hesap ve Veri Silme Hakkı (Apple & Google Standardı)",
        "Dilediğiniz an Ayarlar > 'Hesabımı ve Tüm Verilerimi Sil' butonunu kullanarak profilinizi, mesajlarınızı, garajınızı ve tüm verilerinizi kalıcı olarak silebilirsiniz. Silme işlemi anında yürürlüğe girer ve geri alınamaz.",
      ),
      _buildSection(
        "6. İletişim & Hak Talepleri",
        "Verilerinizle ilgili her türlü soru, itiraz ve bilgi talebi için destek@motoconnect.app adresi üzerinden bizimle iletişime geçebilirsiniz.",
      ),
    ];
  }

  List<Widget> _buildTermsContent() {
    return [
      _buildSection(
        "1. Kabul Edilme ve Kapsam",
        "MotoConnect uygulamasını indirerek, hesap oluşturarak veya kullanarak işbu Kullanım Koşullarını ve Topluluk Kurallarını kabul etmiş sayılırsınız.",
      ),
      _buildSection(
        "2. Trafik Güvenliği ve Sorumluluk Reddi (ÖNEMLİ)",
        "MotoConnect bir sosyal etkileşim ve rota paylaşım platformudur. Kullanıcılar her zaman yürürlükteki Karayolları Trafik Kanunu'na ve hız sınırlarına uymakla yükümlüdür.\n\n• Sürüş esnasında telefon ekranına müdahale etmek kesinlikle yasaktır.\n• Kask, korumalı mont, eldiven ve dizlik gibi tam koruma ekipmanı olmadan sürüş yapmayınız.\n• Uygulama üzerinden planlanan rotalarda veya bireysel sürüşlerde meydana gelebilecek kaza, hasar veya ihlallerden sürücünün kendisi münhasıran sorumludur.",
      ),
      _buildSection(
        "3. Kullanıcı Davranış Kuralları & Sıfır Tolerans Politikası",
        "MotoConnect topluluğunda taciz, nefret söylemi, hakaret, sahte hesap oluşturma veya rahatsız edici davranışlara sıfır tolerans uygulanır. Moderasyon ekibimiz veya kullanıcı şikayetleri sonucunda kuralları ihlal eden hesaplar süresiz olarak askıya alınır.",
      ),
      _buildSection(
        "4. VIP Garaj & Uygulama İçi Satın Alımlar",
        "VIP üyelik ve süper selektör gibi dijital ürünler Apple App Store ve Google Play Store resmi ödeme altyapıları üzerinden tahsil edilir. Abonelik iptalleri ilgili mağaza hesap ayarlarından yönetilebilir.",
      ),
      _buildSection(
        "5. Fikri Mülkiyet",
        "MotoConnect logosu, arayüz tasarımları, yazılım kodları ve tüm marka varlıkları MotoConnect'e aittir; izinsiz kopyalanamaz ve çoğaltılamaz.",
      ),
    ];
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
