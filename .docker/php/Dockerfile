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
