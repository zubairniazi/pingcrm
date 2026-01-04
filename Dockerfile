FROM unit:1.34.1-php8.3

# -----------------------
# System deps + Node for assets
# -----------------------
RUN apt update && apt install -y \
    curl unzip git nodejs npm \
    libicu-dev libzip-dev libpng-dev libjpeg-dev libfreetype6-dev libssl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) pcntl opcache pdo pdo_mysql intl zip gd exif ftp bcmath \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apt clean && rm -rf /var/lib/apt/lists/*

# -----------------------
# PHP settings
# -----------------------
RUN echo "opcache.enable=1" > /usr/local/etc/php/conf.d/custom.ini \
    && echo "opcache.jit=tracing" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "opcache.jit_buffer_size=256M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "memory_limit=512M" > /usr/local/etc/php/conf.d/custom.ini \
    && echo "upload_max_filesize=64M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "post_max_size=64M" >> /usr/local/etc/php/conf.d/custom.ini

# -----------------------
# Composer
# -----------------------
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# -----------------------
# App setup
# -----------------------
WORKDIR /var/www/html

# Create directories
RUN mkdir -p storage bootstrap/cache \
    && chown -R unit:unit storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Copy code
COPY . .

# Fix permissions for copied files
RUN chown -R unit:unit storage bootstrap/cache public \
    && chmod -R 775 storage bootstrap/cache public

# -----------------------
# Composer deps
# -----------------------
RUN composer install --prefer-dist --optimize-autoloader --no-interaction

# -----------------------
# Build Vite assets as unit
# -----------------------
RUN npm install && npm run build

COPY unit.json /docker-entrypoint.d/unit.json

# -----------------------
# Expose and run
# -----------------------
EXPOSE 8000
CMD ["unitd", "--no-daemon"]
