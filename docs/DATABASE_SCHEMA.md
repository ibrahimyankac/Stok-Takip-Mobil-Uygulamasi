# Stok Takip Uygulaması - Database Şeması

## 🎯 İhtiyaç Analizi Sonucu

### ✅ Dahil Edilenler
- **Kategoriler**: Gıda çeşitleri için kategori sistemi
- **Birimler**: kg, litre, adet gibi farklı ölçü birimleri
- **Stok & Fiyat Takibi**: Temel stok ve fiyat yönetimi
- **Hareket Kayıtları**: Stok değişiklik logları

### ❌ Dahil Edilmeyenler
- Tedarikçi takibi
- Satış kayıtları
- Parti/lot takibi
- Müşteri bilgileri

---

## 📊 Tablo Yapısı

### 1. 🏷️ CATEGORIES (Kategoriler)
```sql
- id (uuid, primary key)
- name (text) - "Süt Ürünleri", "Et & Tavuk", "Sebze & Meyve"
- description (text) - Kategori açıklaması
- color_code (text) - UI'da renk kodları için
- is_active (boolean)
- sort_order (int) - Sıralama
- created_at (timestamptz)
```

### 2. 📏 UNITS (Birimler)
```sql
- id (uuid, primary key)  
- name (text) - "kg", "litre", "adet", "gram"
- short_name (text) - "kg", "lt", "ad", "gr"
- type (text) - "weight", "volume", "piece"
- is_active (boolean)
- created_at (timestamptz)
```

### 3. 📦 PRODUCTS (Ana Tablo)
```sql
- id (uuid, primary key)
- name (text, not null) - "Süt 1L"
- sku (text, unique, not null) - "SUT001"
- barcode (text, unique) - Barkod
- description (text) - Ürün açıklaması
- category_id (uuid, foreign key) → categories
- unit_id (uuid, foreign key) → units
- brand (text) - Marka adı
- size (text) - "1 Litre", "500 gram"
-
- -- Stok Bilgileri
- stock_quantity (numeric(12,3), default 0) - Mevcut stok
- min_stock_alert (numeric(12,3), default 0) - Minimum stok uyarısı
- 
- -- Fiyat Bilgileri  
- purchase_price (numeric(12,2)) - Alış fiyatı (maliyet)
- sale_price (numeric(12,2), not null, default 0) - Satış fiyatı
- vat_rate (numeric(4,2), default 0.18) - KDV oranı (0.18 = %18)
- profit_margin (numeric(5,2)) - Kar marjı (hesaplanacak)
- 
- -- Durum
- is_active (boolean, default true)
- notes (text) - Notlar
- 
- -- Meta
- created_at (timestamptz, default now())
- updated_at (timestamptz, default now())
```

### 4. 📈 STOCK_MOVEMENTS (Stok Hareketleri)
```sql
- id (uuid, primary key)
- product_id (uuid, foreign key) → products
- delta (numeric(12,3), not null) - Değişim miktarı (+/-)
- movement_type (text, check constraint) - Hareket tipi
- reason (text) - Sebep açıklaması
- unit_price (numeric(12,2)) - O anki birim fiyat
- total_value (numeric(12,2)) - Toplam değer
- reference_number (text) - Referans no (fatura vs.)
- notes (text) - Notlar
- created_at (timestamptz, default now())
```

**Movement Types:**
- `purchase` - Satın alma (+)
- `sale` - Satış (-)
- `return_in` - İade alım (+)
- `return_out` - İade çıkış (-)
- `adjustment` - Düzeltme (+/-)
- `damaged` - Hasarlı (-)
- `expired` - Süresi dolmuş (-)
- `manual` - Manuel düzeltme (+/-)

### 5. 💰 PRICE_CHANGES (Fiyat Değişiklikleri)
```sql
- id (uuid, primary key)
- product_id (uuid, foreign key) → products
- old_purchase_price (numeric(12,2))
- new_purchase_price (numeric(12,2))
- old_sale_price (numeric(12,2))
- new_sale_price (numeric(12,2))
- change_reason (text) - Değişim sebebi
- notes (text)
- created_at (timestamptz, default now())
```

---

## 🍎 Basit Kategori Listesi

### 🎯 Ana Kategoriler (Frontend'de dropdown)
```sql
1. Baharat
2. Bitki Yağları
3. Kişisel Bakım Ürünleri
4. Bitkisel Macunlar
5. Vitamin Mineraller
6. Kuruyemiş
7. Lokum
8. Diğer
```

**Not:** Bu kategoriler frontend'de basit dropdown olarak görünecek, seçilen kategori products tablosunda category_id olarak saklanacak.

## 📏 Örnek Birimler

```sql
1. Adet (ad) - piece
2. Kilogram (kg) - weight  
3. Gram (gr) - weight
4. Litre (lt) - volume
5. Mililitre (ml) - volume
6. Paket (pkt) - piece
7. Kutu (kutu) - piece
8. Poşet (poşet) - piece
```

---

## 🎯 Sonraki Adım

Bu şemayı onayladıktan sonra SQL kodlarını oluşturup Supabase'de kuracağız!

**Eksik veya değiştirmek istediğiniz bir şey var mı?**