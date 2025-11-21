import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; <-- BARIS INI KITA HAPUS AGAR TIDAK ERROR
import '../services/admin_service.dart';

// --- PALET WARNA ---
const Color kColorDarkBrown = Color(0xFF9D5C0D);
const Color kColorVibrantOrange = Color(0xFFE5890A);
const Color kColorSoftYellow = Color(0xFFF7D08A);
const Color kColorWhiteCream = Color(0xFFFAFAFA);

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final AdminService _svc = AdminService();
  List<dynamic> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    try {
      final list = await _svc.getProducts();
      if (!mounted) return;
      setState(() => _items = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForm([Map<String, dynamic>? item]) async {
    final formKey = GlobalKey<FormState>();
    final tName =
        TextEditingController(text: item != null ? item['name'] ?? '' : '');
    final tDesc = TextEditingController(
        text: item != null ? item['description'] ?? '' : '');
    final tPrice = TextEditingController(
        text: item != null ? (item['price']?.toString() ?? '') : '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item == null ? 'Tambah Produk' : 'Edit Produk',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kColorDarkBrown,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    _buildTextField(
                        tName, 'Nama Produk', Icons.shopping_bag_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(
                        tDesc, 'Deskripsi', Icons.description_outlined,
                        maxLines: 2),
                    const SizedBox(height: 16),
                    _buildTextField(tPrice, 'Harga (Rp)', Icons.attach_money,
                        isNumber: true),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kColorVibrantOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final payload = {
                              'name': tName.text.trim(),
                              'description': tDesc.text.trim(),
                              'price': double.tryParse(tPrice.text) ?? 0.0
                            };

                            Navigator.pop(ctx);
                            _submitData(item, payload);
                          }
                        },
                        child: const Text(
                          'SIMPAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitData(
      Map<String, dynamic>? item, Map<String, dynamic> payload) async {
    if (mounted) setState(() => _loading = true);

    try {
      if (item == null) {
        await _svc.createProduct(payload);
      } else {
        await _svc.updateProduct(item['id'].toString(), payload);
      }
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil menyimpan produk!'),
            backgroundColor: kColorDarkBrown,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Produk"),
        content: const Text("Yakin ingin menghapus produk ini?"),
        actions: [
          TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(ctx, false)),
          TextButton(
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _svc.deleteProduct(id);
        await _fetch();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhiteCream,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kColorVibrantOrange,
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Produk",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // 1. Background Decoration
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                // PERBAIKAN 1: Ganti withOpacity jadi withValues
                color: kColorSoftYellow.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Content
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: kColorVibrantOrange))
              : _items.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: kColorVibrantOrange,
                      onRefresh: _fetch,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final p = _items[i];
                          return _buildProductCard(p);
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // PERBAIKAN 2: Ganti withOpacity jadi withValues
            color: kColorDarkBrown.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              // PERBAIKAN 3: Ganti withOpacity jadi withValues
              color: kColorSoftYellow.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: kColorDarkBrown, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Tanpa Nama',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kColorDarkBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rp ${item['price'] ?? '0'}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kColorVibrantOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'] ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            children: [
              InkWell(
                onTap: () => _showForm(item),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // PERBAIKAN 4: Ganti withOpacity jadi withValues
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _delete(item['id'].toString()),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // PERBAIKAN 5: Ganti withOpacity jadi withValues
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, size: 18, color: Colors.red),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: kColorDarkBrown),
        filled: true,
        fillColor: kColorWhiteCream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kColorVibrantOrange, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '$label tidak boleh kosong';
        return null;
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Belum ada produk",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
