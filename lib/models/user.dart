class User {
  final int? id;
  final String fullName;
  final String email;
  final String password; // In a real app, simpan password yang sudah di-hash
  final String? imageUrl;
  final String? address; // Ditambahkan: Alamat pengguna

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.password,
    this.imageUrl,
    this.address, // Ditambahkan
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
      'imageUrl': imageUrl,
      'address': address, // Ditambahkan
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String,
      password: map['password'] as String,
      imageUrl: map['imageUrl'] as String?,
      address: map['address'] as String?, // Ditambahkan
    );
  }
}
