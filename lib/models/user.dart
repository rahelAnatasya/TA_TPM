class User {
  final int? id;
  final String fullName; // Ditambahkan
  final String email;
  final String
  password; // Dalam aplikasi nyata, simpan password yang sudah di-hash

  User({
    this.id,
    required this.fullName, // Ditambahkan
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName, // Ditambahkan
      'email': email,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      fullName: map['fullName'] as String? ?? '', // Ditambahkan, tangani null
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}
