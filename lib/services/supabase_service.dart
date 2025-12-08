import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  /// Sign up a new user with username and password
  Future<AuthResponse> signUp(String email, String password, String username) async {
    final response = await supabase.auth.signUp(email: email, password: password);
    final user = response.user;

    if (user != null) {
      // 1) Fetch default level
      final defaultLevel = await supabase
          .from('levels')
          .select()
          .eq('is_default', true)
          .maybeSingle();

      int defaultLevelId = defaultLevel != null ? defaultLevel['id'] as int : 1;

      // 2) Fetch default sub-level for that level
      final defaultSubLevel = await supabase
          .from('sub_levels')
          .select()
          .eq('level_id', defaultLevelId)
          .eq('is_default', true)
          .maybeSingle();

      int defaultSubLevelId = defaultSubLevel != null ? defaultSubLevel['id'] as int : 1;

      // 3) Insert user_meta with default level unlocked
      await supabase.from('users_meta').insert({
        'user_id': user.id,
        'username': username,
        'email': email,
        'selected_weapon_id': 1,
        'unlocked_levels': [defaultLevelId],
      });

      // 4) Unlock default sub-level for user
      await supabase.from('user_levels').insert({
        'user_id': user.id,
        'sub_level_id': defaultSubLevelId,
        'is_unlocked': true,
        'is_completed': false,
      });
    }

    return response;
  }

  /// Sign in existing user
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Get current user meta
  Future<Map<String, dynamic>?> getUserMeta() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final result = await supabase
        .from('users_meta')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return result;
  }
}

/*import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<AuthResponse> signUp(String email, String password, String username) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      await supabase.from('users_meta').insert({
        'user_id': user.id,
        'username': username,
        'email': email,
        'selected_weapon_id': 1,
      });
    }

    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<Map<String, dynamic>?> getUserMeta() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final result = await supabase
        .from('users_meta')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return result;
  }
}*/
