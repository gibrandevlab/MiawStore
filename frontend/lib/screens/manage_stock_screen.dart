import 'package:flutter/material.dart';
import '../services/admin_service.dart';

// --- PALET WARNA ---
const Color kColorDarkBrown = Color(0xFF9D5C0D);
const Color kColorVibrantOrange = Color(0xFFE5890A);
const Color kColorSoftYellow = Color(0xFFF7D08A);
const Color kColorWhiteCream = Color(0xFFFAFAFA);
const Color kColorRedAlert = Color(0xFFD32F2F);
const Color kColorGreenSuccess = Color(0xFF388E3C);

class ManageStockScreen extends StatefulWidget {
  const ManageStockScreen({super.key});

  @override
  State<ManageStockScreen> createState() => _ManageStockScreenState();
}

class _ManageStockScreenState extends State<ManageStockScreen> {
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
      final list = await _svc.getAllStocks();
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

  // --- UPDATE STOCK (MODAL SHEET) ---
  Future<void> _showUpdateSheet(Map<String, dynamic> item) async {
    final currentQty = (item['quantity'] ?? 0);
    final productName = item['product']?['name'] ?? 'Unknown Product';
    
    // Controller untuk input manual
    final tQty = TextEditingController(text: currentQty.toString());
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Update Stok',
                              style: TextStyle(
                                fontSize: 14, 
                                color: Colors.grey,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              productName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kColorDarkBrown,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 30),

                  // Input Area dengan Tombol +/-
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tombol Kurang
                      _buildCircleBtn(Icons.remove, () {
                        int val = int.tryParse(tQty.text) ?? 0;
                        if (val > 0) {
                          val--;
                          tQty.text = val.toString();
                          setModalState(() {}); // Update tampilan modal
                        }
                      }),

                      const SizedBox(width: 20),

                      // Input Field Tengah
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: tQty,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            color: kColorDarkBrown
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Tombol Tambah
                      _buildCircleBtn(Icons.add, () {
                        int val = int.tryParse(tQty.text) ?? 0;
                        val++;
                        tQty.text = val.toString();
                        setModalState(() {});
                      }),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Tombol Simpan
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
                        final newQty = int.tryParse(tQty.text) ?? 0;
                        try {
                          Navigator.pop(ctx); // Tutup dulu
                          await _updateStockProcess(item['productId'], newQty);
                        } catch (e) {
                           // Error handled in process
                        }
                      },
                      child: const Text(
                        'SIMPAN PERUBAHAN',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // Proses update terpisah agar bersih
  Future<void> _updateStockProcess(dynamic productId, int newQty) async {
    if(mounted) setState(() => _loading = true);
    try {
      await _svc.updateStock(productId, newQty);
      await _fetch();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok berhasil diupdate!'),
            backgroundColor: kColorDarkBrown,
          ),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
       if(mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhiteCream,
      body: Stack(
        children: [
          // 1. Blob Background Decoration
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: kColorSoftYellow.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Content List
          _loading
            ? const Center(child: CircularProgressIndicator(color: kColorVibrantOrange))
            : _items.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: kColorVibrantOrange,
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final s = _items[i];
                      return _buildStockCard(s);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildStockCard(Map<String, dynamic> item) {
    final product = item['product'] ?? {};
    final qty = (item['quantity'] ?? 0) as int;
    final isLowStock = qty <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLowStock 
          ? Border.all(color: kColorRedAlert.withValues(alpha: 0.3), width: 1)
          : null,
        boxShadow: [
          BoxShadow(
            color: isLowStock 
               ? kColorRedAlert.withValues(alpha: 0.05)
               : kColorDarkBrown.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isLowStock 
                ? kColorRedAlert.withValues(alpha: 0.1)
                : kColorGreenSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
              color: isLowStock ? kColorRedAlert : kColorGreenSuccess,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kColorDarkBrown,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLowStock ? kColorRedAlert.withValues(alpha: 0.1) : kColorSoftYellow.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isLowStock ? 'Low Stock' : 'In Stock',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isLowStock ? kColorRedAlert : kColorDarkBrown,
                    ),
                  ),
                )
              ],
            ),
          ),

          // Quantity Display & Edit Button
          InkWell(
            onTap: () => _showUpdateSheet(item),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kColorWhiteCream,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '$qty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isLowStock ? kColorRedAlert : kColorDarkBrown,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper tombol bulat (+ / -)
  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kColorWhiteCream,
          border: Border.all(color: kColorSoftYellow),
        ),
        child: Icon(icon, color: kColorDarkBrown),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shelves, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Data stok kosong",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}