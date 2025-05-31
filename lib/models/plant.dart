// lib/models/plant.dart

class Plant {
  int? id;
  String? name;
  String? description;
  int? price;
  String? size_category;
  String? size_dimensions;
  String? light_intensity;
  String? price_category;
  bool? has_flowers;
  String? indoor_durability;
  int? stock_quantity;
  String?
  image_url; // URL dari API (jika ada saat GET, tidak untuk dikirim saat UPDATE)
  bool?
  is_active; // Status dari API (jika ada saat GET, tidak untuk dikirim saat UPDATE)
  String? created_at;
  String? updated_at;
  List<String>? placements;

  String? localImageUrl;

  Plant({
    this.id,
    this.name,
    this.description,
    this.price,
    this.size_category,
    this.size_dimensions,
    this.light_intensity,
    this.price_category,
    this.has_flowers,
    this.indoor_durability,
    this.stock_quantity,
    this.image_url, // Tetap ada untuk parsing dari GET response API
    this.is_active, // Tetap ada untuk parsing dari GET response API
    this.created_at,
    this.updated_at,
    this.placements,
    this.localImageUrl,
  });

  Plant.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    price = json['price'];
    size_category = json['size_category'];
    size_dimensions = json['size_dimensions'];
    light_intensity = json['light_intensity'];
    price_category = json['price_category'];
    has_flowers = json['has_flowers'];
    indoor_durability = json['indoor_durability'];
    stock_quantity = json['stock_quantity'];
    image_url = json['image_url'];
    is_active =
        json['is_active']; // Akan bernilai null jika tidak ada di JSON response
    created_at = json['created_at'];
    updated_at = json['updated_at'];

    if (json['placements'] != null && json['placements'] is List) {
      placements = List<String>.from(json['placements']);
    } else {
      placements = [];
    }
  }

  // toJson() HANYA menyertakan field yang DITERIMA API untuk CREATE/UPDATE
  // Berdasarkan data API yang Anda berikan, field berikut yang relevan:
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    // Hanya tambahkan field ke map jika nilainya tidak null (atau sesuai kebutuhan API Anda)
    // dan merupakan field yang valid untuk dikirim.
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (size_category != null) data['size_category'] = size_category;
    if (size_dimensions != null)
      data['size_dimensions'] =
          size_dimensions; // Bisa null jika API mengizinkan
    if (light_intensity != null) data['light_intensity'] = light_intensity;
    if (price_category != null) data['price_category'] = price_category;
    if (has_flowers != null) data['has_flowers'] = has_flowers;
    if (indoor_durability != null)
      data['indoor_durability'] = indoor_durability;
    if (stock_quantity != null) data['stock_quantity'] = stock_quantity;
    if (placements != null)
      data['placements'] = placements; // Bisa null jika API mengizinkan

    // Field yang TIDAK BOLEH DIKIRIM ke API saat UPDATE (berdasarkan error Anda):
    // - is_active
    // - image_url (karena Anda bilang API tidak ada tempat untuk ini saat update)
    // - id (biasanya ada di URL path, bukan di body)
    // - created_at, updated_at (dikelola server)
    // - localImageUrl (hanya untuk lokal)

    return data;
  }
}
