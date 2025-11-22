import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/kasir_service.dart';
import 'login_screen.dart';

// --- KONFIGURASI WARNA BARU ---
class AppColors {
  // Palette dari User
  static const Color darkBrown = Color(0xFF9D5C0D); // Primary Dark / Text
  static const Color vibrantOrange =
      Color(0xFFE5890A); // Primary Action / Button
  static const Color softYellow = Color(0xFFF7D08A); // Accent / Highlight
  static const Color whiteCream = Color(0xFFFAFAFA); // Background

  // Functional Colors
  static const Color cardBg = Colors.white;
  static const Color danger = Color(0xFFDC2626); // Merah untuk Error/Habis
  static const Color success = Color(0xFF16A34A); // Hijau untuk Sukses
  static const Color textMain = Color(
      0xFF5D4037); // Cokelat Tua untuk Teks Utama (supaya tidak hitam pekat)
  static const Color textGrey =
      Color(0xFF8D6E63); // Cokelat muda/abu untuk subtitle
}

class KasirHomeScreen extends StatefulWidget {
  const KasirHomeScreen({super.key});

  @override
  State<KasirHomeScreen> createState() => _KasirHomeScreenState();
}

class _KasirHomeScreenState extends State<KasirHomeScreen> {
  final _api = ApiService().dio;
  final _storage = const FlutterSecureStorage();
  final KasirService _kasir = KasirService();

  int _currentIndex = 0;
  String _username = 'Kasir';

  List<dynamic> _lowStock = [];
  List<dynamic> _products = [];
  List<dynamic> _stocks = [];

  bool _loadingDashboard = true;
  bool _loadingProducts = true;
  bool _loadingStocks = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchDashboard();
    _fetchProducts();
    _fetchStocks();
  }

  // --- HELPER: Notifikasi (SnackBar) ---
  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
                child: Text(msg,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        // Jika error pakai Merah, jika sukses pakai DarkBrown agar elegan
        backgroundColor: isError ? AppColors.danger : AppColors.darkBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 90),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadUser() async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token != null && token.isNotEmpty) {
        final payload = JwtDecoder.decode(token);
        if (!mounted) return;
        setState(() {
          _username = payload['username'] ?? payload['email'] ?? 'Kasir';
        });
      }
    } catch (_) {}
  }

  // --- API CALLS ---
  Future<void> _fetchDashboard() async {
    if (mounted) setState(() => _loadingDashboard = true);
    try {
      final list = await _kasir.getDashboard();
      if (!mounted) return;
      setState(() => _lowStock = list);
    } catch (e) {
      // Silent catch
    } finally {
      if (mounted) setState(() => _loadingDashboard = false);
    }
  }

  Future<void> _fetchProducts() async {
    if (mounted) setState(() => _loadingProducts = true);
    try {
      final resp = await _api.get('/api/products');
      if (!mounted) return;
      setState(() => _products = resp.data as List<dynamic>);
    } catch (e) {
      _showMsg('Gagal memuat produk', isError: true);
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _fetchStocks() async {
    if (mounted) setState(() => _loadingStocks = true);
    try {
      final list = await _kasir.getStocks();
      if (!mounted) return;
      setState(() => _stocks = list);
    } catch (e) {
      _showMsg('Gagal memuat stok', isError: true);
    } finally {
      if (mounted) setState(() => _loadingStocks = false);
    }
  }

  // --- CHECKOUT LOGIC ---
  Future<void> _checkout(BuildContext ctx) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final items = cart.items.entries
        .map((e) =>
            {'productId': int.parse(e.key), 'quantity': e.value['quantity']})
        .toList();

    if (items.isEmpty) {
      _showMsg('Keranjang kosong', isError: true);
      return;
    }

    try {
      showDialog(
          context: ctx,
          barrierDismissible: false,
          builder: (_) => Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: const CircularProgressIndicator(
                      color: AppColors.vibrantOrange),
                ),
              ));

      final resp = await _api.post('/api/transaction', data: {'items': items});
      Navigator.of(ctx).pop();

      if ((resp.data != null && resp.data['success'] == true) ||
          resp.statusCode == 200) {
        cart.clearCart();
        _showMsg('Transaksi Berhasil!');
        await _fetchProducts();
        await _fetchDashboard();
      } else {
        _showMsg(resp.data['message'] ?? 'Transaksi gagal', isError: true);
      }
    } catch (err) {
      Navigator.of(ctx).pop();
      _showMsg('Terjadi kesalahan koneksi', isError: true);
    }
  }

  void _addToCartLogic(Map<String, dynamic> product) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final productId = product['id'].toString();
    final currentStock = product['stock'] ?? 0;

    int inCartQty = 0;
    if (cart.items.containsKey(productId)) {
      inCartQty = cart.items[productId]!['quantity'];
    }

    if (currentStock <= 0) {
      _showMsg('Stok habis!', isError: true);
      return;
    }

    if (inCartQty >= currentStock) {
      _showMsg('Stok tersisa hanya $currentStock', isError: true);
      return;
    }

    cart.addToCart(product);
    ScaffoldMessenger.of(context).clearSnackBars();
    _showMsg('${product['name']} ditambahkan ke keranjang');
  }

  // --- TAB 1: DASHBOARD ---
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      color: AppColors.vibrantOrange,
      onRefresh: _fetchDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // HEADER GRADASI ORANYE-COKELAT
            _buildWaveHeader(
              title: 'Halo, Kasir',
              subtitle: _username,
              height: 220,
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Peringatan Stok',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain)),
                  const SizedBox(height: 12),
                  _loadingDashboard
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.vibrantOrange))
                      : _lowStock.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.verified,
                              color: AppColors.success,
                              title: 'Stok Aman',
                              subtitle: 'Semua persediaan produk mencukupi.')
                          : Column(
                              children: _lowStock.asMap().entries.map((entry) {
                                return _buildAnimatedItem(
                                  index: entry.key,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.softYellow.withOpacity(
                                          0.4), // Kuning Pastel Transparan
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: AppColors.softYellow,
                                          width: 2),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_rounded,
                                            color: AppColors.darkBrown,
                                            size: 30),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  entry.value['product']
                                                          ['name'] ??
                                                      'Produk',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color:
                                                          AppColors.textMain)),
                                              Text(
                                                  'Sisa Stok: ${entry.value['quantity']}',
                                                  style: const TextStyle(
                                                      color: AppColors.danger,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: TRANSAKSI ---
  Widget _buildTransactionsTab() {
    final cart = Provider.of<CartProvider>(context);

    return Column(
      children: [
        // Header Mini
        Stack(
          children: [
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 110,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.vibrantOrange, AppColors.darkBrown]),
                ),
              ),
            ),
            const Positioned(
              top: 45,
              left: 20,
              child: Text('Menu Produk',
                  style: TextStyle(
                      color: AppColors.whiteCream,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            )
          ],
        ),

        Expanded(
          child: _loadingProducts
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.vibrantOrange))
              : RefreshIndicator(
                  color: AppColors.vibrantOrange,
                  onRefresh: _fetchProducts,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12),
                    itemCount: _products.length,
                    itemBuilder: (ctx, i) {
                      final p = _products[i];
                      final stock = p['stock'] ?? 0;
                      final isOutOfStock = stock <= 0;
                      final inCart = cart.items.containsKey(p['id'].toString())
                          ? cart.items[p['id'].toString()]!['quantity']
                          : 0;

                      return _buildAnimatedItem(
                        index: i,
                        child: GestureDetector(
                          onTap: () => _addToCartLogic(p),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          AppColors.darkBrown.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ]),
                            clipBehavior: Clip.hardEdge,
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon Placeholder Area
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        width: double.infinity,
                                        color: isOutOfStock
                                            ? Colors.grey[300]
                                            : AppColors.softYellow
                                                .withOpacity(0.3),
                                        child: Icon(
                                            Icons
                                                .coffee_rounded, // Ganti icon sesuai tema (kopi/makanan)
                                            size: 48,
                                            color: isOutOfStock
                                                ? Colors.grey
                                                : AppColors.vibrantOrange),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(p['name'] ?? '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: AppColors.textMain)),
                                            const SizedBox(height: 4),
                                            Text('Rp ${p['price']}',
                                                style: const TextStyle(
                                                    color:
                                                        AppColors.vibrantOrange,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13)),
                                            const Spacer(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  isOutOfStock
                                                      ? 'HABIS'
                                                      : 'Stok: $stock',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: isOutOfStock
                                                          ? AppColors.danger
                                                          : AppColors.textGrey,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                if (inCart > 0)
                                                  CircleAvatar(
                                                    radius: 12,
                                                    backgroundColor:
                                                        AppColors.darkBrown,
                                                    child: Text('$inCart',
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                Colors.white)),
                                                  )
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                // Overlay Habis
                                if (isOutOfStock)
                                  Container(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // --- TAB 3: KELOLA STOK ---
  Widget _buildStocksTab() {
    return Column(
      children: [
        _buildWaveHeader(
            title: 'Manajemen Stok',
            subtitle: 'Atur jumlah ketersediaan',
            height: 180),
        Expanded(
          child: _loadingStocks
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.vibrantOrange))
              : RefreshIndicator(
                  color: AppColors.vibrantOrange,
                  onRefresh: _fetchStocks,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _stocks.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final s = _stocks[i];
                      final p = s['product'] ?? {};
                      final qty = s['quantity'] ?? 0;
                      return _buildAnimatedItem(
                        index: i,
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        AppColors.darkBrown.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2))
                              ]),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: AppColors.softYellow.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.inventory,
                                  color: AppColors.darkBrown),
                            ),
                            title: Text(p['name'] ?? 'Produk',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain)),
                            subtitle: Text('$qty item',
                                style: TextStyle(
                                    color: qty <= 5
                                        ? AppColors.danger
                                        : AppColors.textGrey)),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_note_rounded,
                                  color: AppColors.vibrantOrange),
                              onPressed: () => _showUpdateStockDialog(s),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // --- WIDGET COMPONENTS ---

  // Wave Header dengan Gradient Warna Baru
  Widget _buildWaveHeader(
      {required String title, String? subtitle, required double height}) {
    return Stack(
      children: [
        ClipPath(
          clipper: WaveClipper(),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.vibrantOrange,
                  AppColors.darkBrown
                ], // Oranye ke Cokelat
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 55.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.whiteCream,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            color: AppColors.whiteCream.withOpacity(0.9),
                            fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
        // Ornamen Lingkaran Transparan (Pemanis)
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
          ),
        )
      ],
    );
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 50)),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(icon, size: 70, color: color.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdateStockDialog(Map<String, dynamic> stock) async {
    final currentQty = (stock['quantity'] ?? 0).toString();
    final controller = TextEditingController(text: currentQty);
    final product = stock['product'] ?? {};

    final res = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.whiteCream,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Update Stok',
                style: TextStyle(color: AppColors.textMain)),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              cursorColor: AppColors.vibrantOrange,
              decoration: InputDecoration(
                labelText: 'Jumlah Fisik',
                labelStyle: const TextStyle(color: AppColors.textGrey),
                focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: AppColors.vibrantOrange),
                    borderRadius: BorderRadius.circular(10)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal',
                      style: TextStyle(color: AppColors.textGrey))),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vibrantOrange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  onPressed: () async {
                    final newQty = int.tryParse(controller.text) ?? 0;
                    try {
                      await _kasir.updateStock(
                          product['id'] ?? stock['productId'], newQty);
                      if (!mounted) return;
                      Navigator.of(ctx).pop(true);
                    } catch (e) {
                      ScaffoldMessenger.of(ctx)
                          .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Simpan',
                      style: TextStyle(color: Colors.white)))
            ],
          );
        });

    if (res == true) {
      _showMsg('Stok diperbarui');
      await _fetchStocks();
      await _fetchDashboard();
    }
  }

  void _openCheckoutSheet() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final cart = Provider.of<CartProvider>(ctx);
          final items = cart.items.entries.toList();
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.65,
            decoration: const BoxDecoration(
              color: AppColors.whiteCream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20))),
                const SizedBox(height: 20),
                const Text('Keranjang Belanja',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain)),
                const SizedBox(height: 10),
                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.shopping_cart_outlined,
                          color: Colors.grey,
                          title: 'Keranjang Kosong',
                          subtitle: 'Yuk tambah produk dulu!')
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (c, i) {
                            final e = items[i];
                            final p = e.value['product'];
                            final qty = e.value['quantity'] as int;
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2))
                                  ]),
                              child: ListTile(
                                title: Text(p['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMain)),
                                subtitle: Text('${qty}x @ Rp ${p['price']}',
                                    style: const TextStyle(
                                        color: AppColors.textGrey)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: AppColors.textGrey),
                                      onPressed: () =>
                                          Provider.of<CartProvider>(ctx,
                                                  listen: false)
                                              .decreaseQty(e.key),
                                    ),
                                    Text('$qty',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.textMain)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle,
                                          color: AppColors.vibrantOrange),
                                      onPressed: () {
                                        if (qty >= p['stock']) return;
                                        Provider.of<CartProvider>(ctx,
                                                listen: false)
                                            .increaseQty(e.key);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [
                    BoxShadow(
                        color: AppColors.darkBrown.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5))
                  ]),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Tagihan',
                                style: TextStyle(color: AppColors.textGrey)),
                            Text('Rp ${cart.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkBrown)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.vibrantOrange,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 4),
                        onPressed: items.isEmpty ? null : () => _checkout(ctx),
                        child: const Text('BAYAR SEKARANG',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final totalItems = cart.items.length;

    return Scaffold(
      backgroundColor: AppColors.whiteCream, // Warna background lembut
      body: IndexedStack(index: _currentIndex, children: [
        _buildDashboardTab(),
        Stack(children: [
          _buildTransactionsTab(),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: totalItems > 0
                  ? GestureDetector(
                      onTap: _openCheckoutSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                            color:
                                AppColors.darkBrown, // Cokelat Gelap (Elegan)
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.darkBrown.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8))
                            ]),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle),
                              child: Text('$totalItems',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                                Text(
                                    'Rp ${cart.totalAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: AppColors.softYellow,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17)),
                              ],
                            ),
                            const Spacer(),
                            const Text('Keranjang',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const Icon(Icons.chevron_right, color: Colors.white)
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          )
        ]),
        _buildStocksTab(),
      ]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ]),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.vibrantOrange, // Icon Aktif Oranye
          unselectedItemColor: Colors.grey[400],
          elevation: 0,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_filled), label: 'Beranda'),
            BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded), label: 'Menu'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_rounded), label: 'Stok'),
          ],
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTER ---
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
        Offset(size.width - (size.width / 3.25), size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
