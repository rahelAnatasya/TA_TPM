import 'package:flutter/material.dart';
import 'package:tpm_flora/models/user.dart';
import 'package:tpm_flora/services/session_service.dart';
import 'package:tpm_flora/screens/change_password_page.dart';
import 'package:tpm_flora/screens/change_email_page.dart';
import 'package:tpm_flora/database/database_helper.dart'; // Import DatabaseHelper
import 'package:tpm_flora/services/favorite_service.dart'; // Import FavoriteService
import 'package:tpm_flora/services/cart_service.dart'; // Import CartService
import 'package:tpm_flora/screens/login_page.dart'; // Import LoginPage

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final SessionService _sessionService = SessionService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FavoriteService _favoriteService = FavoriteService();
  final CartService _cartService = CartService();

  User? _currentUser;
  bool _isLoading = true;
  bool _isDeleting = false; // State untuk loading saat hapus akun

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    _currentUser = await _sessionService.getCurrentUser();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _promptForPasswordAndDelete() async {
    if (_currentUser == null) return;

    final TextEditingController passwordController = TextEditingController();
    bool isPasswordObscure = true;
    String? dialogErrorMessage;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Konfirmasi Hapus Akun'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text(
                      'Ini adalah tindakan permanen. Untuk melanjutkan, masukkan password Anda saat ini:',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: isPasswordObscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              isPasswordObscure = !isPasswordObscure;
                            });
                          },
                        ),
                        errorText:
                            dialogErrorMessage, // Untuk error di dalam dialog
                      ),
                      autofocus: true,
                      onChanged: (_) {
                        // Clear error message on change
                        if (dialogErrorMessage != null) {
                          setStateDialog(() {
                            dialogErrorMessage = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Hapus Akun Saya'),
                  onPressed: () {
                    if (passwordController.text.isEmpty) {
                      setStateDialog(() {
                        dialogErrorMessage = 'Password tidak boleh kosong.';
                      });
                      return;
                    }
                    if (passwordController.text == _currentUser!.password) {
                      Navigator.of(dialogContext).pop(true);
                    } else {
                      setStateDialog(() {
                        dialogErrorMessage = 'Password salah.';
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      await _performAccountDeletion();
    }
  }

  Future<void> _performAccountDeletion() async {
    if (_currentUser == null || _currentUser!.id == null) return;
    if (!mounted) return;

    setState(() {
      _isDeleting = true;
    });

    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Menghapus akun..."),
            ],
          ),
        );
      },
    );

    final String userEmailForPrefs = _currentUser!.email;
    final int userIdToDelete = _currentUser!.id!;

    try {
      // 1. Delete from database
      await _dbHelper.deleteUserById(userIdToDelete);

      // 2. Clear SharedPreferences data
      await _favoriteService.clearUserFavoritesData(userEmailForPrefs);
      await _cartService.clearUserCartData(userEmailForPrefs);

      // 3. Clear session
      await _sessionService.clearSession();

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop(); // Tutup dialog loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil dihapus.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 4. Navigate to LoginPage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // Tutup dialog loading jika ada error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus akun: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Akun')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentUser == null
              ? const Center(child: Text("Tidak dapat memuat data pengguna."))
              : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser!.fullName,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _currentUser!.email,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.email_outlined,
                    title: 'Ubah Email',
                    subtitle: 'Perbarui alamat email Anda',
                    onTap:
                        _isDeleting
                            ? null
                            : () {
                              // Disable if deleting
                              if (_currentUser != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChangeEmailPage(
                                          currentUser: _currentUser!,
                                          onEmailChangedSuccessfully:
                                              _loadCurrentUser,
                                        ),
                                  ),
                                );
                              }
                            },
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.lock_outline,
                    title: 'Ubah Password',
                    subtitle: 'Ganti password akun Anda',
                    onTap:
                        _isDeleting
                            ? null
                            : () {
                              // Disable if deleting
                              if (_currentUser != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChangePasswordPage(
                                          currentUser: _currentUser!,
                                        ),
                                  ),
                                ).then(
                                  (_) => _loadCurrentUser(),
                                ); // Reload user data in case password change affects session indirectly
                              }
                            },
                  ),
                  const Divider(
                    height: 1,
                    thickness: 8,
                    color: Color.fromARGB(255, 236, 239, 236),
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.delete_forever_outlined,
                    title: 'Hapus Akun',
                    subtitle: 'Hapus akun Anda secara permanen',
                    onTap:
                        _isDeleting
                            ? null
                            : _promptForPasswordAndDelete, // Updated onTap
                    textColor: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback? onTap, // Allow null for disabled state
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            onTap == null
                ? Colors.grey
                : (textColor ?? Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: onTap == null ? Colors.grey : textColor,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: TextStyle(
                  color: onTap == null ? Colors.grey[400] : Colors.grey[600],
                ),
              )
              : null,
      trailing:
          textColor == null && onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null,
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}
