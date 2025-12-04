import 'package:supabase_flutter/supabase_flutter.dart';

class WeaponService {
  final supabase = Supabase.instance.client;

  // Load all weapons
  Future<List<Map<String, dynamic>>> loadWeapons() async {
    final weapons = await supabase.from('weapons').select();
    return weapons;
  }

  // Load user's equipped weapon
  Future<Map<String, dynamic>?> loadEquippedWeapon() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final weaponRow = await supabase
        .from('user_weapons')
        .select('weapon_id, weapons(*)')
        .eq('user_id', user.id)
        .eq('is_equipped', true)
        .maybeSingle();

    if (weaponRow == null) return null;

    final weaponData = weaponRow['weapons'];
    return weaponData;
  }

  // Equip a weapon for user
  Future<void> equipWeapon(int weaponId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Unequip current weapon
    await supabase
        .from('user_weapons')
        .update({'is_equipped': false})
        .eq('user_id', user.id)
        .eq('is_equipped', true);

    // Upsert new weapon
    await supabase.from('user_weapons').upsert({
      'user_id': user.id,
      'weapon_id': weaponId,
      'is_equipped': true,
    });
  }
}
