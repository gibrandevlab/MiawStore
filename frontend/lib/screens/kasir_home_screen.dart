import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/kasir_service.dart';
import 'login_screen.dart';

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

  // data for tabs
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

  Future<void> _loadUser() async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token != null && token.isNotEmpty) {
        final payload = JwtDecoder.decode(token);
        setState(() {
          _username = payload['username'] ?? payload['email'] ?? 'Kasir';
        });
      }
    } catch (_) {}
  }

  // Tab 1: dashboard (low stock alerts)
  Future<void> _fetchDashboard() async {
    if (mounted) setState(() => _loadingDashboard = true);
    try {
      final list = await _kasir.getDashboard();
      if (!mounted) return;
      setState(() => _lowStock = list);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading dashboard: $e')));
    } finally {
      if (mounted) setState(() => _loadingDashboard = false);
    }
  }

  // Tab 2: products (POS)
  Future<void> _fetchProducts() async {
    if (mounted) setState(() => _loadingProducts = true);
    try {
      final resp = await _api.get('/api/products');
      if (!mounted) return;
      setState(() => _products = resp.data as List<dynamic>);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memuat produk: $e')));
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _checkout(BuildContext ctx) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final items = cart.items.entries
        .map((e) =>
            {'productId': int.parse(e.key), 'quantity': e.value['quantity']})
        .toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(const SnackBar(content: Text('Keranjang kosong')));
      return;
    }

    try {
      showDialog(
          context: ctx,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()));
      final resp = await _api.post('/api/transaction', data: {'items': items});
      Navigator.of(ctx).pop();

      if ((resp.data != null && resp.data['success'] == true) ||
          resp.statusCode == 200) {
        cart.clearCart();
        ScaffoldMessenger.of(ctx)
            .showSnackBar(const SnackBar(content: Text('Pembayaran sukses')));
        await _fetchProducts();
      } else {
        final msg = resp.data != null && resp.data['message'] != null
            ? resp.data['message']
            : 'Transaksi gagal';
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (err) {
      Navigator.of(ctx).pop();
      final msg = (err is Exception) ? err.toString() : 'Terjadi kesalahan';
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _openCheckout() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          final cart = Provider.of<CartProvider>(ctx);
          final items = cart.items.entries.toList();
          return Padding(
            padding: MediaQuery.of(ctx).viewInsets,
            child: SizedBox(
              height: 420,
              child: Column(
                children: [
                  AppBar(
                    title: const Text('Checkout'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop())
                    ],
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(child: Text('Keranjang kosong'))
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (c, i) {
                              final e = items[i];
                              final pid = e.key;
                              final p =
                                  e.value['product'] as Map<String, dynamic>;
                              final qty = e.value['quantity'] as int;
                              return ListTile(
                                title: Text(p['name'] ?? ''),
                                subtitle: Text(
                                    'Qty: $qty • Rp ${((p['price'] ?? 0) * qty).toStringAsFixed(2)}'),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () =>
                                              Provider.of<CartProvider>(ctx,
                                                      listen: false)
                                                  .decreaseQty(pid)),
                                      IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () =>
                                              Provider.of<CartProvider>(ctx,
                                                      listen: false)
                                                  .increaseQty(pid)),
                                    ]),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(
                                'Total: Rp ${Provider.of<CartProvider>(ctx).totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold))),
                        ElevatedButton(
                            onPressed: () => _checkout(ctx),
                            child: const Text('BAYAR'))
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  // Tab 3: stocks
  Future<void> _fetchStocks() async {
    if (mounted) setState(() => _loadingStocks = true);
    try {
      final list = await _kasir.getStocks();
      if (!mounted) return;
      setState(() => _stocks = list);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading stocks: $e')));
    } finally {
      if (mounted) setState(() => _loadingStocks = false);
    }
  }

  Future<void> _showUpdateStockDialog(Map<String, dynamic> stock) async {
    final currentQty = (stock['quantity'] ?? 0).toString();
    final controller = TextEditingController(text: currentQty);
    final product = stock['product'] ?? {};

    final res = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Update Stok Fisik'),
            content: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Jumlah stok ( angka )'),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal')),
              ElevatedButton(
                  onPressed: () async {
                    final newQty = int.tryParse(controller.text) ?? 0;
                    try {
                      await _kasir.updateStock(
                          product['id'] ??
                              stock['productId'] ??
                              stock['productId'],
                          newQty);
                      Navigator.of(ctx).pop(true);
                    } catch (e) {
                      ScaffoldMessenger.of(ctx)
                          .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Simpan'))
            ],
          );
        });

    if (res == true) await _fetchStocks();
  }

  Widget _buildDashboardTab() {
    if (_loadingDashboard)
      return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Halo, $_username',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Peringatan Stok Menipis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _lowStock.isEmpty
              ? Center(
                  child: Column(children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 8),
                  Text('Stok Aman')
                ]))
              : Column(
                  children: _lowStock.map((s) {
                  final p = s['product'] ?? {};
                  return Card(
                    color: Colors.pink[50],
                    child: ListTile(
                      title: Text(p['name'] ?? 'Produk'),
                      subtitle: Text('Sisa: ${s['quantity'] ?? 0}'),
                    ),
                  );
                }).toList())
        ]),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_loadingProducts)
      return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8),
        itemCount: _products.length,
        itemBuilder: (ctx, i) {
          final p = _products[i] as Map<String, dynamic>;
          return Card(
            child: InkWell(
              onTap: () {
                Provider.of<CartProvider>(context, listen: false).addToCart(p);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${p['name']} ditambahkan')));
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                          'Rp ${((p['price'] ?? 0) as num).toStringAsFixed(2)}'),
                      const Spacer(),
                      Text('Stok: ${p['stock'] ?? 0}'),
                    ]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStocksTab() {
    if (_loadingStocks) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _fetchStocks,
      child: ListView.builder(
        itemCount: _stocks.length,
        itemBuilder: (ctx, i) {
          final s = _stocks[i] as Map<String, dynamic>;
          final p = s['product'] ?? {};
          final qty = s['quantity'] ?? 0;
          return ListTile(
            leading: const Icon(Icons.inventory_2),
            title: Text(p['name'] ?? 'Produk'),
            trailing: Text('$qty',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: qty <= 5 ? Colors.red : Colors.black)),
            onTap: () => _showUpdateStockDialog(s),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await AuthService().logout();
                if (!mounted) return;
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              })
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: [
        _buildDashboardTab(),
        Stack(children: [
          _buildTransactionsTab(),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    Expanded(
                        child: Text(
                            'Total: Rp ${cart.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold))),
                    ElevatedButton(
                        onPressed: _openCheckout, child: const Text('Checkout'))
                  ])))
        ]),
        _buildStocksTab(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale), label: 'Transaksi'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: 'Kelola Stok'),
        ],
      ),
    );
  }
}
