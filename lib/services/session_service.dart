import '../database/database_helper.dart';
import '../models/user.dart'; // Import User model

class SessionService {
  static const String _loggedInUserEmailKey = 'loggedInUserEmail';
  static const String _loggedInUserFullNameKey =
      'loggedInUserFullName'; // Kunci baru
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> createSession(String email, String fullName) async {
    await _dbHelper.setSessionValue(_loggedInUserEmailKey, email);
    await _dbHelper.setSessionValue(
      _loggedInUserFullNameKey,
      fullName,
    ); // Simpan nama lengkap
  }

  Future<String?> getLoggedInUserEmail() async {
    return await _dbHelper.getSessionValue(_loggedInUserEmailKey);
  }

  Future<String?> getLoggedInUserFullName() async {
    // Metode baru
    return await _dbHelper.getSessionValue(_loggedInUserFullNameKey);
  }

  Future<void> clearSession() async {
    await _dbHelper.deleteSessionValue(_loggedInUserEmailKey);
    await _dbHelper.deleteSessionValue(
      _loggedInUserFullNameKey,
    ); // Hapus nama lengkap dari sesi
  }

  Future<bool> isLoggedIn() async {
    final email = await getLoggedInUserEmail();
    return email != null;
  }

  // Helper untuk mendapatkan detail user yang sedang login jika diperlukan di banyak tempat
  Future<User?> getCurrentUser() async {
    final email = await getLoggedInUserEmail();
    if (email != null) {
      return await _dbHelper.getUserByEmail(email);
    }
    return null;
  }
}
