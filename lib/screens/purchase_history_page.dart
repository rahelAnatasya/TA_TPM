// lib/screens/purchase_history_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Ditambahkan baris ini
import 'package:tpm_flora/database/database_helper.dart';
import 'package:tpm_flora/services/session_service.dart';
import 'package:tpm_flora/models/user.dart';

// Model to hold combined Order and OrderItems data for display
class DisplayOrder {
  final String orderId;
  final DateTime orderDate;
  final double totalAmount;
  final String shippingAddress;
  final String status;
  final List<DisplayOrderItem> items;

  DisplayOrder({
    required this.orderId,
    required this.orderDate,
    required this.totalAmount,
    required this.shippingAddress,
    required this.status,
    required this.items,
  });
}

class DisplayOrderItem {
  final String plantName;
  final int quantity;
  final double priceAtPurchase;
  // final int? plantId; // Optional: if you want to navigate to plant detail from history

  DisplayOrderItem({
    required this.plantName,
    required this.quantity,
    required this.priceAtPurchase,
    // this.plantId,
  });
}

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SessionService _sessionService = SessionService();

  bool _isLoading = true;
  List<DisplayOrder> _purchaseHistory = [];
  String? _errorMessage;
  bool _isDateFormattingInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadHistory();
  }

  Future<void> _initializeAndLoadHistory() async {
    try {
      // Initialize date formatting for 'id_ID' locale
      // This only needs to be done once.
      if (!_isDateFormattingInitialized) {
        await initializeDateFormatting('id_ID', null);
        _isDateFormattingInitialized = true;
      }
    } catch (e) {
      // Handle error if initialization fails, though it's unlikely for a known locale.
      print("Error initializing date formatting: $e");
      if (mounted) {
        setState(() {
          _errorMessage =
              "Gagal menginisialisasi format tanggal: ${e.toString()}";
          _isLoading = false;
        });
        return;
      }
    }
    await _loadPurchaseHistory();
  }

  Future<void> _loadPurchaseHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _purchaseHistory = []; // Clear previous history before loading
    });

    try {
      User? currentUser = await _sessionService.getCurrentUser();
      if (currentUser == null || currentUser.id == null) {
        throw Exception("Pengguna tidak ditemukan atau belum login.");
      }

      List<Map<String, dynamic>> ordersData = await _dbHelper.getOrdersForUser(
        currentUser.id!,
      ); //
      List<DisplayOrder> history = [];

      for (var orderMap in ordersData) {
        List<Map<String, dynamic>> itemsData = await _dbHelper.getOrderItems(
          orderMap['orderId'] as String,
        ); //
        List<DisplayOrderItem> displayItems =
            itemsData
                .map(
                  (itemMap) => DisplayOrderItem(
                    plantName: itemMap['plantName'] as String,
                    quantity: itemMap['quantity'] as int,
                    priceAtPurchase: itemMap['priceAtPurchase'] as double,
                  ),
                )
                .toList();

        history.add(
          DisplayOrder(
            orderId: orderMap['orderId'] as String,
            orderDate: DateTime.parse(orderMap['orderDate'] as String),
            totalAmount: orderMap['totalAmount'] as double,
            shippingAddress: orderMap['shippingAddress'] as String? ?? 'N/A',
            status: orderMap['status'] as String,
            items: displayItems,
          ),
        );
      }
      if (mounted) {
        setState(() {
          _purchaseHistory = history;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat riwayat pembelian: ${e.toString()}";
        });
      }
      print("Error loading purchase history: $e");
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
      appBar: AppBar(
        title: const Text('Riwayat Pembelian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _isLoading
                    ? null
                    : _initializeAndLoadHistory, // Panggil method yang sudah ada inisialisasi
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Coba Lagi"),
                        onPressed:
                            _initializeAndLoadHistory, // Panggil method yang sudah ada inisialisasi
                      ),
                    ],
                  ),
                ),
              )
              : _purchaseHistory.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada riwayat pembelian.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Semua pembelian Anda akan muncul di sini.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Muat Ulang"),
                      onPressed:
                          _initializeAndLoadHistory, // Panggil method yang sudah ada inisialisasi
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh:
                    _initializeAndLoadHistory, // Panggil method yang sudah ada inisialisasi
                child: ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: _purchaseHistory.length,
                  itemBuilder: (context, index) {
                    final order = _purchaseHistory[index];
                    return Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ExpansionTile(
                        key: PageStorageKey(order.orderId),
                        backgroundColor: Colors.white,
                        collapsedBackgroundColor: Colors.white,
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Order ID: ${order.orderId.substring(0, 8)}...',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    order.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor:
                                      order.status == 'Selesai'
                                          ? Colors.green[600]
                                          : order.status == 'Dibatalkan'
                                          ? Colors.red[400]
                                          : Colors.orange[600],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 0,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                            Text(
                              DateFormat(
                                'EEEE, dd MMMM yyyy, HH:mm',
                                'id_ID',
                              ).format(order.orderDate),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            'Total: Rp${NumberFormat("#,##0", "id_ID").format(order.totalAmount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              bottom: 16.0,
                              top: 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  'Detail Item:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (order.items.isEmpty)
                                  const Text(
                                    'Tidak ada item dalam pesanan ini.',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                else
                                  ...order.items
                                      .map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '• ${item.plantName} (x${item.quantity})',
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                'Rp${NumberFormat("#,##0", "id_ID").format(item.priceAtPurchase * item.quantity)}',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                const SizedBox(height: 12),
                                Text(
                                  'Alamat Pengiriman:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  order.shippingAddress,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
