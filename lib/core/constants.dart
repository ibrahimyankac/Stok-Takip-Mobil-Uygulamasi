// ===================================================
// UYGULAMA SABİTLERİ
// ===================================================

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase Configuration - .env dosyasından okunacak
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // App Info
  static const String appName = 'Stok Takip';
  static const String appVersion = '1.0.0';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  
  // Database Table Names
  static const String productsTable = 'products';
  static const String categoriesTable = 'categories';
  static const String unitsTable = 'units';
  static const String stockMovementsTable = 'stock_movements';
  static const String priceChangesTable = 'price_changes';
  
  // Movement Types
  static const String movementTypePurchase = 'purchase';
  static const String movementTypeSale = 'sale';
  static const String movementTypeAdjustment = 'adjustment';
  static const String movementTypeManual = 'manual';
  static const String movementTypeDamaged = 'damaged';
  static const String movementTypeExpired = 'expired';
  
  // Default Values
  static const double defaultVatRate = 0.18; // %18 KDV
  static const int defaultMinStock = 0;
}

// ===================================================
// SUPABASE KONFİGÜRASYON NOTLARI
// ===================================================

/*
KENDİ BİLGİLERİNİZLE DEĞİŞTİRİN:

1. Supabase Dashboard → Settings → API
2. "Project URL" değerini kopyalayın
3. "Anon/Public Key" değerini kopyalayın
4. Bu dosyada değiştirin:

static const String supabaseUrl = 'https://abcdefgh.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

GÜVENLİK NOTU:
- Anon key herkese açık olduğu için güvenli
- Row Level Security (RLS) ile korunuyor
- Private key'i asla paylaşmayın!
*/