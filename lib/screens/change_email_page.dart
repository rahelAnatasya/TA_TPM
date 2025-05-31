import 'package:flutter/material.dart';
import 'package:tpm_flora/models/user.dart';
import 'package:tpm_flora/database/database_helper.dart';
import 'package:tpm_flora/services/session_service.dart';

class ChangeEmailPage extends StatefulWidget {
  final User currentUser;
  final VoidCallback onEmailChangedSuccessfully; // To refresh profile page data

  const ChangeEmailPage({
    Key? key,
    required this.currentUser,
    required this.onEmailChangedSuccessfully,
  }) : super(key: key);

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isPasswordObscure = true;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SessionService _sessionService = SessionService();

  Future<void> _handleChangeEmail() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.currentUser.password != _currentPasswordController.text) {
      setState(() {
        _errorMessage = 'Password salah.';
      });
      return;
    }

    final newEmail = _newEmailController.text.trim();
    if (newEmail == widget.currentUser.email) {
      setState(() {
        _errorMessage = 'Email baru tidak boleh sama dengan email saat ini.';
      });
      return;
    }

    // Check if new email already exists
    final existingUser = await _dbHelper.getUserByEmail(newEmail);
    if (existingUser != null) {
      setState(() {
        _errorMessage = 'Email ini sudah digunakan oleh akun lain.';
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
        email: newEmail, // Update email
        password: widget.currentUser.password, // Password remains the same
        imageUrl: widget.currentUser.imageUrl,
      );

      int result = await _dbHelper.updateUser(updatedUser);

      if (!mounted) return;

      if (result > 0) {
        // Update session with new email
        await _sessionService.createSession(
          updatedUser.email,
          updatedUser.fullName,
        );

        setState(() {
          _successMessage =
              'Email berhasil diubah! Harap dicatat bahwa favorit dan item keranjang Anda mungkin direset karena perubahan email.';
          _errorMessage = null;
          _newEmailController.clear();
          _currentPasswordController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(
              seconds: 4,
            ), // Longer duration for important message
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onEmailChangedSuccessfully(); // Callback to refresh parent
        Navigator.pop(context); // Go back to account settings page
      } else {
        setState(() {
          _errorMessage = 'Gagal mengubah email. Silakan coba lagi.';
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
      appBar: AppBar(title: const Text('Ubah Email')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Email Saat Ini: ${widget.currentUser.email}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),
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

              // Success message is shown via SnackBar now.
              TextFormField(
                controller: _newEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email Baru',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan email baru';
                  }
                  if (!RegExp(
                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                  ).hasMatch(value)) {
                    return 'Masukkan format email yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password Saat Ini (untuk verifikasi)',
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed:
                        () => setState(
                          () => _isPasswordObscure = !_isPasswordObscure,
                        ),
                  ),
                ),
                obscureText: _isPasswordObscure,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan password Anda untuk verifikasi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Simpan Email'),
                onPressed: _isLoading ? null : _handleChangeEmail,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Penting: Mengubah alamat email Anda akan memperbarui kredensial login Anda. Item favorit dan isi keranjang belanja Anda terkait dengan alamat email Anda sebelumnya dan mungkin tidak terbawa.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[800],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
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
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }
}
