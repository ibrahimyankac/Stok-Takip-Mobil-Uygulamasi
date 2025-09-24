import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants.dart';

// ===================================================
// SUPABASE İNİCİALİZER
// ===================================================

class SupabaseInitializer {
  static Future<void> initialize() async {
    // .env dosyasını yükle
    await dotenv.load(fileName: '.env');
    
    // Supabase'i başlat
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }
  
  // Supabase client'ını kolay erişim için
  static SupabaseClient get client => Supabase.instance.client;
  
  // Connection test fonksiyonu
  static Future<bool> testConnection() async {
    try {
      final response = await client
          .from(AppConstants.categoriesTable)
          .select('count')
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Database health check
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final categoriesCount = await client
          .from(AppConstants.categoriesTable)
          .select('id')
          .count();
          
      final unitsCount = await client
          .from(AppConstants.unitsTable)
          .select('id')
          .count();
          
      final productsCount = await client
          .from(AppConstants.productsTable)
          .select('id')
          .count();
      
      return {
        'status': 'healthy',
        'categories': categoriesCount.count,
        'units': unitsCount.count,
        'products': productsCount.count,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}

// ===================================================
// KULLANIM ÖRNEĞİ
// ===================================================

/*
main.dart dosyasında kullanım:

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase'i başlat
  await SupabaseInitializer.initialize();
  
  // Bağlantıyı test et
  final isConnected = await SupabaseInitializer.testConnection();
  
  runApp(MyApp());
}

*/