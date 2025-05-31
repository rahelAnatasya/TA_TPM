// lib/services/favorite_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/plant.dart';
import 'api_service.dart';
import 'session_service.dart'; // Untuk mendapatkan email pengguna saat ini
import '../database/database_helper.dart'; // Import DatabaseHelper

class FavoriteService {
  final SessionService _sessionService = SessionService();
  final DatabaseHelper _dbHelper =
      DatabaseHelper(); // Instantiate DatabaseHelper

  Future<String> _getFavoritesKey() async {
    String? userEmail = await _sessionService.getLoggedInUserEmail();
    if (userEmail == null || userEmail.isEmpty) {
      print("Peringatan: Email pengguna tidak ditemukan untuk kunci favorit.");
      return 'favoritePlantIds_guest';
    }
    return 'favoritePlantIds_$userEmail';
  }

  Future<List<int>> getFavoritePlantIds() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getFavoritesKey();
    final String? favoriteIdsString = prefs.getString(key);
    if (favoriteIdsString != null) {
      List<String> stringIds = List<String>.from(
        json.decode(favoriteIdsString),
      );
      return stringIds.map((id) => int.parse(id)).toList();
    }
    return [];
  }

  Future<void> addFavorite(int plantId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getFavoritesKey();
    List<int> favoriteIds = await getFavoritePlantIds();
    if (!favoriteIds.contains(plantId)) {
      favoriteIds.add(plantId);
      await prefs.setString(
        key,
        json.encode(favoriteIds.map((id) => id.toString()).toList()),
      );
    }
  }

  Future<void> removeFavorite(int plantId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getFavoritesKey();
    List<int> favoriteIds = await getFavoritePlantIds();
    if (favoriteIds.contains(plantId)) {
      favoriteIds.remove(plantId);
      await prefs.setString(
        key,
        json.encode(favoriteIds.map((id) => id.toString()).toList()),
      );
    }
  }

  Future<bool> isFavorite(int plantId) async {
    List<int> favoriteIds = await getFavoritePlantIds();
    return favoriteIds.contains(plantId);
  }

  Future<List<Plant>> getFavoritePlantsDetails() async {
    List<int> favoriteIds = await getFavoritePlantIds();
    List<Plant> favoritePlants = [];
    if (favoriteIds.isEmpty) return [];

    try {
      List<dynamic> allPlantsJson = await ApiService.getPlants();
      List<Plant> allPlants =
          allPlantsJson.map((json) => Plant.fromJson(json)).toList();

      for (int id in favoriteIds) {
        final plantIndex = allPlants.indexWhere((p) => p.id == id);
        if (plantIndex != -1) {
          Plant plant = allPlants[plantIndex];
          // Augment with local image URL
          if (plant.id != null) {
            plant.localImageUrl = await _dbHelper.getLocalPlantImageUrl(
              plant.id!,
            );
          }
          favoritePlants.add(plant);
        }
      }
    } catch (e) {
      print("Error fetching or augmenting plants for favorites: $e");
    }
    return favoritePlants;
  }
}
