import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // In a real app, these keys would be loaded from environment variables (.env).
  // These are placeholder mock URLs for the pilot scaffold.
  static const String _supabaseUrl = 'https://mock-project.supabase.co';
  static const String _supabaseAnonKey = 'mock-anon-key-12345';

  static Future<void> initialize() async {
    // Only initialize if we want to actually connect.
    // In our offline-first pilot UI mock phase, we skip the real network call.
    /*
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
    */
  }

  // Mock getter for Supabase client
  // static final SupabaseClient client = Supabase.instance.client;

  /// Syncs local session data to the cloud (Mock)
  static Future<void> syncSessions(List<Map<String, dynamic>> localSessions) async {
    // await client.from('sessions').upsert(localSessions);
    print("Mock: Synced ${localSessions.length} sessions to Supabase.");
  }
}
