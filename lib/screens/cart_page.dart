// lib/screens/cart_page.dart
import 'package:flutter/material.dart';
import 'package:tpm_flora/models/plant.dart';
import 'package:tpm_flora/services/cart_service.dart';
import 'package:tpm_flora/screens/plant_detail.dart'; // Untuk navigasi
import 'package:tpm_flora/utils/string_extensions.dart'; // Untuk capitalizeFirstLetter
import 'package:tpm_flora/database/database_helper.dart';
import 'package:tpm_flora/services/session_service.dart';
import 'package:tpm_flora/models/user.dart';
import 'package:tpm_flora/screens/purchase_history_page.dart';
import 'package:tpm_flora/services/api_service.dart'; // Ditambahkan untuk update stok

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SessionService _sessionService = SessionService();
  final ApiService _apiService = ApiService(); // Ditambahkan

  late Future<List<Map<String, dynamic>>> _cartItemsFuture;
  late Future<double> _totalPriceFuture;
  bool _isProcessingCheckout = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    if (!mounted) return;
    setState(() {
      _cartItemsFuture = _cartService.getCartItemsWithDetails();
      _totalPriceFuture = _cartService.getTotalPrice();
    });
  }

  Future<void> _updateQuantity(int plantId, int newQuantity) async {
    if (!mounted) return;
    await _cartService.updateItemQuantity(plantId, newQuantity);
    _loadCart();
  }

  Future<void> _removeFromCart(int plantId) async {
    if (!mounted) return;
    await _cartService.removeItemFromCart(plantId);
    _loadCart();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanaman dihapus dari keranjang'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearCart() async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Kosongkan Keranjang?'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus semua item dari keranjang?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                'Ya, Hapus',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _cartService.clearCart();
      _loadCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keranjang telah dikosongkan'),
            backgroundColor: Colors.blueAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _proceedToCheckout(
    double totalPrice,
    List<Map<String, dynamic>> cartItemsDetails,
  ) async {
    if (!mounted) return;
    if (totalPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang Anda kosong.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isProcessingCheckout) return;

    setState(() {
      _isProcessingCheckout = true;
    });

    User? currentUser = await _sessionService.getCurrentUser();
    if (currentUser == null || currentUser.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: Pengguna tidak ditemukan. Silakan login ulang.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isProcessingCheckout = false;
        });
      }
      return;
    }

    final List<Map<String, dynamic>> orderItemsForDb =
        cartItemsDetails.map((itemDetail) {
          final Plant plant = itemDetail['plant'] as Plant;
          final int quantity = itemDetail['quantity'] as int;
          return {
            'plantId': plant.id,
            'plantName': plant.name ?? 'Nama Tanaman Tidak Diketahui',
            'quantity': quantity,
            'priceAtPurchase': plant.price?.toDouble() ?? 0.0,
          };
        }).toList();

    String? orderId;
    try {
      orderId = await _dbHelper.insertOrder(
        userId: currentUser.id!,
        totalAmount: totalPrice,
        shippingAddress: 'Alamat Pengiriman Default (Contoh dari Keranjang)',
        status: 'Selesai',
        items: orderItemsForDb,
      );

      // Setelah order lokal berhasil, coba update stok di API
      for (var itemDetail in cartItemsDetails) {
        final Plant orderedPlant = itemDetail['plant'] as Plant;
        final int quantityOrdered = itemDetail['quantity'] as int;

        if (orderedPlant.id != null && orderedPlant.stock_quantity != null) {
          int newStock = orderedPlant.stock_quantity! - quantityOrdered;
          if (newStock < 0) newStock = 0;

          Plant plantForApiUpdate = Plant(
            id: orderedPlant.id,
            name: orderedPlant.name,
            description: orderedPlant.description,
            price: orderedPlant.price,
            size_category: orderedPlant.size_category,
            size_dimensions: orderedPlant.size_dimensions,
            light_intensity: orderedPlant.light_intensity,
            price_category: orderedPlant.price_category,
            has_flowers: orderedPlant.has_flowers,
            indoor_durability: orderedPlant.indoor_durability,
            placements: orderedPlant.placements,
            stock_quantity: newStock,
          );

          try {
            await ApiService.updatePlant(plantForApiUpdate); //
            print(
              'Successfully updated stock for plant ID ${orderedPlant.id} to $newStock',
            );
          } catch (e) {
            print('Failed to update stock for plant ID ${orderedPlant.id}: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pesanan dicatat. Gagal sinkronisasi stok untuk ${orderedPlant.name}.',
                  ),
                  backgroundColor: Colors.orangeAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      }

      await _cartService.clearCart();
      _loadCart();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Checkout Berhasil! (Simulasi)'),
            content: Text(
              'Pesanan Anda (ID: ${orderId?.substring(0, 8)}...) senilai Rp${totalPrice.toStringAsFixed(0)} telah dicatat.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Lihat Riwayat'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseHistoryPage(),
                    ),
                  );
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      print("Error during checkout from cart (local order insertion): $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses checkout: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingCheckout = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method remains largely the same, ensure buttons are disabled with _isProcessingCheckout)
    // Example for checkout button:
    // onPressed: _isProcessingCheckout || cartItemsDetails.isEmpty ? null : () => _proceedToCheckout(totalPrice, cartItemsDetails),

    // Build method from previous correct step is suitable here, just ensure relevant buttons check _isProcessingCheckout.
    // For brevity, I'm not repeating the entire build method. The logic above is the key change.
    // The existing build method already has checks for _isProcessingCheckout on buttons.
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cartItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_isProcessingCheckout) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal memuat keranjang belanja.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      onPressed: _isProcessingCheckout ? null : _loadCart,
                    ),
                  ],
                ),
              ),
            );
          } else if ((!snapshot.hasData || snapshot.data!.isEmpty) &&
              !_isProcessingCheckout) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Keranjang belanja Anda kosong.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Yuk, cari tanaman impianmu!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          } else {
            final cartItemsDetails = snapshot.data ?? [];
            return Column(
              children: [
                if (_isProcessingCheckout) const LinearProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Item: ${cartItemsDetails.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                        label: const Text('Kosongkan'),
                        onPressed:
                            cartItemsDetails.isNotEmpty &&
                                    !_isProcessingCheckout
                                ? _clearCart
                                : null,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    itemCount: cartItemsDetails.length,
                    itemBuilder: (context, index) {
                      final itemDetail = cartItemsDetails[index];
                      final Plant plant = itemDetail['plant'] as Plant;
                      final int quantity = itemDetail['quantity'] as int;
                      final String? displayImageUrl =
                          plant.localImageUrl ?? plant.image_url;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70,
                                height: 70,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child:
                                      displayImageUrl != null &&
                                              displayImageUrl.isNotEmpty
                                          ? Image.network(
                                            displayImageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => const Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.grey,
                                                  size: 30,
                                                ),
                                            loadingBuilder: (
                                              context,
                                              child,
                                              loadingProgress,
                                            ) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              );
                                            },
                                          )
                                          : const Icon(
                                            Icons.local_florist_outlined,
                                            color: Colors.grey,
                                            size: 30,
                                          ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap:
                                          _isProcessingCheckout
                                              ? null
                                              : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            PlantDetail(
                                                              plant: plant,
                                                            ),
                                                  ),
                                                ).then((_) {
                                                  if (!_isProcessingCheckout) {
                                                    _loadCart();
                                                  }
                                                });
                                              },
                                      child: Text(
                                        plant.name ?? 'Nama Tidak Tersedia',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Rp${plant.price?.toString() ?? 'N/A'}',
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 22,
                                          ),
                                          onPressed:
                                              _isProcessingCheckout
                                                  ? null
                                                  : quantity > 1
                                                  ? () => _updateQuantity(
                                                    plant.id!,
                                                    quantity - 1,
                                                  )
                                                  : () => _removeFromCart(
                                                    plant.id!,
                                                  ),
                                          color: Colors.red[600],
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Text(
                                            '$quantity',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 22,
                                          ),
                                          onPressed:
                                              _isProcessingCheckout
                                                  ? null
                                                  : () {
                                                    if (plant.stock_quantity ==
                                                            null ||
                                                        quantity <
                                                            plant
                                                                .stock_quantity!) {
                                                      _updateQuantity(
                                                        plant.id!,
                                                        quantity + 1,
                                                      );
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Stok maksimal untuk ${plant.name} telah tercapai.',
                                                          ),
                                                          backgroundColor:
                                                              Colors
                                                                  .orangeAccent,
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                        ),
                                                      );
                                                    }
                                                  },
                                          color: Colors.green[700],
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey[600],
                                ),
                                tooltip: 'Hapus dari Keranjang',
                                onPressed:
                                    _isProcessingCheckout
                                        ? null
                                        : () => _removeFromCart(plant.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
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
                  child: FutureBuilder<double>(
                    future: _totalPriceFuture,
                    builder: (context, priceSnapshot) {
                      if (priceSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !_isProcessingCheckout) {
                        return const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final totalPrice = priceSnapshot.data ?? 0.0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Harga:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Rp${totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            icon:
                                _isProcessingCheckout
                                    ? Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.payment_outlined),
                            label: Text(
                              _isProcessingCheckout
                                  ? 'MEMPROSES...'
                                  : 'Checkout',
                            ),
                            onPressed:
                                _isProcessingCheckout ||
                                        cartItemsDetails.isEmpty
                                    ? null
                                    : () => _proceedToCheckout(
                                      totalPrice,
                                      cartItemsDetails,
                                    ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(fontSize: 16),
                              disabledBackgroundColor:
                                  _isProcessingCheckout
                                      ? Colors.orange[700]
                                      : Colors.grey[400],
                            ),
                          ),
                        ],
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
