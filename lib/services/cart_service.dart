// lib/services/cart_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/plant.dart';
import 'api_service.dart';
import 'session_service.dart'; // Untuk mendapatkan email pengguna saat ini
import '../database/database_helper.dart'; // Import DatabaseHelper

class CartItem {
  final int plantId;
  int quantity;

  CartItem({required this.plantId, required this.quantity});

  Map<String, dynamic> toJson() => {'plantId': plantId, 'quantity': quantity};

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      CartItem(plantId: json['plantId'], quantity: json['quantity']);
}

class CartService {
  final SessionService _sessionService = SessionService();
  final DatabaseHelper _dbHelper =
      DatabaseHelper(); // Instantiate DatabaseHelper

  Future<String> _getCartKey() async {
    String? userEmail = await _sessionService.getLoggedInUserEmail();
    if (userEmail == null || userEmail.isEmpty) {
      print(
        "Peringatan: Email pengguna tidak ditemukan untuk kunci keranjang.",
      );
      return 'cartItems_guest';
    }
    return 'cartItems_$userEmail';
  }

  Future<List<CartItem>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getCartKey();
    final String? cartItemsString = prefs.getString(key);
    if (cartItemsString != null) {
      List<dynamic> decodedList = json.decode(cartItemsString);
      return decodedList.map((item) => CartItem.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> _saveCartItems(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getCartKey();
    String encodedData = json.encode(
      items.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(key, encodedData);
  }

  Future<void> addItemToCart(int plantId, {int quantity = 1}) async {
    List<CartItem> items = await getCartItems();
    try {
      CartItem existingItem = items.firstWhere(
        (item) => item.plantId == plantId,
      );
      existingItem.quantity += quantity;
    } catch (e) {
      items.add(CartItem(plantId: plantId, quantity: quantity));
    }
    await _saveCartItems(items);
  }

  Future<void> updateItemQuantity(int plantId, int newQuantity) async {
    List<CartItem> items = await getCartItems();
    try {
      CartItem itemToUpdate = items.firstWhere(
        (item) => item.plantId == plantId,
      );
      if (newQuantity > 0) {
        itemToUpdate.quantity = newQuantity;
      } else {
        items.removeWhere((item) => item.plantId == plantId);
      }
    } catch (e) {
      // Item tidak ditemukan
    }
    await _saveCartItems(items);
  }

  Future<void> removeItemFromCart(int plantId) async {
    List<CartItem> items = await getCartItems();
    items.removeWhere((item) => item.plantId == plantId);
    await _saveCartItems(items);
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getCartKey();
    await prefs.remove(key);
  }

  Future<double> getTotalPrice() async {
    List<CartItem> cartItems = await getCartItems();
    if (cartItems.isEmpty) return 0.0;
    double totalPrice = 0;

    List<Plant> allPlants = [];
    try {
      List<dynamic> allPlantsJson = await ApiService.getPlants();
      allPlants = allPlantsJson.map((json) => Plant.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching all plants for cart total: $e");
      return 0;
    }

    for (CartItem cartItem in cartItems) {
      try {
        final plant = allPlants.firstWhere(
          (p) => p.id == cartItem.plantId,
          orElse: () => Plant(id: -1, price: 0),
        );
        if (plant.id != -1 && plant.price != null) {
          totalPrice += (plant.price! * cartItem.quantity);
        }
      } catch (e) {
        print(
          "Error finding plant ID ${cartItem.plantId} in fetched list for total: $e",
        );
      }
    }
    return totalPrice;
  }

  Future<List<Map<String, dynamic>>> getCartItemsWithDetails() async {
    List<CartItem> cartItems = await getCartItems();
    if (cartItems.isEmpty) return [];
    List<Map<String, dynamic>> detailedItems = [];

    List<Plant> allPlants = [];
    try {
      List<dynamic> allPlantsJson = await ApiService.getPlants();
      allPlants = allPlantsJson.map((json) => Plant.fromJson(json)).toList();

      // Augment plants with local image URLs before matching with cart items
      for (var plant in allPlants) {
        if (plant.id != null) {
          plant.localImageUrl = await _dbHelper.getLocalPlantImageUrl(
            plant.id!,
          );
        }
      }
    } catch (e) {
      print("Error fetching or augmenting plants for cart details: $e");
      return [];
    }

    for (CartItem cartItem in cartItems) {
      try {
        // Find the (already augmented) plant from the allPlants list
        final plant = allPlants.firstWhere(
          (p) => p.id == cartItem.plantId,
          orElse: () => Plant(id: -1, name: "Tanaman Tidak Dikenal", price: 0),
        );
        if (plant.id != -1) {
          detailedItems.add({'plant': plant, 'quantity': cartItem.quantity});
        }
      } catch (e) {
        print(
          "Error matching plant ID ${cartItem.plantId} for cart details: $e",
        );
      }
    }
    return detailedItems;
  }
}
