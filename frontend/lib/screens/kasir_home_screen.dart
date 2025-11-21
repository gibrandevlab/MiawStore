import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class KasirHomeScreen extends StatefulWidget {
  const KasirHomeScreen({super.key});

  @override
  State<KasirHomeScreen> createState() => _KasirHomeScreenState();
}

class _KasirHomeScreenState extends State<KasirHomeScreen> {
  final _api = ApiService().dio;
  final _storage = const FlutterSecureStorage();
  List<dynamic> _products = [];
  bool _loading = true;
  String _username = 'Kasir';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchProducts();
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

  Future<void> _fetchProducts() async {
    setState(() => _loading = true);
    try {
      final resp = await _api.get('/api/products');
      if (!mounted) return;
      setState(() {
        _products = resp.data as List<dynamic>;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memuat produk: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
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
      Navigator.of(ctx).pop(); // close progress

      if ((resp.data != null && resp.data['success'] == true) ||
          resp.statusCode == 200) {
        cart.clearCart();
        ScaffoldMessenger.of(ctx)
            .showSnackBar(const SnackBar(content: Text('Pembayaran sukses')));
        await _fetchProducts();
        Navigator.of(ctx).pop(); // close checkout modal
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
                                              cart.decreaseQty(pid)),
                                      IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () =>
                                              cart.increaseQty(pid)),
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
                          child: const Text('BAYAR'),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir — $_username'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (!mounted) return;
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                        Provider.of<CartProvider>(context, listen: false)
                            .addToCart(p);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${p['name']} ditambahkan')));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(
                                'Rp ${((p['price'] ?? 0) as num).toStringAsFixed(2)}'),
                            const Spacer(),
                            Text('Stok: ${p['stock'] ?? 0}'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
                child: Text(
                    'Total: Rp ${Provider.of<CartProvider>(context).totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold))),
            ElevatedButton(
                onPressed: _openCheckout, child: const Text('Checkout'))
          ],
        ),
      ),
    );
  }
}
