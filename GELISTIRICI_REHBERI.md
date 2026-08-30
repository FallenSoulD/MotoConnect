# MotoConnect Geliştirici Rehberi (Developer Guide)

Hoş geldin! Bu doküman, MotoConnect projesine yeni katılan veya projeyi devralan bir geliştiricinin kaybolmadan ilerleyebilmesi için hazırlanmıştır. Projenin mimarisi, klasör yapısı ve temel sistemlerin ne işe yaradığı Türkçe olarak aşağıda açıklanmıştır.

---

## 🏗️ 1. Mimari Yaklaşım

Bu proje **Flutter** ile geliştirilmiş olup, arka planda **Firebase** (Authentication, Firestore, Storage, Hosting) kullanmaktadır. 
State Management (Durum Yönetimi) için ağırlıklı olarak `StatefulWidget` ve standart Flutter yapıları kullanılmıştır.

---

## 📁 2. Klasör Yapısı (`lib/` dizini)

Projenin tüm ana kodları `lib/` klasörü altındadır. Bu klasörün yapısı ve her bir klasörün amacı şu şekildedir:

### 🔹 `models/` (Veri Modelleri)
Veritabanından (Firestore) gelen JSON verilerini Dart nesnelerine dönüştüren sınıflar buradadır.
*   `user_model.dart`: Uygulamadaki her bir sürücünün profilini (MotoUser) temsil eder. (İsim, motor tipi, konum, favori şarkı vb.)
*   `sos_model.dart`: S.O.S (Acil Yardım) sinyallerinin veri yapısını tutar.
*   `telemetry_model.dart`: Sürüş sırasında elde edilen telemetri (yatış açısı, G-Kuvveti, hız vb.) verilerinin modelidir.
*   `crossed_path_model.dart`: Yolda karşılaşılan diğer sürücülerin (Crossed Paths) kayıtlarını tutar.

### 🔹 `services/` (Arka Plan ve API Servisleri)
Kullanıcı arayüzünden (UI) bağımsız olan, veritabanı okuma/yazma, sensör okuma gibi işlemleri yapan servislerdir.
*   `firestore_service.dart`: Projenin kalbidir! Veritabanı ile tüm işlemler (kullanıcı kaydetme, eşleşme, SOS gönderme, selektör atma) burada yapılır.
*   `auth_service.dart`: Google, Apple ve E-posta ile giriş yapma, çıkış yapma işlemlerini yönetir. (Aynı e-posta ile çoklu hesabı engelleme mantığı da buradadır).
*   `sensor_service.dart`: Telefondaki İvmeölçer (Accelerometer) ve Jiroskop gibi donanımlarla iletişim kurup telemetri verilerini (Yatış açısı vb.) UI katmanına iletir.
*   `weather_service.dart`: Anlık hava durumunu çekmek için kullanılan servistir.

### 🔹 `screens/` (Kullanıcı Arayüzü / Ekranlar)
Kullanıcının gördüğü tüm ekranlar burada mantıklı klasörlere ayrılmıştır:
*   **`auth/`**: Giriş (`login_screen.dart`), kayıt olma ve şifre sıfırlama ekranları.
*   **`garage/`**: Kullanıcının kendi profilini yönettiği, motosikletini, tarzını ve favori şarkısını belirlediği "Garaj" (Profil) ekranlarıdır. Telemetri geçmişi ve liderlik tabloları da buradadır.
*   **`radar/`**: Harita (`radar_screen.dart`), Sürüş Kaydı (`ride_recording_screen.dart`) ve Yolda Karşılaşılanlar (`crossed_paths_screen.dart`) gibi uygulamanın ana sürüş özelliklerinin bulunduğu yerdir.
*   **`swipe/`**: Diğer motosikletçileri tıpkı Tinder'daki gibi sağa/sola kaydırarak beğendiğiniz veya eşleştiğiniz ekrandır.
*   **`chat/`**: Eşleşilen veya radar üzerinden selektörleşilen kişilerle mesajlaşma ekranıdır.

### 🔹 `widgets/` (Tekrar Kullanılabilir Arayüz Elemanları)
*   `neumorphic_widgets.dart`: MotoConnect'in özel tasarım dili olan "Karanlık Nöromorfik" (Dark Neumorphic) tasarımı oluşturan butonlar ve kartlardır. Uygulamadaki butonların havalı durmasını ve tıklandığında cihazı titretmesini (haptic feedback) sağlayan çekirdek dosya budur. UI değiştirilecekse önce buraya bakılmalıdır.
*   `profanity_filter.dart`: (Aslında utils veya widgets altında olabilir) Kullanıcıların isimlerine küfürlü kelimeler yazmasını engelleyen algoritmadır.

### 🔹 `utils/` (Yardımcı Fonksiyonlar)
Sık kullanılan, spesifik görevleri olan küçük fonksiyonlar barındırır (Tarih formatlama, veri dönüştürme vb.)

---

## ⚙️ 3. Önemli Algoritmalar ve Mantıklar

*   **Radar ve Harita:** `radar_screen.dart` dosyasında, kullanıcının GPS konumu sürekli güncellenir. Haritada sadece yolda karşılaşılan (`Crossed Paths`) kişiler gösterilir. Harita olarak ücretsiz OpenStreetMap kullanılmış, ancak kod (`ColorFiltered` matrisi) aracılığıyla siyaha çevrilmiştir (Karanlık tema).
*   **Telemetri (Yatış Açısı):** `ride_recording_screen.dart` ve `telemetry_screen.dart`, veriyi `sensor_service.dart` üzerinden alır. Telefonun sensörleri yatış (lean angle) ve G-Force verilerini anlık hesaplar.
*   **Eşleşme (Swipe):** Bir kullanıcı sağa kaydırıldığında, eğer o da daha önce sizi sağa kaydırdıysa `firestore_service.dart` bunu yakalar ve bir `Match` (Eşleşme) oluşturur.
*   **S.O.S. Sistemi:** `sos_sheet.dart` içinden tetiklenir. Günlük maksimum 2 adet S.O.S sinyali oluşturulabilir.

## 🚀 4. Projeyi Çalıştırma
Projeyi bilgisayarınızda çalıştırmak için:
1. `flutter pub get` ile kütüphaneleri indirin.
2. Web testi için: `flutter run -d chrome`
3. Android testi için (Cihaz takılıyken): `flutter run`
4. Web'e canlı olarak güncelleme göndermek için (Firebase Hosting): `flutter build web` ardından `firebase deploy --only hosting` (veya `npx firebase-tools deploy --only hosting`) kullanılır.

## 🔒 Firebase Güvenliği
Uygulama `motoconnect-c3412` Firebase projesine bağlıdır. Authentication ayarlarından giriş yöntemleri açılmıştır. Veritabanı kuralları (Firestore Rules) geliştirme ortamına göre yapılandırılmıştır, canlı yayına (Production) çıkarken bu kuralların sıkılaştırılması gereklidir.

> **Son Geliştiriciden Not:** Tasarımda `NeuButton` kullanılmasına özen gösterin. Butonlar kendi haptic feedback (titreşim) özelliklerine sahiptir. Yeni ekleyeceğiniz her şeyde `NeuColors.background` gibi global tasarım renklerini kullanın. Kolay gelsin! 🏍️
