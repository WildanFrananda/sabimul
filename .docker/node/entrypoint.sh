#!/bin/bash

# Masuk ke direktori aplikasi
cd /var/www/html

# Install npm dependencies jika belum ada node_modules
if [ ! -d "node_modules" ]; then
  npm install
fi

# Jalankan Vite secara eksplisit dengan host dan port yang benar
exec npm run dev