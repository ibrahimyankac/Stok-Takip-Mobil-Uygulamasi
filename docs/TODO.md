# Stok Takip Uygulaması - Detaylı Yapılacaklar Listesi

## 📋 Proje Genel Bakış
- **Platform**: Flutter (Android APK)
- **Backend**: Supabase
- **Kullanıcı**: Tek admin kullanıcı
- **Özellikler**: Stok yönetimi, fiyat takibi, barkod tarama

---

## ✅ Tamamlanan Görevler

### 1. Proje Kurulumu
- [x] Flutter projesi oluşturuldu
- [x] Gerekli paketler pubspec.yaml'a eklendi:
  - supabase_flutter: ^2.10.1
  - mobile_scanner: ^5.2.3
  - provider: ^6.1.5
  - go_router: ^14.8.1
  - flutter_form_builder: ^10.2.0
  - form_builder_validators: ^11.2.0
- [x] Paketler başarıyla yüklendi
- [x] Git repository GitHub'a bağlandı

### 2. İhtiyaç Analizi & Database Tasarımı
- [x] Gıda dükkanı için ihtiyaç analizi tamamlandı
- [x] Database şeması tasarlandı
- [x] Kategoriler belirlendi (Baharat, Bitki Yağları, vs.)
- [x] Birimler tanımlandı (kg, lt, adet, vs.)

### 3. Supabase Backend Kurulumu
- [x] Supabase hesabı oluşturuldu
- [x] Proje oluşturuldu
- [x] SQL tablolarını başarıyla kuruldu:
  - categories (8 kayıt)
  - units (8 kayıt) 
  - products (boş)
  - stock_movements (boş)
  - price_changes (boş)
- [x] İş mantığı fonksiyonları eklendi:
  - add_stock_and_log()
  - change_price_and_log()

---

## 🟡 Devam Eden Görevler

### 4. Supabase API Entegrasyonu
- [ ] **API bilgilerini al ve kaydet**
  - Project URL
  - Anon Key
  - Bu bilgileri Flutter projesine entegre et

---

## 📂 Gelecek Görevler

### 5. Proje Klasör Yapısı
- [ ] **Core klasörü oluştur**
  - `lib/core/supabase_initializer.dart`
  - `lib/core/constants.dart`
  - `lib/core/router.dart`

### 6. Data Layer (Veri Katmanı)
- [ ] **Data modelleri oluştur**
  - Product model (fromMap, toMap, copyWith)
  - Category model
  - Unit model
  - StockMovement model
  - PriceChange model

- [ ] **Repository pattern**
  - Abstract ProductRepository interface
  - SupabaseProductRepository implementation
  - CRUD operasyonları (Create, Read, Update, Delete)

### 7. UI/UX Geliştirme
- [ ] **Ana sayfa (Product List)**
  - Ürün listesi görünümü
  - Arama ve kategori filtreleme
  - Floating Action Button (Yeni ürün ekle)
  - Pull-to-refresh

- [ ] **Ürün formu sayfası**
  - Yeni ürün ekleme formu
  - Ürün düzenleme formu
  - Form validasyonu
  - Kategori ve birim dropdown'ları
  - Barkod alanı

- [ ] **Ürün detay sayfası**
  - Ürün bilgileri görüntüleme
  - Stok artırma/azaltma kontrolleri
  - Fiyat güncelleme
  - Hareket geçmişi görüntüleme

### 8. Özel Özellikler
- [ ] **Barkod tarama**
  - Mobile scanner entegrasyonu
  - Kamera izinleri
  - Tarama sonucu işleme
  - Barkod ile ürün arama

- [ ] **Stok ve fiyat yönetimi**
  - Atomic stok artırma/azaltma
  - Fiyat güncelleme
  - Kar marjı hesaplama
  - Minimum stok uyarıları

### 9. Test ve Dağıtım
- [ ] **Test ve optimizasyon**
  - Uygulama testi
  - Performance optimizasyonu
  - Error handling

- [ ] **APK build ve dağıtım**
  - Release APK oluştur
  - Cihazda test
  - Manual dağıtım

---

## 🚀 Sonraki Adım
**Supabase API bilgilerini alıp Flutter projesine entegre etme!**

1. Supabase Dashboard → Settings → API
2. Project URL ve Anon Key'i al
3. Flutter projesinde konfigürasyon yap
4. İlk bağlantı testini yap

---

## � İlerleme Durumu
- ✅ **Backend**: %100 (Database kuruldu)
- 🟡 **API Entegrasyonu**: %0 (Başlanacak)
- ⏳ **Frontend**: %0 (Beklemede)
- ⏳ **Test & Dağıtım**: %0 (Beklemede)

**Toplam İlerleme: ~30%**