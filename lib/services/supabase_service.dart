import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<AuthResponse> signUp(String email, String password, String username) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      // Get default level
      final defaultLevel = await supabase
          .from('levels')
          .select('id')
          .eq('is_default', true)
          .maybeSingle();

      final defaultSubLevel = await supabase
          .from('sub_levels')
          .select('id')
          .eq('level_id', defaultLevel?['id'])
          .eq('is_default', true)
          .maybeSingle();
      
      await supabase.from('users_meta').insert({
        'user_id': user.id,
        'username': username,
        'email': email,
        'selected_weapon_id': 1,
        'unlocked_levels': defaultLevel != null ? [defaultLevel['id']] : [],
      });
      // Unlock default sublevel for the user
      if (defaultSubLevel != null) {
        await supabase.from('user_levels').insert({
          'user_id': user.id,
          'sub_level_id': defaultSubLevel['id'],
          'is_unlocked': true,
          'is_completed': false,
        });
      }
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
