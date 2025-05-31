import 'package:flutter/material.dart';
import 'package:tpm_flora/models/user.dart';
import 'package:tpm_flora/services/session_service.dart';
import 'package:tpm_flora/screens/login_page.dart'; // Untuk navigasi setelah logout
import 'package:tpm_flora/screens/edit_profile_page.dart';
// Import placeholder pages
import 'package:tpm_flora/screens/account_settings_page.dart';
import 'package:tpm_flora/screens/purchase_history_page.dart';
import 'package:tpm_flora/screens/help_faq_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SessionService _sessionService = SessionService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    User? user = await _sessionService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout Akun'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await _sessionService.clearSession();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _navigateToEditProfile() {
    if (_currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfilePage(
            currentUser: _currentUser!,
            onProfileUpdated: _loadUserProfile,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Gagal memuat profil pengguna.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: <Widget>[
                  const SizedBox(height: 20),
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.green[100],
                      backgroundImage:
                          _currentUser!.imageUrl != null &&
                              _currentUser!.imageUrl!.isNotEmpty
                          ? NetworkImage(_currentUser!.imageUrl!)
                          : null,
                      onBackgroundImageError:
                          _currentUser!.imageUrl != null &&
                              _currentUser!.imageUrl!.isNotEmpty
                          ? (dynamic exception, StackTrace? stackTrace) {
                              print("Error loading image: $exception");
                            }
                          : null,
                      child:
                          (_currentUser!.imageUrl == null ||
                              _currentUser!.imageUrl!.isEmpty)
                          ? Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.green[700],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _currentUser!.fullName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Center(
                    child: Text(
                      _currentUser!.email,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  // Display Address (Ditambahkan)
                  if (_currentUser!.address != null &&
                      _currentUser!.address!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _currentUser!.address!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[700]),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildProfileOption(
                          icon: Icons.edit_outlined,
                          title: 'Edit Profil',
                          onTap: _navigateToEditProfile,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildProfileOption(
                          icon: Icons.settings_outlined,
                          title: 'Pengaturan Akun',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AccountSettingsPage(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildProfileOption(
                          icon: Icons.history_outlined,
                          title: 'Riwayat Pembelian',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PurchaseHistoryPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildProfileOption(
                      icon: Icons.help_outline,
                      title: 'Bantuan & FAQ',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpFaqPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Versi Aplikasi 1.0.0', // This should be dynamic in a real app
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
