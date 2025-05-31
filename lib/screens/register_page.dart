import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _addressController =
      TextEditingController(); // Ditambahkan
  final _formKey = GlobalKey<FormState>();
  bool _isObscurePassword = true;
  bool _isObscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        User newUser = User(
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          address:
              _addressController.text.isNotEmpty
                  ? _addressController.text
                  : null, // Ditambahkan
          // imageUrl is not provided at registration, will be null by default
        );
        int result = await _dbHelper.registerUser(newUser);

        if (!mounted) return;

        if (result != -1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi berhasil! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          final existingUser = await _dbHelper.getUserByEmail(
            _emailController.text,
          );
          if (existingUser != null) {
            setState(() {
              _errorMessage =
                  'Email sudah terdaftar. Silakan gunakan email lain.';
            });
          } else {
            setState(() {
              _errorMessage = 'Registrasi gagal. Silakan coba lagi.';
            });
          }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Buat Akun Baru'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.green[800]),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.eco_rounded, size: 60, color: Colors.green[700]),
                const SizedBox(height: 12),
                Text(
                  'Selamat Datang di FLORA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Daftar untuk melanjutkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 28),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextFormField(
                  controller: _fullNameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Colors.green[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green[800]!,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan nama lengkap Anda';
                    }
                    if (value.length < 3) {
                      return 'Nama minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Colors.green[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green[800]!,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan email Anda';
                    }
                    if (!RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                    ).hasMatch(value)) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Address TextFormField (Ditambahkan)
                TextFormField(
                  controller: _addressController,
                  keyboardType: TextInputType.streetAddress,
                  decoration: InputDecoration(
                    labelText: 'Alamat (Opsional)',
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: Colors.green[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green[800]!,
                        width: 2,
                      ),
                    ),
                  ),
                  // Validator is optional for an optional field
                  // validator: (value) {
                  //   if (value != null && value.isNotEmpty && value.length < 10) {
                  //     return 'Alamat minimal 10 karakter jika diisi';
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.green[700],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.green[700],
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscurePassword = !_isObscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green[800]!,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan password Anda';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _isObscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.green[700],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.green[700],
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscureConfirmPassword =
                              !_isObscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green[800]!,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password Anda';
                    }
                    if (value != _passwordController.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : const Text(
                            'DAFTAR',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Sudah punya akun?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Login Sekarang',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose(); // Ditambahkan
    super.dispose();
  }
}
