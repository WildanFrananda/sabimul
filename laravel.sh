#!/bin/bash
# Script untuk menyiapkan Docker untuk project Laravel yang sudah ada

# Membuat struktur direktori
mkdir -p .docker/{php,node,mysql}

# Membuat file Dockerfile untuk PHP
cat > .docker/php/Dockerfile << 'EOF'
FROM php:8.4-cli

# Set working directory
WORKDIR /var/www/html

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl \
    libzip-dev \
    libonig-dev \
    libicu-dev

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl bcmath opcache intl
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Add composer global binaries to PATH
ENV PATH="${PATH}:/root/.composer/vendor/bin"

# Copy PHP configuration
COPY php.ini /usr/local/etc/php/conf.d/local.ini

# Expose port 8000 for Laravel
EXPOSE 8000

# Start command for Laravel development server
CMD php artisan serve --host=0.0.0.0 --port=8000
EOF

# Membuat file konfigurasi php.ini
cat > .docker/php/php.ini << 'EOF'
[PHP]
post_max_size = 100M
upload_max_filesize = 100M
variables_order = EGPCS
memory_limit = 512M
max_execution_time = 120

[opcache]
opcache.enable=1
opcache.revalidate_freq=0
opcache.validate_timestamps=1
opcache.max_accelerated_files=10000
opcache.memory_consumption=192
opcache.max_wasted_percentage=10
opcache.interned_strings_buffer=16
opcache.fast_shutdown=1
EOF

# Membuat file Dockerfile untuk Node
cat > .docker/node/Dockerfile << 'EOF'
FROM node:20-alpine

# Set working directory
WORKDIR /var/www/html

# Install dependencies
RUN apk add --no-cache bash

# Command to keep container running
CMD ["tail", "-f", "/dev/null"]
EOF

# Membuat file konfigurasi MySQL
cat > .docker/mysql/my.cnf << 'EOF'
[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-character-set-client-handshake = 1
default_authentication_plugin = mysql_native_password
EOF

# Membuat file docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # PHP Application Service
  app:
    build:
      context: ./.docker/php
      dockerfile: Dockerfile
    container_name: sabimul-app
    volumes:
      - ./:/var/www/html
      - ./.docker/php/php.ini:/usr/local/etc/php/conf.d/local.ini
    ports:
      - "8000:8000"
    depends_on:
      - db
    networks:
      - sabimul-network
    environment:
      - DB_HOST=db
      - DB_PORT=3306
      - DB_DATABASE=sabimul
      - DB_USERNAME=root
      - DB_PASSWORD=secret
    working_dir: /var/www/html

  # Node.js Service for Frontend Compilation
  node:
    build:
      context: ./.docker/node
      dockerfile: Dockerfile
    container_name: sabimul-node
    volumes:
      - ./:/var/www/html
    working_dir: /var/www/html
    networks:
      - sabimul-network
    tty: true

  # MySQL Service
  db:
    image: mysql:8.4
    container_name: sabimul-db
    restart: unless-stopped
    volumes:
      - sabimul-mysql-data:/var/lib/mysql
      - ./.docker/mysql/my.cnf:/etc/mysql/conf.d/my.cnf
    ports:
      - "3306:3306"
    environment:
      - MYSQL_DATABASE=sabimul
      - MYSQL_ROOT_PASSWORD=secret
      - MYSQL_CHARACTER_SET_SERVER=utf8mb4
      - MYSQL_COLLATION_SERVER=utf8mb4_unicode_ci
    networks:
      - sabimul-network

  # phpMyAdmin Service
  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: sabimul-phpmyadmin
    depends_on:
      - db
    ports:
      - "8080:80"
    environment:
      - PMA_HOST=db
      - PMA_PORT=3306
      - UPLOAD_LIMIT=100M
    networks:
      - sabimul-network

networks:
  sabimul-network:
    driver: bridge

volumes:
  sabimul-mysql-data:
EOF

# Membuat file Makefile
cat > Makefile << 'EOF'
# Makefile for Docker Laravel Project

.PHONY: help up down build dev watch test setup-existing

help: ## Show this help
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $1, $2}'

up: ## Start all containers
	docker-compose up -d

down: ## Stop all containers
	docker-compose down

build: ## Rebuild all containers
	docker-compose build --no-cache

setup-existing: ## Setup for existing Laravel installation with Livewire
	@echo "Setting up Docker for existing Laravel installation..."
	docker-compose exec node npm install
	docker-compose exec node npm install -D tailwindcss postcss autoprefixer
	docker-compose exec node npx tailwindcss init -p
	@echo "Configuring Tailwind CSS for Livewire..."
	docker-compose exec node sh -c "echo \"@tailwind base;\n@tailwind components;\n@tailwind utilities;\" > resources/css/app.css"
	docker-compose exec node sh -c "cat > tailwind.config.js << 'EOF'\nmodule.exports = {\n  content: [\n    './resources/**/*.blade.php',\n    './resources/**/*.js',\n    './resources/**/*.vue',\n  ],\n  theme: {\n    extend: {},\n  },\n  plugins: [],\n}\nEOF"
	docker-compose exec node sh -c "cat > vite.config.js << 'EOF'\nimport { defineConfig } from 'vite';\nimport laravel from 'laravel-vite-plugin';\n\nexport default defineConfig({\n    plugins: [\n        laravel({\n            input: ['resources/css/app.css', 'resources/js/app.js'],\n            refresh: true,\n        }),\n    ],\n});\nEOF"
	@echo "Setup completed successfully! Run 'make dev' to start Vite development server."

dev: ## Run npm dev
	docker-compose exec node npm run dev

watch: ## Run npm watch
	docker-compose exec node npm run watch

bash: ## Access app container shell
	docker-compose exec app bash

node-bash: ## Access node container shell
	docker-compose exec node bash

migrate: ## Run Laravel migrations
	docker-compose exec app php artisan migrate

seed: ## Run Laravel seeders
	docker-compose exec app php artisan db:seed

fresh: ## Refresh migrations and seed
	docker-compose exec app php artisan migrate:fresh --seed
EOF

echo "Setup selesai! File konfigurasi Docker untuk Laravel dengan Livewire dan Tailwind CSS telah dibuat."
echo "Langkah selanjutnya:"
echo "1. Jalankan 'docker-compose up -d' untuk memulai container"
echo "2. Jalankan 'make setup-existing' untuk konfigurasi Tailwind CSS"
echo "3. Jalankan 'make dev' untuk memulai Vite dalam mode development"
echo ""
echo "CATATAN: Script ini dibuat dengan asumsi bahwa Anda menjalankannya di direktori root project Laravel yang sudah ada."
