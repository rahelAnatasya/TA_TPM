import 'package:flutter/material.dart';
import 'package:tpm_flora/models/user.dart';
import 'package:tpm_flora/services/session_service.dart';
import 'package:tpm_flora/database/database_helper.dart';

class EditProfilePage extends StatefulWidget {
  final User currentUser;
  final VoidCallback onProfileUpdated;

  const EditProfilePage({
    Key? key,
    required this.currentUser,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _imageUrlController;
  late TextEditingController _addressController; // Ditambahkan
  bool _isLoading = false;
  String? _errorMessage;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.currentUser.fullName,
    );
    _imageUrlController = TextEditingController(
      text: widget.currentUser.imageUrl ?? '',
    );
    _addressController = TextEditingController(
      text: widget.currentUser.address ?? '', // Ditambahkan
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        User updatedUser = User(
          id: widget.currentUser.id,
          fullName: _fullNameController.text,
          email: widget.currentUser.email,
          password: widget.currentUser.password,
          imageUrl:
              _imageUrlController.text.isNotEmpty
                  ? _imageUrlController.text
                  : null,
          address:
              _addressController.text.isNotEmpty
                  ? _addressController.text
                  : null, // Ditambahkan
        );

        int result = await _dbHelper.updateUser(updatedUser);

        if (!mounted) return;

        if (result > 0) {
          if (widget.currentUser.fullName != updatedUser.fullName) {
            await _sessionService.createSession(
              updatedUser.email,
              updatedUser.fullName,
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onProfileUpdated();
          Navigator.pop(context);
        } else {
          setState(() {
            _errorMessage = 'Gagal memperbarui profil. Silakan coba lagi.';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline),
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
              const SizedBox(height: 20),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'URL Foto Profil (Opsional)',
                  prefixIcon: const Icon(Icons.image_outlined),
                  hintText: 'https://example.com/image.png',
                  suffixIcon:
                      _imageUrlController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _imageUrlController.clear();
                              setState(() {});
                            },
                          )
                          : null,
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final uri = Uri.tryParse(value);
                    if (uri == null ||
                        !uri.isAbsolute ||
                        (uri.scheme != 'http' && uri.scheme != 'https')) {
                      return 'Masukkan URL yang valid (http/https)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              if (_imageUrlController.text.isNotEmpty &&
                  Uri.tryParse(_imageUrlController.text)?.isAbsolute == true &&
                  (Uri.tryParse(_imageUrlController.text)?.scheme == 'http' ||
                      Uri.tryParse(_imageUrlController.text)?.scheme ==
                          'https'))
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(_imageUrlController.text),
                      onBackgroundImageError: (exception, stackTrace) {},
                      child:
                          Uri.tryParse(_imageUrlController.text) == null ||
                                  !Uri.tryParse(
                                    _imageUrlController.text,
                                  )!.isAbsolute
                              ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[400],
                              )
                              : null,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // Address TextFormField (Ditambahkan)
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat (Opsional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'Jl. Merdeka No. 10, Kota Bahagia',
                ),
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 3,
                // Validator is optional
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: const Icon(Icons.save_outlined),
                label:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text('Simpan Perubahan'),
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
    _fullNameController.dispose();
    _imageUrlController.dispose();
    _addressController.dispose(); // Ditambahkan
    super.dispose();
  }
}
