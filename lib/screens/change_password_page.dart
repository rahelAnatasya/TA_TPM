import 'package:flutter/material.dart';
import 'package:tpm_flora/models/user.dart';
import 'package:tpm_flora/database/database_helper.dart';
import 'package:tpm_flora/services/session_service.dart';

class ChangePasswordPage extends StatefulWidget {
  final User currentUser;

  const ChangePasswordPage({Key? key, required this.currentUser})
    : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool _isCurrentPasswordObscure = true;
  bool _isNewPasswordObscure = true;
  bool _isConfirmNewPasswordObscure = true;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _handleChangePassword() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.currentUser.password != _currentPasswordController.text) {
      setState(() {
        _errorMessage = 'Password saat ini salah.';
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password baru minimal 6 karakter.';
      });
      return;
    }

    if (_newPasswordController.text == _currentPasswordController.text) {
      setState(() {
        _errorMessage =
            'Password baru tidak boleh sama dengan password saat ini.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User updatedUser = User(
        id: widget.currentUser.id,
        fullName: widget.currentUser.fullName,
        email: widget.currentUser.email,
        password: _newPasswordController.text, // Update password
        imageUrl: widget.currentUser.imageUrl,
      );

      int result = await _dbHelper.updateUser(updatedUser);

      if (!mounted) return;

      if (result > 0) {
        setState(() {
          _successMessage = 'Password berhasil diubah!';
          _errorMessage = null;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmNewPasswordController.clear();
          // Update widget.currentUser if needed for further actions on this page,
          // though typically we'd pop or show success and let parent refresh.
          // For simplicity, we show success and clear.
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Optionally pop after a delay or let user see the message
        // Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = 'Gagal mengubah password. Silakan coba lagi.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_successMessage != null &&
                  _errorMessage == null) // Only show success if no error
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password Saat Ini',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCurrentPasswordObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed:
                        () => setState(
                          () =>
                              _isCurrentPasswordObscure =
                                  !_isCurrentPasswordObscure,
                        ),
                  ),
                ),
                obscureText: _isCurrentPasswordObscure,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan password saat ini';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed:
                        () => setState(
                          () => _isNewPasswordObscure = !_isNewPasswordObscure,
                        ),
                  ),
                ),
                obscureText: _isNewPasswordObscure,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan password baru';
                  }
                  if (value.length < 6) {
                    return 'Password baru minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmNewPasswordController,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmNewPasswordObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed:
                        () => setState(
                          () =>
                              _isConfirmNewPasswordObscure =
                                  !_isConfirmNewPasswordObscure,
                        ),
                  ),
                ),
                obscureText: _isConfirmNewPasswordObscure,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi password baru Anda';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Simpan Password'),
                onPressed: _isLoading ? null : _handleChangePassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }
}
