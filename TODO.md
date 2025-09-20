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
- [x] Git init yapıldı

---

## 🟡 Devam Eden Görevler

### 2. Supabase Backend Kurulumu
- [ ] **Supabase hesabı oluştur**
  - https://supabase.com adresine git
  - Ücretsiz hesap aç
  - Proje adı: `stok-takip-uygulamasi`
  
- [ ] **Database tablolarını oluştur**
  - SQL Editor'da aşağıdaki tabloları oluştur:
    - `products` (id, name, sku, barcode, stock_quantity, sale_price, purchase_price, vat_rate, min_stock_alert)
    - `stock_movements` (id, product_id, delta, reason, note, created_at)
    - `price_changes` (id, product_id, old_price, new_price, created_at)
  
- [ ] **Database fonksiyonlarını ekle**
  - `add_stock_and_log()` - Atomic stok güncelleme
  - `change_price_and_log()` - Atomic fiyat güncelleme
  - Trigger fonksiyonları
  
- [ ] **API bilgilerini al**
  - Project URL
  - Anon Key
  - Bu bilgileri kaydet

---

## 📂 Gelecek Görevler

### 3. Proje Klasör Yapısı
- [ ] **Core klasörü oluştur**
  - `lib/core/supabase_initializer.dart`
  - `lib/core/constants.dart`
  - `lib/core/router.dart`

- [ ] **Features klasörü oluştur**
  ```
  lib/features/
    auth/
      presentation/
        login_page.dart
    products/
      data/
        models/
          product.dart
          stock_movement.dart
          price_change.dart
        repositories/
          product_repository.dart
          supabase_product_repository.dart
      presentation/
        pages/
          product_list_page.dart
          product_form_page.dart
          product_detail_page.dart
          scan_page.dart
        widgets/
          product_card.dart
          stock_controls.dart
  ```

### 4. Supabase Entegrasyonu
- [ ] **Supabase inicializasyonu**
  - `supabase_initializer.dart` dosyası
  - `main.dart`'a entegrasyon
  - Environment variables (.env dosyası)

- [ ] **Data modelleri**
  - Product model (fromMap, toMap, copyWith)
  - StockMovement model
  - PriceChange model

- [ ] **Repository pattern**
  - Abstract ProductRepository interface
  - SupabaseProductRepository implementation
  - CRUD operasyonları

### 5. UI/UX Geliştirme
- [ ] **Ana sayfa (Product List)**
  - Ürün listesi görünümü
  - Arama ve filtreleme
  - Fab button (Yeni ürün ekle)
  - Pull-to-refresh

- [ ] **Ürün formu**
  - Yeni ürün ekleme
  - Ürün düzenleme
  - Form validasyonu
  - Barkod alanı

- [ ] **Ürün detay sayfası**
  - Ürün bilgileri
  - Stok artırma/azaltma kontrolleri
  - Fiyat güncelleme
  - Hareket geçmişi

- [ ] **Barkod tarama**
  - Mobile scanner entegrasyonu
  - Kamera izinleri
  - Tarama sonucu işleme

### 6. İş Mantığı
- [ ] **Stok yönetimi**
  - Stok artırma/azaltma
  - Hareket kaydı tutma
  - Minimum stok uyarıları

- [ ] **Fiyat yönetimi**
  - Fiyat güncelleme
  - Fiyat geçmişi
  - KDV hesaplamaları

- [ ] **Raporlama**
  - Toplam stok değeri
  - Düşük stok listesi
  - Son hareketler

### 7. Optimizasyon ve Test
- [ ] **Performance optimizasyonu**
  - Lazy loading
  - Image optimization
  - Memory management

- [ ] **Error handling**
  - Network errors
  - Database errors
  - User feedback

- [ ] **Test yazma**
  - Unit tests
  - Widget tests
  - Integration tests

### 8. Dağıtım
- [ ] **APK hazırlığı**
  - Release build konfigürasyonu
  - App signing
  - Obfuscation

- [ ] **APK build ve test**
  - `flutter build apk --release`
  - Cihazda test
  - Performance test

### 9. Gelecek Geliştirmeler (Opsiyonel)
- [ ] **Auth sistemi**
  - Email/password login
  - RLS policies

- [ ] **Gelişmiş özellikler**
  - CSV export/import
  - Backup/restore
  - Çoklu dil desteği
  - Dark mode

- [ ] **Web versiyonu**
  - Flutter web build
  - Responsive design

---

## 🚀 Sonraki Adım
**Supabase projesini kurarak devam edeceğiz!**

1. Supabase hesabı oluştur
2. SQL tablolarını kur
3. API bilgilerini al
4. Proje klasör yapısını oluştur

---

## 📝 Notlar
- Tek kullanıcı (admin) odaklı uygulama
- İnternet bağlantısı her zaman mevcut
- APK olarak manuel dağıtım
- Basit ve kullanışlı arayüz önceliği