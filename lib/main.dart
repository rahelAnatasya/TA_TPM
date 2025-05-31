import 'package:flutter/material.dart';
import 'package:tpm_flora/screens/login_page.dart';
import 'package:tpm_flora/screens/home_screen.dart'; // Import HomeScreen
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SessionService sessionService = SessionService();
  bool isLoggedIn = await sessionService.isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flora Plant App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green[700]!,
          primary: Colors.green[700],
          secondary: Colors.amber[600],
          surface: Colors.green[50],
          background: Colors.white,
          error: Colors.red[700],
        ),
        scaffoldBackgroundColor: Colors.green[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          // Menggunakan CardThemeData
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.green[700]!, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          floatingLabelStyle: TextStyle(color: Colors.green[700]),
          prefixIconColor: MaterialStateColor.resolveWith(
            (states) =>
                states.contains(MaterialState.focused)
                    ? Colors.green[700]!
                    : Colors.grey[600]!,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.green[800],
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 8.0,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home:
          isLoggedIn
              ? const HomeScreen()
              : const LoginPage(), // Arahkan ke HomeScreen jika login
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(), // Rute untuk HomeScreen
        // '/main': (context) => const MainPage(), // MainPage sekarang bagian dari HomeScreen
      },
    );
  }
}
