import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/api_service.dart';
import 'plant_detail.dart';
import 'plant_form.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<List<dynamic>> _plantsFuture;
  bool _isAdmin =
      true; // For demonstration purposes, set to true to allow management functionality

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  void _loadPlants() {
    setState(() {
      _plantsFuture = ApiService.getPlants();
    });
  }

  void _navigateToAddPlant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantForm(onSuccess: _loadPlants),
      ),
    );
  }

  void _editPlant(Plant plant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantForm(plant: plant, onSuccess: _loadPlants),
      ),
    );
  }

  void _deletePlant(BuildContext context, int? id) {
    if (id == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Plant'),
          content: const Text('Are you sure you want to delete this plant?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ApiService.deletePlant(id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plant deleted successfully')),
                  );
                  _loadPlants();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting plant: ${e.toString()}'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Flora Plant Store"),
        backgroundColor: Colors.green[700],
        actions:
            _isAdmin
                ? [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _navigateToAddPlant,
                    tooltip: 'Add New Plant',
                  ),
                ]
                : null,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _plantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No plants found.'));
          } else {
            final List<dynamic> plantItemsJson = snapshot.data!;
            final List<Plant> plantItems =
                plantItemsJson.map((json) => Plant.fromJson(json)).toList();

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: plantItems.length,
              itemBuilder: (context, index) {
                final plant = plantItems[index];
                return Stack(
                  children: [
                    // The plant card
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlantDetail(plant: plant),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                color: Colors.green[100],
                                width: double.infinity,
                                child:
                                    plant.image_url != null &&
                                            plant.image_url!.isNotEmpty
                                        ? Image.network(
                                          plant.image_url!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                            );
                                          },
                                        )
                                        : const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                        ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plant.name ?? 'No Name',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Rp${(plant.price ?? 0).toStringAsFixed(0)}", // Assuming price is an int
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Admin controls (Edit & Delete)
                    if (_isAdmin)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.blue,
                                onPressed: () => _editPlant(plant),
                                tooltip: 'Edit',
                                visualDensity: VisualDensity.compact,
                                splashRadius: 20,
                              ),
                              // Delete button
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                color: Colors.red,
                                onPressed:
                                    () => _deletePlant(context, plant.id),
                                tooltip: 'Delete',
                                visualDensity: VisualDensity.compact,
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}
