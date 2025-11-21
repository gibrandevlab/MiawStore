import 'package:flutter/material.dart';
import '../services/admin_service.dart';

// --- PALET WARNA (Konsisten) ---
const Color kColorDarkBrown = Color(0xFF9D5C0D);
const Color kColorVibrantOrange = Color(0xFFE5890A);
const Color kColorSoftYellow = Color(0xFFF7D08A);
const Color kColorWhiteCream = Color(0xFFFAFAFA);
const Color kColorRedAlert = Color(0xFFD32F2F);
const Color kColorGreenSuccess = Color(0xFF388E3C);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AdminService _svc = AdminService();
  bool _loading = true;
  double revenueToday = 0.0;
  double revenueAllTime = 0.0;
  List<dynamic> lowStock = [];
  List<dynamic> topProducts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final map = await _svc.getDashboardSummary();

      if (!mounted) return;
      setState(() {
        final revenue = map['revenue'] ?? {};
        revenueAllTime = (revenue['allTime'] is num)
            ? (revenue['allTime'] as num).toDouble()
            : double.tryParse('${revenue['allTime']}') ?? 0.0;
        revenueToday = (revenue['today'] is num)
            ? (revenue['today'] as num).toDouble()
            : double.tryParse('${revenue['today']}') ?? 0.0;

        lowStock = (map['lowStock'] as List<dynamic>?) ?? [];
        topProducts = (map['topProducts'] as List<dynamic>?) ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading dashboard: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhiteCream,
      // Kita hilangkan AppBar bawaan di sini jika parent (AdminHome) sudah punya, 
      // atau kita biarkan kosong body-nya saja karena AdminHome biasanya handle AppBar.
      // Tapi jika ini halaman mandiri, berikut body-nya:
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kColorVibrantOrange))
          : RefreshIndicator(
              color: kColorVibrantOrange,
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Sapaan
                    const Text(
                      "Overview Toko",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kColorDarkBrown,
                      ),
                    ),
                    Text(
                      "Pantau performa bisnismu hari ini",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // 2. Kartu Omzet (Revenue)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Omzet Hari Ini',
                            amount: revenueToday,
                            icon: Icons.today_rounded,
                            color: kColorVibrantOrange,
                            isHighlight: true, // Lebih menonjol
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Omzet',
                            amount: revenueAllTime,
                            icon: Icons.account_balance_wallet_rounded,
                            color: Colors.blueAccent,
                            isHighlight: false,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 3. Section Low Stock
                    _buildSectionHeader("Stok Menipis", Icons.warning_amber_rounded, kColorRedAlert),
                    const SizedBox(height: 16),
                    _buildLowStockList(),

                    const SizedBox(height: 32),

                    // 4. Section Top Products
                    _buildSectionHeader("Produk Terlaris", Icons.emoji_events_rounded, kColorDarkBrown),
                    const SizedBox(height: 16),
                    _buildTopProductsList(),
                    
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGET BUILDERS (Agar kode rapi) ---

  // 1. Header Judul Per-Section
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kColorDarkBrown,
          ),
        ),
      ],
    );
  }

  // 2. Kartu Statistik (Omzet)
  Widget _buildStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isHighlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlight ? kColorVibrantOrange : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isHighlight 
              ? kColorVibrantOrange.withValues(alpha: 0.3) 
              : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHighlight ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isHighlight ? Colors.white : color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isHighlight ? Colors.white.withValues(alpha: 0.9) : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Rp ${_formatCurrency(amount)}",
            style: TextStyle(
              fontSize: 18, // Ukuran font dinamis bisa diatur
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.white : kColorDarkBrown,
            ),
          ),
        ],
      ),
    );
  }

  // 3. List Stok Menipis (Horizontal Scroll)
  Widget _buildLowStockList() {
    if (lowStock.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kColorGreenSuccess.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kColorGreenSuccess.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: kColorGreenSuccess),
            const SizedBox(width: 12),
            const Text("Aman! Semua stok mencukupi.", style: TextStyle(color: kColorGreenSuccess, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 110, // Tinggi area scroll
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: lowStock.length,
        itemBuilder: (ctx, i) {
          final item = lowStock[i];
          return Container(
            width: 240, // Lebar per kartu
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kColorRedAlert.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: kColorRedAlert.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kColorRedAlert.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.priority_high_rounded, color: kColorRedAlert),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['name'] ?? 'Produk',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Sisa: ${item['quantity']}",
                        style: const TextStyle(color: kColorRedAlert, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 4. List Top Products (Vertical List Style)
  Widget _buildTopProductsList() {
    if (topProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Belum ada data penjualan.", style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(
            color: kColorDarkBrown.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: topProducts.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final name = item['name'] ?? 'Produk';
          final sold = item['totalSold'] ?? item['total_sold'] ?? 0;
          
          // Warna medali untuk Top 3
          Color badgeColor;
          if (idx == 0) badgeColor = const Color(0xFFFFD700); // Gold
          else if (idx == 1) badgeColor = const Color(0xFFC0C0C0); // Silver
          else if (idx == 2) badgeColor = const Color(0xFFCD7F32); // Bronze
          else badgeColor = Colors.grey[300]!;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: idx < 3 ? kColorDarkBrown : Colors.grey[700],
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kColorSoftYellow.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$sold terjual',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kColorDarkBrown),
                  ),
                ),
              ),
              if (idx != topProducts.length - 1) 
                Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1), indent: 70),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Helper format angka sederhana (Contoh: 1500000 -> 1.5M atau sejenisnya, tapi di sini kita simple fixed)
  String _formatCurrency(double value) {
    // Jika mau format cantik (1.5jt, 200rb) bisa ditambah logic di sini
    // Untuk sekarang kita pakai pembulatan sederhana biar tidak kepanjangan
    if (value >= 1000000) {
      double val = value / 1000000;
      return "${val.toStringAsFixed(1)} Jt"; // Contoh: 1.5 Jt
    } else if (value >= 1000) {
       double val = value / 1000;
       return "${val.toStringAsFixed(0)} Rb"; // Contoh: 500 Rb
    }
    return value.toStringAsFixed(0);
  }
}