import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/purchase_service.dart';
import 'neumorphic_widgets.dart';

class CheckoutSheet extends StatefulWidget {
  final MotoUser user;
  final ProductPackage package;
  final VoidCallback? onSuccess;

  const CheckoutSheet({
    super.key,
    required this.user,
    required this.package,
    this.onSuccess,
  });

  static void show(
    BuildContext context, {
    required MotoUser user,
    required ProductPackage package,
    VoidCallback? onSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: CheckoutSheet(
          user: user,
          package: package,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: "Cenk Ali");
  final _cardNumController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cityController = TextEditingController(text: "İstanbul, Türkiye");

  bool _isProcessing = false;
  String _processingStep = "";
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cardNumController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _fillDemoCard() {
    setState(() {
      _nameController.text = widget.user.nickname.isNotEmpty ? widget.user.nickname : "Cenk Ali";
      _cardNumController.text = "4543 8920 1144 7821";
      _expiryController.text = "12/28";
      _cvcController.text = "842";
      _cityController.text = "İstanbul, Türkiye";
    });
  }

  Future<void> _handlePayment() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStep = "🔒 256-Bit SSL ile banka sunucularına bağlanılıyor...";
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _processingStep = "⚡ 3D Secure provizyon doğrulaması yapılıyor...");

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _processingStep = "👑 VIP Garaj üyeliği hesabınıza tanımlanıyor...");

    try {
      final success = await PurchaseService().processCheckoutOrder(
        context,
        user: widget.user,
        package: widget.package,
        cardHolderName: _nameController.text.trim(),
        cardNumber: _cardNumController.text.trim(),
        billingAddress: _cityController.text.trim(),
      );

      if (success && mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
        widget.onSuccess?.call();
      } else {
        if (mounted) setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ödeme hatası: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: NeuColors.accentAmber, width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: _isSuccess ? _buildSuccessView() : _buildCheckoutForm(),
      ),
    );
  }

  Widget _buildCheckoutForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ÇEKME TUTAMAĞI
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

          // BAŞLIK
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock, color: NeuColors.accentAmber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Güvenli Ödeme & Sipariş",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 1. SİPARİŞ ÖZETİ KARTI
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.package.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Aylık Otomatik Yenilenen VIP Abonelik",
                            style: TextStyle(color: Colors.white54, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      widget.package.priceString,
                      style: const TextStyle(
                        color: NeuColors.accentAmber,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("KDV (%20 Dahil):", style: TextStyle(color: Colors.white38, fontSize: 11.5)),
                    Text("₺0,00", style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Ödenecek Toplam:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      widget.package.priceString,
                      style: const TextStyle(color: NeuColors.accentAmber, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // HIZLI TEST KARTI DOLDUR BUTONU
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                backgroundColor: Colors.amber.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.flash_on, color: Colors.amber, size: 16),
              label: const Text(
                "Demo Kart Bilgilerini Doldur",
                style: TextStyle(color: Colors.amber, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              onPressed: _fillDemoCard,
            ),
          ),

          const SizedBox(height: 8),

          // 2. KART SAHİBİ ADI SOYADI
          const Text(
            "KART ÜZERİNDEKİ İSİM",
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: _inputDecoration("Örn: Cenk Ali", Icons.person_outline),
            validator: (v) => (v == null || v.trim().isEmpty) ? "Kart sahibinin adını giriniz" : null,
          ),

          const SizedBox(height: 14),

          // 3. KART NUMARASI
          const Text(
            "KART NUMARASI (16 HANE)",
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _cardNumController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, letterSpacing: 1.2),
            decoration: _inputDecoration("4543 **** **** 1234", Icons.credit_card),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberInputFormatter(),
            ],
            validator: (v) {
              if (v == null || v.replaceAll(' ', '').length < 15) {
                return "Geçerli bir 16 haneli kart numarası giriniz";
              }
              return null;
            },
          ),

          const SizedBox(height: 14),

          // 4. SON KULLANMA TARİHİ & CVC
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "SKT (AA/YY)",
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: _inputDecoration("12/28", Icons.calendar_today_outlined),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateInputFormatter(),
                      ],
                      validator: (v) => (v == null || v.length < 5) ? "AA/YY giriniz" : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CVC / GÜVENLİK",
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _cvcController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: _inputDecoration("842", Icons.lock_outline),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (v) => (v == null || v.length < 3) ? "3 hane giriniz" : null,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 5. FATURA ADRESİ
          const Text(
            "FATURA BÖLGESİ / ŞEHİR",
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _cityController,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: _inputDecoration("İstanbul, Türkiye", Icons.location_city),
          ),

          const SizedBox(height: 22),

          // 6. ÖDEME BUTONU / İŞLENİYOR
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.amber),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _processingStep,
                      style: const TextStyle(color: Colors.amber, fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NeuColors.accentAmber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: _handlePayment,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "3D Secure ile Güvenli Öde (${widget.package.priceString})",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: Colors.white38, size: 14),
                SizedBox(width: 6),
                Text(
                  "256-Bit SSL Uçtan Uca Şifreli Banka Altyapısı",
                  style: TextStyle(color: Colors.white38, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent, width: 2),
          ),
          child: const Icon(Icons.check, color: Colors.greenAccent, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          "🎉 ÖDEME BAŞARIYLA ALINDI!",
          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          "Tebrikler ${widget.user.nickname}! 30 Günlük VIP Garaj üyeliğin hesabına başarıyla tanımlandı.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 20),

        // FATURA MAKBUZ KARTI
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              _receiptRow("Sipariş No:", "MC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}"),
              _receiptRow("Paket:", widget.package.title),
              _receiptRow("Ödeme Yöntemi:", "Kredi Kartı (**** ${_cardNumController.text.length >= 4 ? _cardNumController.text.substring(_cardNumController.text.length - 4) : '7821'})"),
              _receiptRow("Tutar:", widget.package.priceString),
              _receiptRow("Durum:", "Ödendi (Onaylandı 🟢)"),
            ],
          ),
        ),

        const SizedBox(height: 24),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: NeuColors.accentAmber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text("Garaja Geri Dön 👑", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white54, size: 18),
      filled: true,
      fillColor: const Color(0xFF1C1C1C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: NeuColors.accentAmber)),
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
