import 'package:flutter/material.dart';
import '../services/admin_service.dart';

// --- PALET WARNA ---
const Color kColorDarkBrown = Color(0xFF9D5C0D);
const Color kColorVibrantOrange = Color(0xFFE5890A);
const Color kColorSoftYellow = Color(0xFFF7D08A);
const Color kColorWhiteCream = Color(0xFFFAFAFA);

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final AdminService _svc = AdminService();
  List<dynamic> _users = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    try {
      final list = await _svc.getUsers();
      if (!mounted) return;
      setState(() => _users = list);
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

  // Menggunakan Modal Bottom Sheet (Lebih modern daripada Dialog)
  Future<void> _showAddForm() async {
    final formKey = GlobalKey<FormState>();
    final tUser = TextEditingController();
    final tEmail = TextEditingController();
    final tPass = TextEditingController();
    String role = 'kasir';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar keyboard tidak menutupi
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
              // Header Modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tambah User Baru',
                    style: TextStyle(
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
                    _buildTextField(tUser, 'Username', Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField(tEmail, 'Email', Icons.email_outlined,
                        inputType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildTextField(tPass, 'Password', Icons.lock_outline,
                        isPassword: true),
                    const SizedBox(height: 16),
                    
                    // Dropdown Role
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: _inputDecoration('Role', Icons.admin_panel_settings_outlined),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'kasir', child: Text('Kasir'))
                      ],
                      onChanged: (v) {
                        if (v != null) role = v;
                      },
                    ),
                    const SizedBox(height: 24),

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
                          if (formKey.currentState!.validate()) {
                            final payload = {
                              'username': tUser.text.trim(),
                              'email': tEmail.text.trim(),
                              'password': tPass.text,
                              'role': role
                            };
                            Navigator.pop(ctx); // Tutup modal
                            _submitData(payload);
                          }
                        },
                        child: const Text(
                          'SIMPAN USER',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
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

  Future<void> _submitData(Map<String, dynamic> payload) async {
    if (mounted) setState(() => _loading = true);
    try {
      await _svc.createUser(payload);
      await _fetch(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User berhasil ditambahkan!'),
            backgroundColor: kColorDarkBrown,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus User"),
        content: const Text("Yakin ingin menghapus user ini? Akses mereka akan hilang."),
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
        await _svc.deleteUser(id);
        await _fetch();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        onPressed: _showAddForm,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("Tambah User",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // 1. Blob Decoration (Pojok kanan atas)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: kColorSoftYellow.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Content
          _loading
              ? const Center(child: CircularProgressIndicator(color: kColorVibrantOrange))
              : _users.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: kColorVibrantOrange,
                      onRefresh: _fetch,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _users.length,
                        itemBuilder: (ctx, i) {
                          final u = _users[i];
                          return _buildUserCard(u);
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  // --- WIDGET ITEM USER ---
  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? 'kasir';
    final isAdmin = role == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kColorDarkBrown.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isAdmin 
                  ? Colors.purple.withValues(alpha: 0.1) 
                  : Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: isAdmin ? Colors.purple : Colors.green,
            ),
          ),
          const SizedBox(width: 16),

          // Info User
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user['username'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kColorDarkBrown,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAdmin 
                            ? Colors.purple.withValues(alpha: 0.1) 
                            : kColorVibrantOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isAdmin 
                              ? Colors.purple.withValues(alpha: 0.3) 
                              : kColorVibrantOrange.withValues(alpha: 0.3),
                          width: 0.5
                        ),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAdmin ? Colors.purple : kColorDarkBrown,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? '-',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),

          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _delete(user['id'].toString()),
          ),
        ],
      ),
    );
  }

  // --- HELPER INPUT FIELDS ---
  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isPassword = false, TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      decoration: _inputDecoration(label, icon),
      validator: (v) => v == null || v.isEmpty ? '$label diperlukan' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Belum ada user",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}