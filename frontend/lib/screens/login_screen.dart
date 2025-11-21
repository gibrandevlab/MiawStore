import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/auth_service.dart';
import 'admin_home_screen.dart';
import 'kasir_home_screen.dart';

// --- DEFINISI WARNA DARI PALET ---
const Color kColorDarkBrown = Color(0xFF9D5C0D); // Teks Utama & Ikon
const Color kColorVibrantOrange = Color(0xFFE5890A); // Header & Tombol
const Color kColorSoftYellow = Color(0xFFF7D08A); // Aksen Background
const Color kColorWhiteCream = Color(0xFFFAFAFA); // Background Utama

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _isObscure = true; // State untuk menyembunyikan/menampilkan password

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final auth = AuthService();
      final token = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Decode JWT untuk mengetahui role dan username
      String role = 'kasir';
      String username = '';
      try {
        final Map<String, dynamic> payload = JwtDecoder.decode(token);
        if (payload['role'] != null) role = payload['role'];
        if (payload['username'] != null) username = payload['username'];
      } catch (_) {}

      // Simpan token
      const storage = FlutterSecureStorage();
      await storage.write(key: 'jwt', value: token);

      if (!mounted) return;
      setState(() => _loading = false);

      // Tampilkan pesan sukses
      if (username.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kColorDarkBrown,
            content: Text('Selamat Datang, $username!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Navigasi berdasarkan role
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const KasirHomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email diperlukan';
    final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!regex.hasMatch(v.trim())) return 'Masukkan email valid';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.trim().isEmpty) return 'Password diperlukan';
    if (v.length < 6) return 'Minimal 6 karakter';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhiteCream,
      body: Stack(
        children: [
          // 1. BACKGROUND WAVES (Header Bergelombang)
          // Wave Belakang (Kuning Soft)
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 280,
              color: kColorSoftYellow.withOpacity(0.6),
            ),
          ),
          // Wave Depan (Orange Utama)
          ClipPath(
            clipper: WaveClipperReverse(),
            child: Container(
              height: 260,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kColorVibrantOrange, Color(0xFFFFA559)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 2. CONTENT UTAMA
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Judul di atas Card
                    const Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // CARD LOGIN (Melayang)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: kColorDarkBrown.withOpacity(0.1),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ICON/GAMBAR
                          Container(
                            width: 90,
                            height: 90,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: kColorWhiteCream,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: kColorSoftYellow, width: 2),
                            ),
                            child: SvgPicture.asset(
                              'assets/images/cat.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Miaw Login",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kColorDarkBrown,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // FORM INPUT
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // --- EMAIL FIELD ---
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecoration(
                                      "Email", Icons.email_outlined),
                                  validator: _validateEmail,
                                ),

                                const SizedBox(height: 20),

                                // --- PASSWORD FIELD (Dengan Fitur Mata) ---
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _isObscure, // Logic hidden
                                  decoration: _inputDecoration(
                                          "Password", Icons.lock_outline)
                                      .copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _isObscure = !_isObscure;
                                        });
                                      },
                                      icon: Icon(
                                        _isObscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: kColorDarkBrown.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  validator: _validatePassword,
                                ),

                                const SizedBox(height: 30),

                                // --- TOMBOL LOGIN ---
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kColorVibrantOrange,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor:
                                          kColorVibrantOrange.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _loading ? null : _submit,
                                    child: _loading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            "LOGIN",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Footer Text
                    const SizedBox(height: 24),
                    Text(
                      "Lupa password? Hubungi Admin",
                      style: TextStyle(
                        color: kColorDarkBrown.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER: DEKORASI INPUT AGAR RAPI & KONSISTEN ---
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIcon: Icon(icon, color: kColorDarkBrown),
      filled: true,
      fillColor: kColorWhiteCream,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      // Border saat normal
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none, // Polos agar bersih
      ),
      // Border saat diklik (Focus)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kColorVibrantOrange, width: 1.5),
      ),
      // Border saat error
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}

// --- CUSTOM PAINTERS (UNTUK BENTUK GELOMBANG) ---

// Gelombang Belakang
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30.0);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
        Offset(size.width - (size.width / 3.25), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height - 40);
    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Gelombang Depan (Arah Berlawanan)
class WaveClipperReverse extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height - 80);
    var firstEndPoint = Offset(size.width / 2, size.height - 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 0.75, size.height);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
