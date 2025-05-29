import 'package:flutter/material.dart';
import '../models/plant.dart';
import 'plant_form.dart';

class PlantDetail extends StatelessWidget {
  final Plant plant;

  const PlantDetail({Key? key, required this.plant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name ?? 'Detail Tanaman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to favorites')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PlantForm(
                        plant: plant,
                        onSuccess: () {
                          Navigator.pop(context);
                        },
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 250,
              child:
                  plant.image_url != null && plant.image_url!.isNotEmpty
                      ? Image.network(
                        plant.image_url!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                            ),
                          );
                        },
                      )
                      : Container(
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 50),
                      ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plant.name ?? 'Nama Tidak Tersedia',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'Rp ${(plant.price ?? 0).toString()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plant.description ?? 'Deskripsi tidak tersedia.',
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Informasi Tanaman',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Kategori Ukuran', plant.size_category ?? '-'),
                  _buildInfoRow('Dimensi', plant.size_dimensions ?? '-'),
                  _buildInfoRow(
                    'Intensitas Cahaya',
                    plant.light_intensity ?? '-',
                  ),
                  _buildInfoRow('Kategori Harga', plant.price_category ?? '-'),
                  _buildInfoRow(
                    'Memiliki Bunga',
                    (plant.has_flowers ?? false) ? 'Ya' : 'Tidak',
                  ),
                  _buildInfoRow(
                    'Daya Tahan Indoor',
                    plant.indoor_durability ?? '-',
                  ),
                  _buildInfoRow(
                    'Stok',
                    '${(plant.stock_quantity ?? 0).toString()} unit',
                  ),

                  const SizedBox(height: 24),

                  if (plant.placements != null &&
                      plant.placements!.isNotEmpty) ...[
                    const Text(
                      'Cocok Ditempatkan Di',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          plant.placements!
                              .map(
                                (placement) => Chip(
                                  label: Text(placement),
                                  backgroundColor: Colors.green[100],
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(children: [
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
          ],
        ),
      ),
    );
  }

  String valueToDisplay(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Ya' : 'Tidak';
    return value.toString();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
