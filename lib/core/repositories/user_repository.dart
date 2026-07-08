import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';

const _guestUserId = 'guest-local-user';

/// Handles the v1 "guest mode" auth requirement (spec Section 4): a user
/// can use the whole app with no sign-up. Real email/password auth is
/// added in Build Order step 6 alongside Supabase — at that point this
/// guest row becomes the thing that either stays local-only or gets
/// linked to a real account.
class UserRepository {
  UserRepository(this._db);
  final Database _db;

  static const uuid = Uuid();

  /// Returns the single local user for this device, creating a default
  /// guest user on first run if none exists yet.
  Future<UserModel> getOrCreateCurrentUser() async {
    final rows = await _db.query('users', where: 'id = ?', whereArgs: [_guestUserId]);
    if (rows.isNotEmpty) {
      return UserModel.fromMap(rows.first);
    }

    final user = UserModel(
      id: _guestUserId,
      name: 'Guest',
      email: 'guest@local.elizirfit',
      createdAt: DateTime.now().toIso8601String(),
    );
    await _db.insert('users', user.toMap());
    return user;
  }

  Future<void> updateUser(UserModel user) async {
    await _db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }
}
