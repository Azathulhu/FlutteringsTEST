import 'package:supabase_flutter/supabase_flutter.dart';
import '../game/weapon.dart';
import '../game/projectile.dart';

class WeaponService {
  final supabase = Supabase.instance.client;

  Future<Weapon?> getUserWeapon(String userId) async {
    final weaponData = await supabase
        .from('users_meta')
        .select('selected_weapon_id, weapons(*, projectile_id, name, sprite_path, damage, fire_rate, projectiles(*))')
        .eq('user_id', userId)
        .maybeSingle();

    if (weaponData == null) return null;

    final weaponMap = weaponData['weapons'];
    final projectileMap = weaponMap['projectiles'];

    Projectile projectile = Projectile(
      x: 0,
      y: 0,
      speed: (projectileMap['speed'] as num).toDouble(),
      damage: projectileMap['damage'],
      spritePath: projectileMap['sprite_path'],
    );

    return Weapon(
      id: weaponMap['id'],
      name: weaponMap['name'],
      spritePath: weaponMap['sprite_path'],
      damage: weaponMap['damage'],
      fireRate: (weaponMap['fire_rate'] as num).toDouble(),
      projectile: projectile,
    );
  }
}
