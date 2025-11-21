# Miaw Backend (foundation)

Ringkasan: fondasi backend menggunakan Node.js, Express, dan Sequelize (MySQL).

Langkah inisialisasi dan instalasi:

1. Inisialisasi npm:

```
npm init -y
```

2. Install dependensi:

```
npm install express sequelize mysql2
npm install --save-dev sequelize-cli nodemon
```

3. Jalankan migrasi (pastikan env vars `DB_USER`, `DB_PASS`, `DB_NAME`, `DB_HOST` sesuai):

```
npx sequelize-cli db:migrate --env development
```

File penting yang dibuat:
- `package.json` - skrip dan dependensi.
- `.sequelizerc` - konfigurasi path untuk `sequelize-cli`.
- `config/config.js` - konfigurasi koneksi DB (membaca env vars).
- `models/user.js` - model Sequelize `User`.
- `migrations/20251117-create-user.js` - migrasi pembuatan tabel `users`.
- `index.js` - server minimal yang memeriksa koneksi DB.

Contoh env (PowerShell):

```
$env:DB_USER = 'root'; $env:DB_PASS = ''; $env:DB_NAME='miaw_dev'; $env:DB_HOST='127.0.0.1'
node index.js
```

JWT / Auth notes:

- Set `JWT_SECRET` environment variable for signing tokens. Example (PowerShell):

```
$env:JWT_SECRET='a_very_secure_secret_here'
```

- Endpoints:
	- `POST /api/auth/register` -> body: `{ username, email, password }`
	- `POST /api/auth/login` -> body: `{ email, password }` -> returns `{ token }`

