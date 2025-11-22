import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'manage_users_screen.dart';
import 'manage_products_screen.dart';
import 'manage_stock_screen.dart';
import 'manage_sells_screen.dart';

const Color kColorDarkBrown = Color(0xFF9D5C0D);
const Color kColorVibrantOrange = Color(0xFFE5890A);
const Color kColorSoftYellow = Color(0xFFF7D08A);
const Color kColorWhiteCream = Color(0xFFFAFAFA);

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selected = 0;
  String _username = '';
  String _email = '';
  String _role = '';

  final List<Widget> _pages = [
    const DashboardScreen(),
    const ManageUsersScreen(),
    const ManageProductsScreen(),
    const ManageStockScreen(),
    const ManageSellsScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Kelola Users',
    'Kelola Produk',
    'Kelola Stok',
    'Laporan Penjualan'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserFromToken();
  }

  Future<void> _loadUserFromToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt');
    if (token != null) {
      try {
        final Map<String, dynamic> payload = JwtDecoder.decode(token);
        if (!mounted) return;
        setState(() {
          _username = payload['username'] ?? 'Admin';
          _email = payload['email'] ?? '';
          _role = payload['role'] ?? '';
        });
      } catch (_) {}
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kColorWhiteCream,
        title: const Text("Logout", style: TextStyle(color: kColorDarkBrown)),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhiteCream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kColorVibrantOrange,
        centerTitle: true,
        title: Text(
          _titles[_selected],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // Membuat AppBar melengkung di bawah agar tidak kaku
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildCustomDrawer(),
      body: Container(
        color: kColorWhiteCream,
        child: _pages[_selected],
      ),
    );
  }

  Widget _buildCustomDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: Stack(
              children: [
                ClipPath(
                  clipper: DrawerHeaderClipper(),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kColorVibrantOrange, Color(0xFFFFA559)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        child: const CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person,
                              size: 40, color: kColorDarkBrown),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _email.isNotEmpty ? _email : _role,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              children: [
                _buildMenuItem(0, "Dashboard", Icons.dashboard_rounded),
                _buildMenuItem(1, "Kelola Users", Icons.people_alt_rounded),
                _buildMenuItem(2, "Kelola Produk", Icons.shopping_bag_rounded),
                _buildMenuItem(3, "Kelola Stok", Icons.inventory_2_rounded),
                _buildMenuItem(4, "Laporan Jual", Icons.insert_chart_rounded),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.red),
                  ),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Tutup drawer dulu
                    _logout();
                  },
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Ver 1.0.0",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    final bool isSelected = _selected == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? kColorSoftYellow.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          setState(() => _selected = index);
          Navigator.pop(context);
        },
        leading: Icon(
          icon,
          color: isSelected ? kColorDarkBrown : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? kColorDarkBrown : Colors.grey[800],
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: kColorDarkBrown)
            : null,
      ),
    );
  }
}

class DrawerHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);

    path.quadraticBezierTo(size.width / 2, size.height, size.width,
        size.height - 40 // Titik akhir (kanan bawah naik dikit)
        );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
