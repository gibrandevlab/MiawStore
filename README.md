# MiawStore

MiawStore is a demo Point-of-Sale (POS) app with backend (Node.js + Express + Sequelize + MySQL) and frontend (Flutter).

## Structure
- `backend/` - Node.js backend, Sequelize models, migrations, and seeders.
- `frontend/` - Flutter application.

## Quick start (development)
1. Backend

```powershell
Set-Location -Path 'C:\xampp\htdocs\miaw\backend'
# create database (adjust config/config.js if needed)
npx sequelize-cli db:create
# run migrations
npx sequelize-cli db:migrate
# seed demo data
npx sequelize-cli db:seed:all
# start server
npm run dev
```

2. Frontend

```powershell
Set-Location -Path 'C:\xampp\htdocs\miaw\frontend'
flutter pub get
flutter run -d <deviceId>
```

## Notes
- Seeders include demo Pet Shop data (products, stocks, sells). Ensure `users` seeder creates `admin@test.com` and `kasir@test.com` for sell records to link correctly.
- If you reinitialize git or push to a remote, be careful with existing remote repos to avoid overwriting.
