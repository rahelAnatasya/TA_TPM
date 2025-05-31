import 'package:flutter/material.dart';
import 'dart:convert'; // Import untuk jsonEncode (untuk debug print)
import '../models/plant.dart';
import '../services/api_service.dart';
import '../utils/string_extensions.dart';
import '../database/database_helper.dart';

class PlantForm extends StatefulWidget {
  final Plant? plant;
  final VoidCallback onSuccess;

  const PlantForm({Key? key, this.plant, required this.onSuccess})
    : super(key: key);

  @override
  State<PlantForm> createState() => _PlantFormState();
}

class _PlantFormState extends State<PlantForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _selectedPlacements = [];

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  String? _selectedSizeCategory;
  late TextEditingController _sizeDimensionsController;
  String? _selectedLightIntensity;
  String? _selectedPriceCategory;
  late bool _hasFlowers;
  String? _selectedIndoorDurability;
  late TextEditingController _stockQuantityController;
  late TextEditingController _imageUrlController;
  late bool _isActiveForm;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  final List<String> _sizeCategoryOptions = ['meja', 'sedang', 'besar'];
  final List<String> _lightIntensityOptions = ['rendah', 'sedang', 'tinggi'];
  final List<String> _priceCategoryOptions = [
    'ekonomis',
    'standard',
    'premium',
  ];
  final List<String> _indoorDurabilityOptions = ['rendah', 'sedang', 'tinggi'];
  final List<String> _placementTypeOptions = [
    'meja_kerja',
    'meja_resepsionis',
    'pagar',
    'toilet',
    'ruang_tamu',
    'kamar_tidur',
    'dapur',
    'balkon',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plant?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.plant?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.plant?.price?.toString() ?? '',
    );
    _sizeDimensionsController = TextEditingController(
      text: widget.plant?.size_dimensions ?? '',
    );
    _hasFlowers = widget.plant?.has_flowers ?? false;
    _stockQuantityController = TextEditingController(
      text: widget.plant?.stock_quantity?.toString() ?? '',
    );
    // _isActiveForm diinisialisasi dari widget.plant.is_active (yang mungkin null jika API GET tidak mengirimnya)
    // Jika API GET tidak mengirim is_active, maka widget.plant.is_active akan null,
    // dan _isActiveForm akan menjadi true. Ini hanya untuk UI form.
    _isActiveForm = widget.plant?.is_active ?? true;

    _imageUrlController = TextEditingController();
    if (widget.plant != null) {
      if (widget.plant!.id != null) {
        _loadInitialImageUrl(widget.plant!.id!, widget.plant!.image_url);
      } else {
        _imageUrlController.text = widget.plant!.image_url ?? '';
      }
    } else {
      _imageUrlController.text = '';
    }

    _selectedSizeCategory = widget.plant?.size_category;
    if (_selectedSizeCategory != null &&
        !_sizeCategoryOptions.contains(_selectedSizeCategory)) {
      _selectedSizeCategory = null;
    }
    _selectedLightIntensity = widget.plant?.light_intensity;
    if (_selectedLightIntensity != null &&
        !_lightIntensityOptions.contains(_selectedLightIntensity)) {
      _selectedLightIntensity = null;
    }
    _selectedPriceCategory = widget.plant?.price_category;
    if (_selectedPriceCategory != null &&
        !_priceCategoryOptions.contains(_selectedPriceCategory)) {
      _selectedPriceCategory = null;
    }
    _selectedIndoorDurability = widget.plant?.indoor_durability;
    if (_selectedIndoorDurability != null &&
        !_indoorDurabilityOptions.contains(_selectedIndoorDurability)) {
      _selectedIndoorDurability = null;
    }

    if (widget.plant?.placements != null) {
      _selectedPlacements = List<String>.from(
        widget.plant!.placements!.where(
          (p) => _placementTypeOptions.contains(p),
        ),
      );
    }

    _imageUrlController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadInitialImageUrl(
    int plantId,
    String? apiUrlFromPlantObject,
  ) async {
    String? localUrl = await _dbHelper.getLocalPlantImageUrl(plantId);
    if (mounted) {
      setState(() {
        _imageUrlController.text = localUrl ?? apiUrlFromPlantObject ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sizeDimensionsController.dispose();
    _stockQuantityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Membuat objek Plant hanya dengan field yang relevan untuk API
      // Metode toJson() di model Plant akan menjadi filter akhir.
      Plant plantDataForApi = Plant(
        // Untuk UPDATE, ID akan digunakan oleh ApiService untuk URL, bukan di body.
        // Untuk CREATE, ID akan null dan di-generate server.
        id: widget.plant?.id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: int.tryParse(_priceController.text),
        size_category: _selectedSizeCategory,
        size_dimensions:
            _sizeDimensionsController.text.isEmpty
                ? null
                : _sizeDimensionsController.text,
        light_intensity: _selectedLightIntensity,
        price_category: _selectedPriceCategory,
        has_flowers: _hasFlowers,
        indoor_durability: _selectedIndoorDurability,
        stock_quantity: int.tryParse(_stockQuantityController.text),
        placements: _selectedPlacements.isEmpty ? null : _selectedPlacements,
        // image_url, is_active, created_at, updated_at, localImageUrl tidak di-set di sini
        // karena akan diurus oleh toJson() atau tidak relevan untuk payload API.
      );

      Map<String, dynamic> apiResponse;
      String successMessage;
      int? plantIdForDb = widget.plant?.id;

      // --- DEBUG PAYLOAD ---
      final String jsonPayload = jsonEncode(plantDataForApi);
      print("====== JSON Payload to API ======");
      print(jsonPayload);
      print("================================");
      // --- AKHIR DEBUG PAYLOAD ---

      if (widget.plant == null) {
        apiResponse = await ApiService.addPlant(plantDataForApi);
        successMessage =
            apiResponse['message'] as String? ?? 'Tanaman berhasil ditambahkan';
        if (apiResponse['success'] == true &&
            apiResponse['data'] != null &&
            apiResponse['data']['id'] != null) {
          plantIdForDb = apiResponse['data']['id'];
        } else if (apiResponse['success'] != true) {
          throw Exception(
            apiResponse['error']?['message'] ??
                apiResponse['message'] ??
                'Gagal menambahkan tanaman via API',
          );
        }
      } else {
        apiResponse = await ApiService.updatePlant(plantDataForApi);
        successMessage =
            apiResponse['message'] as String? ?? 'Tanaman berhasil diperbarui';
        if (apiResponse['success'] != true) {
          // Ambil pesan error lebih detail jika ada
          String errorDetails = "";
          if (apiResponse['error'] != null &&
              apiResponse['error']['details'] != null) {
            errorDetails =
                " Details: ${jsonEncode(apiResponse['error']['details'])}";
          }
          throw Exception(
            (apiResponse['error']?['message'] ??
                    apiResponse['message'] ??
                    'Gagal memperbarui tanaman via API') +
                errorDetails,
          );
        }
      }

      if (plantIdForDb != null) {
        if (_imageUrlController.text.isNotEmpty) {
          await _dbHelper.upsertLocalPlantImageUrl(
            plantIdForDb,
            _imageUrlController.text,
          );
        } else {
          await _dbHelper.deleteLocalPlantImageUrl(plantIdForDb);
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
      );

      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green[800],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plant == null ? 'Tambah Tanaman Baru' : 'Edit Tanaman',
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[700]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      _buildSectionTitle('Informasi Dasar'),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Tanaman*',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Masukkan nama tanaman';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi*',
                          alignLabelWithHint: true,
                        ),
                        minLines: 3,
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Masukkan deskripsi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Harga (Rp)*',
                                prefixText: 'Rp ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Masukkan harga';
                                if (int.tryParse(value) == null)
                                  return 'Harga tidak valid';
                                if (int.parse(value) < 0)
                                  return 'Harga tidak boleh negatif';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stockQuantityController,
                              decoration: const InputDecoration(
                                labelText: 'Stok*',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Masukkan stok';
                                if (int.tryParse(value) == null)
                                  return 'Stok tidak valid';
                                if (int.parse(value) < 0)
                                  return 'Stok tidak boleh negatif';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL Gambar (Lokal/Online)',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final uri = Uri.tryParse(value);
                            if (uri == null ||
                                !uri.isAbsolute ||
                                (uri.scheme != 'http' &&
                                    uri.scheme != 'https')) {
                              return 'Masukkan URL yang valid (http/https)';
                            }
                          }
                          return null;
                        },
                      ),
                      if (_imageUrlController.text.isNotEmpty &&
                          Uri.tryParse(_imageUrlController.text)?.isAbsolute ==
                              true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _imageUrlController.text,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Text('URL Gambar Tidak Valid'),
                                    ),
                                  ),
                            ),
                          ),
                        ),

                      _buildSectionTitle('Karakteristik Tanaman'),
                      DropdownButtonFormField<String>(
                        value: _selectedSizeCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Ukuran*',
                        ),
                        items:
                            _sizeCategoryOptions
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(val.capitalizeFirstLetter()),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) =>
                                setState(() => _selectedSizeCategory = val),
                        validator:
                            (value) => value == null ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sizeDimensionsController,
                        decoration: const InputDecoration(
                          labelText: 'Dimensi Ukuran (cth: 10x15 cm)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedLightIntensity,
                        decoration: const InputDecoration(
                          labelText: 'Intensitas Cahaya*',
                        ),
                        items:
                            _lightIntensityOptions
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(val.capitalizeFirstLetter()),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) =>
                                setState(() => _selectedLightIntensity = val),
                        validator:
                            (value) => value == null ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPriceCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Harga*',
                        ),
                        items:
                            _priceCategoryOptions
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(val.capitalizeFirstLetter()),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) =>
                                setState(() => _selectedPriceCategory = val),
                        validator:
                            (value) => value == null ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedIndoorDurability,
                        decoration: const InputDecoration(
                          labelText: 'Daya Tahan Indoor*',
                        ),
                        items:
                            _indoorDurabilityOptions
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(val.capitalizeFirstLetter()),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) =>
                                setState(() => _selectedIndoorDurability = val),
                        validator:
                            (value) => value == null ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Berbunga'),
                        value: _hasFlowers,
                        onChanged: (val) => setState(() => _hasFlowers = val),
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.green[600],
                      ),
                      SwitchListTile(
                        title: const Text('Aktif (Tampil di Toko)'),
                        value: _isActiveForm,
                        onChanged: (val) => setState(() => _isActiveForm = val),
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.green[600],
                      ),

                      _buildSectionTitle('Penempatan yang Cocok'),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 0.0,
                        children:
                            _placementTypeOptions.map((placement) {
                              return SizedBox(
                                width:
                                    (MediaQuery.of(context).size.width / 2) -
                                    30,
                                child: CheckboxListTile(
                                  title: Text(
                                    placement
                                        .replaceAll('_', ' ')
                                        .capitalizeFirstLetter(),
                                  ),
                                  value: _selectedPlacements.contains(
                                    placement,
                                  ),
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _selectedPlacements.add(placement);
                                      } else {
                                        _selectedPlacements.remove(placement);
                                      }
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  activeColor: Colors.green[600],
                                ),
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            widget.plant == null
                                ? Icons.add_circle_outline
                                : Icons.save_outlined,
                          ),
                          label: Text(
                            widget.plant == null
                                ? 'Tambah Tanaman'
                                : 'Simpan Perubahan',
                          ),
                          onPressed: _handleSubmit,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }
}
