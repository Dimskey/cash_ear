import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import 'dashboard_screen.dart';
import 'sales_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);

    await productProvider.loadProducts();
    await salesProvider.loadSales();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.isAdmin;

    List<Widget> screens = [
      DashboardScreen(),
      if (!isAdmin) SalesScreen(),
      if (!isAdmin) ReportsScreen(),
      if (isAdmin) ProductsScreen(),
      if (isAdmin) ReportsScreen(),
      ProfileScreen(),
    ];

    List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      if (!isAdmin)
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale),
          label: 'Penjualan',
        ),
      if (!isAdmin)
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Laporan',
        ),
      if (isAdmin)
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Produk',
        ),
      if (isAdmin)
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Laporan',
        ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.brown[700],
        unselectedItemColor: Colors.grey,
        items: navItems,
      ),
    );
  }
}
