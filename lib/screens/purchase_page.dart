import 'package:flutter/material.dart';
import 'package:tpm_flora/database/database_helper.dart';
import 'package:tpm_flora/services/session_service.dart';
import '../models/plant.dart';
import '../models/user.dart';
import 'package:tpm_flora/services/api_service.dart'; // Ditambahkan untuk update stok
import 'package:tpm_flora/screens/purchase_history_page.dart'; // Untuk navigasi ke riwayat

class PurchasePage extends StatefulWidget {
  final Plant plant;

  const PurchasePage({Key? key, required this.plant}) : super(key: key);

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  int _quantity = 1;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SessionService _sessionService = SessionService();
  final ApiService _apiService = ApiService(); // Ditambahkan
  bool _isProcessingPurchase = false;

  void _incrementQuantity() {
    if (_quantity < (widget.plant.stock_quantity ?? 1)) {
      setState(() {
        _quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum stock reached for ${widget.plant.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _confirmPurchase() async {
    if (_isProcessingPurchase) return;

    setState(() {
      _isProcessingPurchase = true;
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
          _isProcessingPurchase = false;
        });
      }
      return;
    }

    final List<Map<String, dynamic>> orderItems = [
      {
        'plantId': widget.plant.id,
        'plantName': widget.plant.name ?? 'Nama Tanaman Tidak Diketahui',
        'quantity': _quantity,
        'priceAtPurchase': widget.plant.price?.toDouble() ?? 0.0,
      },
    ];
    final double totalAmount =
        (widget.plant.price?.toDouble() ?? 0.0) * _quantity;
    String? orderId;

    try {
      orderId = await _dbHelper.insertOrder(
        userId: currentUser.id!,
        totalAmount: totalAmount,
        shippingAddress: 'Alamat Pengiriman Default (Contoh)',
        status: 'Selesai',
        items: orderItems,
      );

      // Setelah order lokal berhasil, coba update stok di API
      if (widget.plant.id != null && widget.plant.stock_quantity != null) {
        int newStock = widget.plant.stock_quantity! - _quantity;
        if (newStock < 0) newStock = 0;

        Plant plantForApiUpdate = Plant(
          id: widget.plant.id,
          name: widget.plant.name,
          description: widget.plant.description,
          price: widget.plant.price,
          size_category: widget.plant.size_category,
          size_dimensions: widget.plant.size_dimensions,
          light_intensity: widget.plant.light_intensity,
          price_category: widget.plant.price_category,
          has_flowers: widget.plant.has_flowers,
          indoor_durability: widget.plant.indoor_durability,
          placements: widget.plant.placements,
          stock_quantity: newStock,
        );

        try {
          await ApiService.updatePlant(plantForApiUpdate); //
          print(
            'Successfully updated stock for plant ID ${widget.plant.id} to $newStock',
          );
          // Optionally update widget.plant state if needed for immediate UI reflection
          // setState(() {
          //   widget.plant.stock_quantity = newStock;
          // });
        } catch (e) {
          print(
            'Failed to update stock for plant ID ${widget.plant.id} from purchase page: $e',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pesanan dicatat. Gagal sinkronisasi stok untuk ${widget.plant.name}.',
                ),
                backgroundColor: Colors.orangeAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Pembelian Berhasil! (Simulasi)'),
            content: Text(
              'Pesanan Anda (ID: ${orderId?.substring(0, 8)}...) untuk $_quantity x ${widget.plant.name ?? 'Tanaman'} senilai Rp${totalAmount.toStringAsFixed(0)} telah dicatat.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Lihat Riwayat'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close this dialog
                  // Navigate to Purchase History Page
                  Navigator.pushReplacement(
                    // Use pushReplacement if you want to remove current PurchasePage from stack
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
                  Navigator.of(dialogContext).pop(); // Close this dialog
                  Navigator.of(context).pop(); // Pop the PurchasePage itself
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      print("Error saving order from purchase page: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan pesanan: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPurchase = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method remains largely the same)
    // Ensure buttons are disabled with _isProcessingPurchase
    // Example for confirm button:
    // onPressed: (widget.plant.stock_quantity != null && widget.plant.stock_quantity! < _quantity) || _isProcessingPurchase ? null : _confirmPurchase,
    // The existing build method already has checks for _isProcessingPurchase and stock.
    final double totalPrice =
        (widget.plant.price?.toDouble() ?? 0.0) * _quantity;

    return Scaffold(
      appBar: AppBar(title: Text('Checkout: ${widget.plant.name ?? 'Plant'}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.plant.image_url != null &&
                        widget.plant.image_url!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.plant.image_url!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      widget.plant.name ?? 'Unnamed Plant',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Harga per unit: Rp${widget.plant.price ?? 0}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.plant.stock_quantity != null)
                      Text(
                        // Display the current stock, which might not reflect API update immediately unless state is managed
                        'Stok Tersedia: ${widget.plant.stock_quantity}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed:
                              _isProcessingPurchase ? null : _decrementQuantity,
                          iconSize: 30,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$_quantity',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed:
                              _isProcessingPurchase ? null : _incrementQuantity,
                          iconSize: 30,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ringkasan Pesanan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                        Text(
                          'Rp${totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ongkos Kirim:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Rp0 (Gratis)', // Simulasi
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Rp${totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:
                    _isProcessingPurchase
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
                  _isProcessingPurchase
                      ? 'MEMPROSES...'
                      : 'Konfirmasi Pembelian (Simulasi)',
                ),
                onPressed:
                    (widget.plant.stock_quantity != null &&
                                widget.plant.stock_quantity! < _quantity) ||
                            _isProcessingPurchase
                        ? null
                        : _confirmPurchase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                  disabledBackgroundColor:
                      _isProcessingPurchase
                          ? Colors.orange[700]
                          : Colors.grey[400],
                ),
              ),
            ),
            if (widget.plant.stock_quantity != null &&
                widget.plant.stock_quantity! < _quantity)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Stok tidak cukup untuk jumlah yang dipilih.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
