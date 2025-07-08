import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/sales_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/products_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBs-72OzQio-CFUKYyyFbdT1CzipO3hP6Y",
        authDomain: "warkop-m.firebaseapp.com",
        projectId: "warkop-m",
        storageBucket: "warkop-m.firebasestorage.app",
        messagingSenderId: "806057164079",
        appId: "1:806057164079:android:b7185b32f27ef1df3775da",
        measurementId: "G-BDWK3LQZBJ",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
      ],
      child: MaterialApp(
        title: 'Warkop Mbak Tata',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          primaryColor: Color(0xFF8B4513),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF8B4513),
            brightness: Brightness.light,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF8B4513),
            foregroundColor: Colors.white,
          ),
        ),
        routes: {
          '/sales': (context) => SalesScreen(),
          '/products': (context) => ProductsScreen(),
        },
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!auth.isAuthenticated) {
              return LoginScreen();
            } else if (auth.currentUser == null || auth.currentUser!.role.isEmpty) {
              return RoleSelectionScreen();
            } else {
              return MainScreen();
            }
          },
        ),
      ),
    );
  }
}