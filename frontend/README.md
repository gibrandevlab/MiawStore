# Miaw Frontend (Flutter)

Ringkasan: fondasi untuk aplikasi Android dengan Flutter.

1) Perintah untuk membuat proyek Flutter baru

Jika Anda ingin membuat proyek baru dari awal, jalankan di PowerShell:

```powershell
# masuk ke folder parent, lalu buat project di folder 'frontend'
Set-Location c:\xampp\htdocs\miaw\frontend
# Jika folder masih kosong, jalankan:
flutter create .
# atau buat project bernama miaw_frontend (opsional):
flutter create --platforms=android -a kotlin -i swift miaw_frontend
```

Catatan: saya sudah menambahkan beberapa file dasar (`lib/main.dart`, `lib/screens/login_screen.dart`) dan `pubspec.yaml` dengan dependensi. Jika Anda menjalankan `flutter create .` setelah ini, Flutter akan menambahkan file/struktur proyek yang hilang.

2) Struktur folder yang disarankan

- `lib/`
  - `screens/`  (halaman UI seperti `login`, `home`, `profile`)
  - `models/`   (model data / DTO)
  - `services/` (API clients, auth service)
  - `widgets/`  (komponen UI yang dipakai ulang)
  - `providers/` (state management dengan Provider)

3) Dependensi yang ditambahkan ke `pubspec.yaml`

- `dio` - http client untuk panggilan API
- `provider` - state management sederhana
- `flutter_secure_storage` - menyimpan JWT dengan aman

4) File dasar yang dibuat

- `lib/main.dart` - entry point aplikasi
- `lib/screens/login_screen.dart` - halaman login sederhana (Scaffold)

5) Menjalankan aplikasi (contoh)

```powershell
# di dalam folder frontend
flutter pub get
flutter run -d emulator-5554
```

Jika Anda belum menginstal Flutter atau emulator, ikuti panduan resmi di https://flutter.dev/docs/get-started/install
