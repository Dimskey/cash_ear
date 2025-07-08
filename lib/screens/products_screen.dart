import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

class ProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AuthProvider>(context).isAdmin;
    return Scaffold(
      appBar: AppBar(title: Text('Produk')),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: \\${provider.error}'));
          }
          if (provider.products.isEmpty) {
            return Center(child: Text('Belum ada produk.'));
          }
          return ListView.builder(
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final product = provider.products[index];
              return Stack(
                children: [
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: product.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.imageUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: Colors.brown),
                            ),
                          )
                        : Icon(Icons.image, size: 40, color: Colors.brown[200]),
                      title: Text(product.name),
                      subtitle: Text('Stok: \\${product.stock} | Harga: \\${product.price}'),
                      trailing: isAdmin ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showProductForm(context, provider, product: product);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Hapus Produk'),
                                  content: Text('Yakin ingin menghapus produk ini?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await provider.deleteProduct(product.id);
                              }
                            },
                          ),
                        ],
                      ) : null,
                    ),
                  ),
                  // Dekorasi icon kopi transparan di pojok kanan atas
                  Positioned(
                    right: 16,
                    top: 8,
                    child: Opacity(
                      opacity: 0.12,
                      child: Icon(Icons.coffee, size: 48, color: Colors.brown),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () {
          final provider = Provider.of<ProductProvider>(context, listen: false);
          _showProductForm(context, provider);
        },
        child: Icon(Icons.add),
        tooltip: 'Tambah Produk',
      ) : null,
    );
  }

  void _showProductForm(BuildContext context, ProductProvider provider, {ProductModel? product}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?.name ?? '');
    final categoryController = TextEditingController(text: product?.category ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final costController = TextEditingController(text: product?.cost.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '');
    String? imageUrl = product?.imageUrl;
    XFile? pickedImage;

    Future<void> pickImage() async {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Izin akses media diperlukan untuk memilih gambar.')),
        );
        return;
      }
      final picker = ImagePicker();
      try {
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          pickedImage = picked;
          // Tidak upload langsung, upload saat simpan produk
          (context as Element).markNeedsBuild();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: \\${e.toString()}')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.brown),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.brown[50],
                      ),
                      child: pickedImage != null
                        ? FutureBuilder<Uint8List>(
                            future: pickedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                return Image.memory(snapshot.data!, fit: BoxFit.cover);
                              } else {
                                return Center(child: CircularProgressIndicator());
                              }
                            },
                          )
                        : (imageUrl != null
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: Colors.brown),
                              )
                            : Icon(Icons.add_a_photo, size: 40, color: Colors.brown)),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Nama Produk'),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: categoryController,
                    decoration: InputDecoration(labelText: 'Kategori'),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Harga'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: costController,
                    decoration: InputDecoration(labelText: 'Modal'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: stockController,
                    decoration: InputDecoration(labelText: 'Stok'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  String? finalImageUrl = imageUrl;
                  if (pickedImage != null) {
                    try {
                      final ref = FirebaseStorage.instance.ref().child('product_images/${DateTime.now().millisecondsSinceEpoch}_${pickedImage!.name}');
                      await ref.putData(await pickedImage!.readAsBytes());
                      finalImageUrl = await ref.getDownloadURL();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal upload gambar: \\${e.toString()}')),
                      );
                      return;
                    }
                  }
                  final newProduct = ProductModel(
                    id: product?.id ?? Uuid().v4(),
                    name: nameController.text,
                    category: categoryController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                    cost: double.tryParse(costController.text) ?? 0,
                    stock: int.tryParse(stockController.text) ?? 0,
                    imageUrl: finalImageUrl,
                    createdAt: product?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  bool success;
                  if (product == null) {
                    success = await provider.addProduct(newProduct);
                  } else {
                    success = await provider.updateProduct(newProduct);
                  }
                  if (success) {
                    Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan produk.')),
                    );
                  }
                }
              },
              child: Text(product == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        );
      },
    );
  }
} 