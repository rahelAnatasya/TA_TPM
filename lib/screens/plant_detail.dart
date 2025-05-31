import 'package:flutter/material.dart';
import 'package:tpm_flora/screens/purchase_page.dart';
import '../models/plant.dart';
import 'plant_form.dart';
import '../utils/string_extensions.dart';
import '../services/favorite_service.dart';
import '../services/cart_service.dart';
import '../database/database_helper.dart'; // Import DatabaseHelper

class PlantDetail extends StatefulWidget {
  final Plant
  plant; // Terima Plant object yang sudah di-augment jika memungkinkan

  const PlantDetail({Key? key, required this.plant}) : super(key: key);

  @override
  State<PlantDetail> createState() => _PlantDetailState();
}

class _PlantDetailState extends State<PlantDetail> {
  final FavoriteService _favoriteService = FavoriteService();
  final CartService _cartService = CartService();
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Instance DatabaseHelper
  bool _isFavorite = false;
  String? _displayImageUrl; // Untuk menyimpan URL yang akan ditampilkan

  @override
  void initState() {
    super.initState();
    // Jika widget.plant.localImageUrl sudah diisi oleh MainPage, kita bisa langsung gunakan
    // Jika tidak, kita muat di sini.
    if (widget.plant.localImageUrl != null) {
      _displayImageUrl = widget.plant.localImageUrl;
    } else if (widget.plant.id != null) {
      _loadLocalImageUrlForDetail(widget.plant.id!);
    } else {
      _displayImageUrl = widget.plant.image_url; // Fallback ke URL API
    }
    _checkIfFavorite();
  }

  Future<void> _loadLocalImageUrlForDetail(int plantId) async {
    String? localUrl = await _dbHelper.getLocalPlantImageUrl(plantId);
    if (mounted) {
      setState(() {
        // Prioritaskan URL lokal, baru URL dari API (jika ada di widget.plant)
        _displayImageUrl = localUrl ?? widget.plant.image_url;
      });
    }
  }

  Future<void> _checkIfFavorite() async {
    if (widget.plant.id == null) return;
    bool favoriteStatus = await _favoriteService.isFavorite(widget.plant.id!);
    if (mounted) {
      setState(() {
        _isFavorite = favoriteStatus;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    // ... (logika toggle favorit tetap sama)
    if (widget.plant.id == null) return;
    if (_isFavorite) {
      await _favoriteService.removeFavorite(widget.plant.id!);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dihapus dari favorit'),
            backgroundColor: Colors.orange,
          ),
        );
    } else {
      await _favoriteService.addFavorite(widget.plant.id!);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ditambahkan ke favorit!'),
            backgroundColor: Colors.pinkAccent,
          ),
        );
    }
    _checkIfFavorite();
  }

  Future<void> _addToCart() async {
    // ... (logika tambah ke keranjang tetap sama)
    if (widget.plant.id == null) return;
    if (widget.plant.stock_quantity == null ||
        widget.plant.stock_quantity! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.plant.name ?? "Tanaman"} ini habis terjual.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    await _cartService.addItemToCart(widget.plant.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.plant.name ?? "Tanaman"} ditambahkan ke keranjang!',
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Lihat',
            onPressed: () {
              // Navigasi ke tab keranjang
            },
          ),
        ),
      );
    }
  }

  void _refreshDataOnReturn() {
    // Panggil semua yang perlu di-refresh saat kembali dari PlantForm
    _checkIfFavorite();
    if (widget.plant.id != null) {
      _loadLocalImageUrlForDetail(widget.plant.id!);
    }
    // Jika data tanaman lain (harga, stok) juga bisa berubah, perlu muat ulang widget.plant
    // Ini bisa lebih kompleks, mungkin memerlukan callback dari PlantForm dengan data terbaru
    // atau memuat ulang seluruh detail tanaman dari API + DB.
    // Untuk sekarang, kita fokus pada gambar dan favorit.
    setState(() {}); // Memicu rebuild
  }

  @override
  Widget build(BuildContext context) {
    // URL gambar yang akan ditampilkan, prioritaskan _displayImageUrl yang sudah dimuat
    final String? currentDisplayImageUrl =
        _displayImageUrl ?? widget.plant.image_url;

    return Scaffold(
      appBar: AppBar(
        // ... (AppBar tetap sama)
        title: Text(widget.plant.name ?? 'Detail Tanaman'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border_outlined,
              color: _isFavorite ? Colors.pinkAccent : Colors.white,
            ),
            tooltip: _isFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Tanaman',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PlantForm(
                        plant: widget.plant, // Kirim plant yang ada
                        onSuccess: () {
                          // Callback ini akan dipanggil dari PlantForm
                          Navigator.pop(context); // Tutup PlantForm
                          _refreshDataOnReturn(); // Panggil metode refresh di sini
                        },
                      ),
                ),
              ).then(
                (_) => _refreshDataOnReturn(),
              ); // Juga refresh saat kembali dengan swipe/tombol back
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'plant_image_grid_${widget.plant.id}',
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.40,
                color: Colors.green[100],
                child:
                    currentDisplayImageUrl != null &&
                            currentDisplayImageUrl.isNotEmpty
                        ? Image.network(
                          currentDisplayImageUrl, // Gunakan URL yang sudah diputuskan
                          fit: BoxFit.cover,
                          // ... (errorBuilder tetap sama)
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.broken_image_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                        )
                        : const Icon(
                          Icons.local_florist_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
              ),
            ),
            // ... (Sisa UI PlantDetail tetap sama, gunakan widget.plant untuk data lain)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.plant.name ?? 'Tanpa Nama',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Rp${(widget.plant.price ?? 0)}',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (widget.plant.stock_quantity != null &&
                      widget.plant.stock_quantity! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Stok: ${widget.plant.stock_quantity} unit tersedia',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else if (widget.plant.stock_quantity == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Habis Terjual',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  _buildSectionTitle(context, 'Deskripsi'),
                  Text(
                    widget.plant.description ?? 'Tidak ada deskripsi.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Informasi Tanaman'),
                  _buildInfoRow(
                    'Kategori Ukuran:',
                    widget.plant.size_category?.capitalizeFirstLetter() ?? '-',
                  ),
                  _buildInfoRow(
                    'Dimensi:',
                    widget.plant.size_dimensions ?? '-',
                  ),
                  _buildInfoRow(
                    'Intensitas Cahaya:',
                    widget.plant.light_intensity?.capitalizeFirstLetter() ??
                        '-',
                  ),
                  _buildInfoRow(
                    'Kategori Harga:',
                    widget.plant.price_category?.capitalizeFirstLetter() ?? '-',
                  ),
                  _buildInfoRow(
                    'Berbunga:',
                    (widget.plant.has_flowers ?? false) ? 'Ya' : 'Tidak',
                  ),
                  _buildInfoRow(
                    'Daya Tahan Indoor:',
                    widget.plant.indoor_durability?.capitalizeFirstLetter() ??
                        '-',
                  ),

                  if (widget.plant.placements != null &&
                      widget.plant.placements!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Penempatan Ideal'),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children:
                          widget.plant.placements!
                              .map(
                                (p) => Chip(
                                  label: Text(
                                    p
                                        .replaceAll('_', ' ')
                                        .capitalizeFirstLetter(),
                                  ),
                                  backgroundColor: Colors.green[100],
                                  labelStyle: TextStyle(
                                    color: Colors.green[800],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        // ... (BottomNavigationBar tetap sama)
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Tambah Keranjang'),
                onPressed:
                    (widget.plant.stock_quantity != null &&
                            widget.plant.stock_quantity! > 0)
                        ? _addToCart
                        : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Beli Sekarang'),
                onPressed:
                    (widget.plant.stock_quantity != null &&
                            widget.plant.stock_quantity! > 0)
                        ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PurchasePage(plant: widget.plant),
                            ),
                          );
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    // ... (Section title tetap sama)
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.green[800],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    // ... (Info row tetap sama)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
