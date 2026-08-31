import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/neumorphic_widgets.dart';

enum LegalDocType { privacyPolicy, termsOfService }

class LegalDocsSheet extends StatelessWidget {
  final LegalDocType docType;

  const LegalDocsSheet({super.key, required this.docType});

  static void show(BuildContext context, {required LegalDocType docType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LegalDocsSheet(docType: docType),
    );
  }

  Future<void> _launchPrivacyUrl() async {
    final url = Uri.parse("https://sites.google.com/view/motoconnecthq");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Web sitesi açılamadı.");
    }
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
        return NeuContainer(
          borderRadius: 28,
          color: NeuColors.surfaceDark,
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
                      color: NeuColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: NeuColors.accentOrange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  NeuIconButton(
                    icon: Icons.close,
                    size: 36,
                    iconSize: 18,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              if (isPrivacy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NeuButton(
                    color: NeuColors.accentOrange,
                    textColor: Colors.black,
                    text: "Resmi Web Sitemizde Oku",
                    onPressed: _launchPrivacyUrl,
                  ),
                ),

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
        "5. Hava Durumu, Asfalt Sıcaklığı ve Tutuş Verileri Sorumluluk Reddi (ÖNEMLİ)",
        "Uygulama içerisinde sunulan hava durumu, tahmini asfalt ısısı, rüzgar yönü/hızı ve lastik tutuş yüzdesi bilgileri yalnızca 3. taraf açık meteoroloji servislerinden ve algoritmik tahmin modellerinden üretilmektedir.\n\n"
        "• Bu verilerin sahadaki anlık yol, mikroklima ve zemin şartlarıyla (gizli buzlanma, yağ sızıntısı, mıcır, çukur vb.) birebir uyuşacağı taahhüt edilmez.\n"
        "• Sürücü; hava durumunu, asfaltın fiziki yapısını ve görüş mesafesini bizzat kontrol etmek, hızını ve takip mesafesini bu şartlara göre ayarlamakla münhasıran yükümlüdür.\n"
        "• Kullanıcının uygulama içi verilere veya göstergelere güvenerek gerçekleştirdiği sürüşlerden, hızlanmalardan veya kaza/hasarlardan MotoConnect ve kurucuları hiçbir suretle hukuki veya cezai olarak sorumlu tutulamaz.",
      ),
      _buildSection(
        "6. Telemetri, Viraj Yatış Açısı ve Canlı Sürüş Feragati",
        "Uygulamadaki jiroskop, telemetri, liderlik sıralamaları ve grup gazlama odaları kullanıcıların kendi inisiyatifleriyle katıldıkları sosyal özelliklerdir. Sürücünün limitlerini aşarak, tehlikeli manevralar yaparak veya yarışarak kaza yapması durumunda tüm hukuki, cezai ve maddi sorumluluk münhasıran sürücüye aittir. Kullanıcı bu şartları peşinen kabul ve taahhüt eder.",
      ),
      _buildSection(
        "7. Fikri Mülkiyet & Değişiklik Hakları",
        "MotoConnect logosu, arayüz tasarımları, yazılım kodları ve tüm marka varlıkları MotoConnect'e aittir; izinsiz kopyalanamaz ve çoğaltılamaz.",
      ),
      _buildSection(
        "8. Yaş Sınırı ve Ehliyet Şartı",
        "Uygulamaya kayıt olmak için en az 18 yaşında olmanız gerekmektedir. Kullanıcılar hesap oluştururken 18 yaşından büyük olduklarını, kendi motosikletlerini kullanmak için geçerli ve yasal bir sürücü belgesine (ehliyet) sahip olduklarını kabul, beyan ve taahhüt ederler. 18 yaş altı kullanıcıların tespiti halinde hesapları kalıcı olarak kapatılacaktır.",
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
              color: NeuColors.accentOrange,
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
