import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _shownLowStockDialog = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_shownLowStockDialog) {
      final products = Provider.of<ProductProvider>(context, listen: false);
      final lowStockProducts = products.products.where((p) => p.stock <= 5).toList();
      if (lowStockProducts.isNotEmpty) {
        _shownLowStockDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Stok Rendah!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Produk berikut stoknya rendah:'),
                  ...lowStockProducts.map((p) => Text('${p.name} (Stok: ${p.stock})')),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tutup'),
                ),
              ],
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final products = Provider.of<ProductProvider>(context);
    final sales = Provider.of<SalesProvider>(context);
    
    final isAdmin = auth.isAdmin;
    print('DEBUG ROLE: [33m${auth.currentUser?.role}[0m');
    print('DEBUG isAdmin: [33m$isAdmin[0m');
    final today = DateTime.now();
    final todayRevenue = sales.getDailyRevenue(today);
    final todayProfit = sales.getDailyProfit(today);
    final lowStockCount = products.lowStockProducts.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await products.loadProducts();
          await sales.loadSales();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.brown[600]!, Colors.brown[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      auth.currentUser != null
                        ? (auth.currentUser!.email.split('@').first)
                        : 'User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      isAdmin ? 'Admin Dashboard' : 'Kasir Dashboard',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Statistik (tampilkan untuk semua role)
              Text(
                'Statistik Hari Ini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Pendapatan',
                      'Rp ${NumberFormat('#,###').format(todayRevenue)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Keuntungan',
                      'Rp ${NumberFormat('#,###').format(todayProfit)}',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Produk',
                      '${products.products.length}',
                      Icons.inventory,
                      Colors.purple,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Stok Rendah',
                      '$lowStockCount',
                      Icons.warning,
                      lowStockCount > 0 ? Colors.red : Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              SizedBox(height: 24),

              // Recent Sales
              Text(
                'Transaksi Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              SizedBox(height: 12),
              
              if (sales.sales.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Belum ada transaksi hari ini'),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: sales.sales.take(5).length,
                  itemBuilder: (context, index) {
                    final sale = sales.sales[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown[100],
                          child: Icon(Icons.receipt, color: Colors.brown[700]),
                        ),
                        title: Text('Transaksi #${sale.id.substring(0, 8)}'),
                        subtitle: Text(
                          '${sale.items.length} item • ${DateFormat('HH:mm').format(sale.createdAt)}',
                        ),
                        trailing: Text(
                          'Rp ${NumberFormat('#,###').format(sale.total)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}