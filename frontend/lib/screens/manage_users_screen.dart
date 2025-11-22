import 'package:flutter/material.dart';
import '../services/admin_service.dart';

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
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddForm() async {
    final formKey = GlobalKey<FormState>();
    final tUser = TextEditingController();
    final tEmail = TextEditingController();
    final tPass = TextEditingController();
    String role = 'kasir';

    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tambah User Baru',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9D5C0D))),
                        IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(ctx))
                      ]),
                  const SizedBox(height: 20),
                  Form(
                      key: formKey,
                      child: Column(children: [
                        TextFormField(
                            controller: tUser,
                            decoration: _inputDecoration(
                                'Username', Icons.person_outline),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Username diperlukan'
                                : null),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: tEmail,
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                _inputDecoration('Email', Icons.email_outlined),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Email diperlukan'
                                : null),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: tPass,
                            obscureText: true,
                            decoration: _inputDecoration(
                                'Password', Icons.lock_outline),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Password diperlukan'
                                : null),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                            initialValue: role,
                            decoration: _inputDecoration(
                                'Role', Icons.admin_panel_settings_outlined),
                            items: const [
                              DropdownMenuItem(
                                  value: 'admin', child: Text('Admin')),
                              DropdownMenuItem(
                                  value: 'kasir', child: Text('Kasir'))
                            ],
                            onChanged: (v) {
                              if (v != null) role = v;
                            }),
                        const SizedBox(height: 16),
                        SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE5890A)),
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    final payload = {
                                      'username': tUser.text.trim(),
                                      'email': tEmail.text.trim(),
                                      'password': tPass.text,
                                      'role': role
                                    };
                                    Navigator.pop(ctx);
                                    await _svc.createUser(payload);
                                    await _fetch();
                                  }
                                },
                                child: const Text('SIMPAN USER')))
                      ]))
                ]),
          );
        });
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Hapus User'),
                content: const Text('Yakin ingin menghapus user ini?'),
                actions: [
                  TextButton(
                      child: const Text('Batal'),
                      onPressed: () => Navigator.pop(ctx, false)),
                  TextButton(
                      child: const Text('Hapus',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () => Navigator.pop(ctx, true))
                ]));
    if (confirm == true) {
      try {
        await _svc.deleteUser(id);
        await _fetch();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFE5890A),
          onPressed: _showAddForm,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label:
              const Text('Tambah User', style: TextStyle(color: Colors.white))),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5890A)))
          : _users.isEmpty
              ? Center(
                  child: Text('Belum ada user',
                      style: TextStyle(color: Colors.grey[600])))
              : RefreshIndicator(
                  color: const Color(0xFFE5890A),
                  onRefresh: _fetch,
                  child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _users.length,
                      itemBuilder: (ctx, i) {
                        final u = _users[i];
                        return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12.withAlpha(8),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4))
                                ]),
                            child: Row(children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(u['username'] ?? 'No Name',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(u['email'] ?? '-',
                                        style:
                                            TextStyle(color: Colors.grey[600]))
                                  ])),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.grey),
                                  onPressed: () => _delete(u['id'].toString()))
                            ]));
                      })),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF9D5C0D)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFE5890A), width: 1.5)));
  }
}
