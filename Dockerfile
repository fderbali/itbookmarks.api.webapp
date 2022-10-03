#######################################
# Base stage
#######################################
FROM php:8.1-fpm-alpine as base

# Opcache variables
# Disable file timestamps per default (faster file access)
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="10000" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="192" \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE="10"

# Install packages
RUN apk update && apk --no-cache add curl \
    # PHP libraries
    php8-bcmath php8-ctype php8-curl php8-dom php8-fileinfo php8-gd php8-iconv php8-json \
    php8-mbstring php8-openssl php8-pdo libpq-dev postgresql-client php8-phar php8-session php8-simplexml \
    php8-tokenizer php8-xml php8-xmlreader php8-xmlwriter php8-xsl php8-zip \
    # Required by the xsl extension
    libxslt-dev libgcrypt-dev \
    # Required by the zip extension
    libzip-dev \
    # Required by the gd extension
    freetype-dev libjpeg-turbo-dev libpng-dev

# Install extensions
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install bcmath opcache pdo pdo_pgsql pgsql xsl zip

# Configure and install the gd extension
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Configure PHP-FPM
COPY .docker/php/opcache.ini $PHP_INI_DIR/conf.d/opcache.ini
COPY .docker/php/php.ini $PHP_INI_DIR/conf.d/zzz_custom.ini
COPY .docker/php/php-fpm.conf $PHP_INI_DIR/php-fpm.d/zzz.conf

# Setup working directory
RUN rm -rf /var/www/*
WORKDIR /var/www


#######################################
# Composer stage
#######################################
FROM base as composer

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


#######################################
# Development stage
#######################################
FROM composer as development

# Enable opcache timestamps
# Allows to make changes in realtime (respect file timestamps)
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="1"
