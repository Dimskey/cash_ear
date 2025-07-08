import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';

class SalesScreen extends StatefulWidget {
  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _selectedCategory = 'Semua';
  String _paymentMethod = 'Tunai';

  @override
  Widget build(BuildContext context) {
    final products = Provider.of<ProductProvider>(context);
    final sales = Provider.of<SalesProvider>(context);

    List<String> categories = ['Semua'] + 
        products.products.map((p) => p.category).toSet().toList();
    
    List<ProductModel> filteredProducts = _selectedCategory == 'Semua'
        ? products.products
        : products.products.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Penjualan'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${sales.currentCart.length}'),
              child: Icon(Icons.shopping_cart),
            ),
            onPressed: () => _showCart(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: Colors.brown[100],
                    checkmarkColor: Colors.brown[700],
                  ),
                );
              },
            ),
          ),

          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _buildProductCard(product, sales);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: sales.currentCart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCart(context),
              icon: Icon(Icons.shopping_cart),
              label: Text('Keranjang (${sales.currentCart.length})'),
              backgroundColor: Colors.brown[700],
            )
          : null,
    );
  }

  Widget _buildProductCard(ProductModel product, SalesProvider sales) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showAddToCartDialog(product, sales),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.fastfood, size: 48, color: Colors.brown[300]);
                      },
                    )
                  : Icon(Icons.fastfood, size: 48, color: Colors.brown[300]),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Rp ${NumberFormat('#,###').format(product.price)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        'Stok: ${product.stock}',
                        style: TextStyle(
                          color: product.isLowStock ? Colors.red : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToCartDialog(ProductModel product, SalesProvider sales) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produk tidak tersedia')),
      );
      return;
    }

    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Tambah ke Keranjang'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(product.name),
                  SizedBox(height: 8),
                  Text('Rp ${NumberFormat('#,###').format(product.price)}'),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: quantity > 1 ? () {
                          setState(() {
                            quantity--;
                          });
                        } : null,
                        icon: Icon(Icons.remove),
                      ),
                      Text(
                        '$quantity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: quantity < product.stock ? () {
                          setState(() {
                            quantity++;
                          });
                        } : null,
                        icon: Icon(Icons.add),
                      ),
                    ],
                  ),
                  Text('Total: Rp ${NumberFormat('#,###').format(product.price * quantity)}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    sales.addToCart(product, quantity);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ditambahkan ke keranjang')),
                    );
                  },
                  child: Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCart(BuildContext context) {
    final sales = Provider.of<SalesProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    String paymentMethod = _paymentMethod;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<SalesProvider>(
          builder: (context, sales, child) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Keranjang',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              sales.clearCart();
                              Navigator.pop(context);
                            },
                            child: Text('Hapus Semua'),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Cart Items
                      Expanded(
                        child: sales.currentCart.isEmpty
                            ? Center(child: Text('Keranjang kosong'))
                            : ListView.builder(
                                itemCount: sales.currentCart.length,
                                itemBuilder: (context, index) {
                                  final item = sales.currentCart[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(item.productName),
                                      subtitle: Text('Rp ${NumberFormat('#,###').format(item.price)}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              sales.updateCartQuantity(item.productId, item.quantity - 1);
                                            },
                                            icon: Icon(Icons.remove),
                                          ),
                                          Text('${item.quantity}'),
                                          IconButton(
                                            onPressed: () {
                                              sales.updateCartQuantity(item.productId, item.quantity + 1);
                                            },
                                            icon: Icon(Icons.add),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              sales.removeFromCart(item.productId);
                                            },
                                            icon: Icon(Icons.delete, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Total and Payment
                      if (sales.currentCart.isNotEmpty) ...[
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total:'),
                            Text(
                              'Rp ${NumberFormat('#,###').format(sales.cartTotal)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Payment Method
                        Row(
                          children: [
                            Text('Pembayaran: '),
                            DropdownButton<String>(
                              value: paymentMethod,
                              items: ['Tunai', 'Kartu', 'Transfer'].map((method) {
                                return DropdownMenuItem(
                                  value: method,
                                  child: Text(method),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  paymentMethod = value!;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              bool success = await sales.processSale(
                                auth.currentUser!.id,
                                paymentMethod,
                              );
                              if (success) {
                                await productProvider.loadProducts();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Transaksi berhasil')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Transaksi gagal')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[700],
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text('Bayar', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}