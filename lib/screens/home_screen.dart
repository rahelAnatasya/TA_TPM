// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:tpm_flora/screens/main_page.dart';
import 'package:tpm_flora/screens/favorites_page.dart';
import 'package:tpm_flora/screens/cart_page.dart';
import 'package:tpm_flora/screens/profile_page.dart';
import 'package:tpm_flora/services/session_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = "Pengguna";
  final SessionService _sessionService = SessionService();

  // Make _widgetOptions an instance variable
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _loadUserName();

    // Initialize _widgetOptions here to pass the callback
    _widgetOptions = <Widget>[
      MainPage(
        onNavigateToCart: () => _onItemTapped(2),
      ), // Pass callback to MainPage
      const FavoritesPage(),
      const CartPage(), // Index 2
      const ProfilePage(),
    ];
  }

  Future<void> _loadUserName() async {
    String? fullName = await _sessionService.getLoggedInUserFullName();
    if (fullName != null && fullName.isNotEmpty) {
      if (mounted) {
        setState(() {
          _userName = fullName.split(' ').first;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Selamat Datang, $_userName!';
      case 1:
        return 'Tanaman Favorit';
      case 2:
        return 'Keranjang Belanja';
      case 3:
        return 'Profil Saya';
      default:
        return 'Flora Plant Store';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_selectedIndex)),
        automaticallyImplyLeading: false,
        actions:
            _selectedIndex == 0
                ? [
                  // Admin-only Add button is within MainPage itself.
                ]
                : null,
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Toko',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 8.0,
      ),
    );
  }
}
