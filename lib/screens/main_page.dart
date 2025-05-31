// lib/screens/main_page.dart
import 'package:flutter/material.dart';
import 'package:tpm_flora/models/plant.dart';
import 'package:tpm_flora/services/api_service.dart';
import 'package:tpm_flora/services/favorite_service.dart';
import 'package:tpm_flora/services/cart_service.dart';
import 'package:tpm_flora/screens/plant_detail.dart';
import 'package:tpm_flora/screens/plant_form.dart';
import '../database/database_helper.dart';

class MainPage extends StatefulWidget {
  final VoidCallback? onNavigateToCart; // Add this callback

  const MainPage({super.key, this.onNavigateToCart}); // Modify constructor

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<List<Plant>> _plantsFuture;
  final bool _isAdmin = true; // Assuming admin status for now
  final FavoriteService _favoriteService = FavoriteService();
  final CartService _cartService = CartService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<int> _favoritePlantIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _plantsFuture = _fetchAndAugmentPlants();
      });
    }
    _loadInitialFavorites(); // This can run in parallel
  }

  Future<List<Plant>> _fetchAndAugmentPlants() async {
    try {
      List<dynamic> apiPlantsJson = await ApiService.getPlants();
      List<Plant> plants =
          apiPlantsJson.map((json) => Plant.fromJson(json)).toList();

      for (var plant in plants) {
        if (plant.id != null) {
          plant.localImageUrl = await _dbHelper.getLocalPlantImageUrl(
            plant.id!,
          );
        }
      }
      return plants;
    } catch (e) {
      print("Error di _fetchAndAugmentPlants: $e");
      throw Exception("Gagal memuat data tanaman utama: $e");
    }
  }

  Future<void> _loadInitialFavorites() async {
    _favoritePlantIds = await _favoriteService.getFavoritePlantIds();
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite(int plantId) async {
    bool isCurrentlyFavorite = _favoritePlantIds.contains(plantId);
    if (isCurrentlyFavorite) {
      await _favoriteService.removeFavorite(plantId);
      _favoritePlantIds.remove(plantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dihapus dari favorit'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      await _favoriteService.addFavorite(plantId);
      _favoritePlantIds.add(plantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ditambahkan ke favorit!'),
            backgroundColor: Colors.pinkAccent,
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _addToCart(Plant plant) async {
    if (plant.id == null) return;
    if (plant.stock_quantity == null || plant.stock_quantity! <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plant.name ?? "Tanaman"} ini habis terjual.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }
    await _cartService.addItemToCart(plant.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plant.name ?? "Tanaman"} ditambahkan ke keranjang!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Lihat',
            onPressed: () {
              widget.onNavigateToCart?.call(); // Use the callback here
            },
          ),
        ),
      );
    }
  }

  void _navigateToAddPlant() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlantForm(onSuccess: _loadData)),
    ).then((_) => _loadData());
  }

  void _editPlant(Plant plant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantForm(plant: plant, onSuccess: _loadData),
      ),
    ).then((_) => _loadData());
  }

  void _deletePlant(BuildContext context, int? id) async {
    if (id == null) return;

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Tanaman'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus tanaman ini? Ini juga akan menghapus URL gambar lokalnya.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await ApiService.deletePlant(id);
        await _dbHelper.deleteLocalPlantImageUrl(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanaman berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menghapus tanaman: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: FutureBuilder<List<Plant>>(
        future: _plantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 50),
                    const SizedBox(height: 10),
                    Text(
                      'Gagal memuat data tanaman: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      onPressed: _loadData,
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grass_outlined, color: Colors.grey[700], size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada tanaman yang dijual.',
                    style: TextStyle(fontSize: 16),
                  ),
                  if (_isAdmin) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Tambah Tanaman Baru'),
                      onPressed: _navigateToAddPlant,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          } else {
            final List<Plant> plantItems = snapshot.data!;

            return Column(
              children: [
                if (_isAdmin)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Tambah Tanaman Baru'),
                      onPressed: _navigateToAddPlant,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      childAspectRatio: 0.70, // Adjusted for more buttons
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: plantItems.length,
                    itemBuilder: (context, index) {
                      final plant = plantItems[index];
                      final bool isFavorite = _favoritePlantIds.contains(
                        plant.id,
                      );

                      final String? displayImageUrl =
                          plant.localImageUrl ?? plant.image_url;

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 3.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlantDetail(plant: plant),
                              ),
                            ).then((_) => _loadData());
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Hero(
                                  tag: 'plant_image_grid_${plant.id}',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                    ),
                                    child:
                                        displayImageUrl != null &&
                                                displayImageUrl.isNotEmpty
                                            ? ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      10,
                                                    ),
                                                    topRight: Radius.circular(
                                                      10,
                                                    ),
                                                  ),
                                              child: Image.network(
                                                displayImageUrl,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  );
                                                },
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Icon(
                                                    Icons
                                                        .local_florist_outlined,
                                                    size: 40,
                                                    color: Colors.grey[400],
                                                  );
                                                },
                                              ),
                                            )
                                            : Icon(
                                              Icons.local_florist_outlined,
                                              size: 40,
                                              color: Colors.grey[400],
                                            ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 6.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plant.name ?? 'Tanpa Nama',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Rp${(plant.price ?? 0)}",
                                      style: TextStyle(
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (plant.stock_quantity != null &&
                                        plant.stock_quantity! <= 0)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2.0),
                                        child: Text(
                                          "Habis",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Action buttons section
                              Container(
                                color: Colors.grey[50],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                  vertical: 0,
                                ),
                                child:
                                    _isAdmin
                                        ? Column(
                                          // Admin view with two rows of buttons
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Expanded(
                                                  child: IconButton(
                                                    icon: Icon(
                                                      isFavorite
                                                          ? Icons.favorite
                                                          : Icons
                                                              .favorite_border,
                                                      color:
                                                          isFavorite
                                                              ? Colors
                                                                  .pinkAccent[400]
                                                              : Colors
                                                                  .grey[500],
                                                      size: 18,
                                                    ),
                                                    tooltip:
                                                        isFavorite
                                                            ? 'Hapus dari Favorit'
                                                            : 'Tambah ke Favorit',
                                                    onPressed:
                                                        () => _toggleFavorite(
                                                          plant.id!,
                                                        ),
                                                    splashRadius: 16,
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons
                                                          .add_shopping_cart_outlined,
                                                      color:
                                                          Colors
                                                              .blueAccent[700],
                                                      size: 18,
                                                    ),
                                                    tooltip:
                                                        'Tambah ke Keranjang',
                                                    onPressed:
                                                        (plant.stock_quantity !=
                                                                    null &&
                                                                plant.stock_quantity! >
                                                                    0)
                                                            ? () => _addToCart(
                                                              plant,
                                                            )
                                                            : null,
                                                    splashRadius: 16,
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Expanded(
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.edit_outlined,
                                                      color:
                                                          Colors
                                                              .orangeAccent[700],
                                                      size: 16,
                                                    ),
                                                    tooltip: 'Edit',
                                                    onPressed:
                                                        () => _editPlant(plant),
                                                    splashRadius: 16,
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      color:
                                                          Colors.redAccent[700],
                                                      size: 16,
                                                    ),
                                                    tooltip: 'Hapus',
                                                    onPressed:
                                                        () => _deletePlant(
                                                          context,
                                                          plant.id,
                                                        ),
                                                    splashRadius: 16,
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                        : Row(
                                          // Non-admin view with one row of buttons
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Expanded(
                                              child: IconButton(
                                                icon: Icon(
                                                  isFavorite
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color:
                                                      isFavorite
                                                          ? Colors
                                                              .pinkAccent[400]
                                                          : Colors.grey[500],
                                                  size: 20,
                                                ),
                                                tooltip:
                                                    isFavorite
                                                        ? 'Hapus dari Favorit'
                                                        : 'Tambah ke Favorit',
                                                onPressed:
                                                    () => _toggleFavorite(
                                                      plant.id!,
                                                    ),
                                                splashRadius: 18,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            ),
                                            Expanded(
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons
                                                      .add_shopping_cart_outlined,
                                                  color: Colors.blueAccent[700],
                                                  size: 20,
                                                ),
                                                tooltip: 'Tambah ke Keranjang',
                                                onPressed:
                                                    (plant.stock_quantity !=
                                                                null &&
                                                            plant.stock_quantity! >
                                                                0)
                                                        ? () =>
                                                            _addToCart(plant)
                                                        : null,
                                                splashRadius: 18,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
