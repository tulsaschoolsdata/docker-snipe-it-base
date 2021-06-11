ARG COMPOSER_VERSION='2.1.1'
ARG PHP_VERSION='7.4.20'

FROM composer:${COMPOSER_VERSION} AS composer
FROM php:${PHP_VERSION}-apache AS php-apache
FROM php-apache

ARG PECL_REDIS_VERSION='5.3.4'
ARG X_AWS_RDS_GLOBAL_BUNDLE_PEM='https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem'

COPY --from=composer /usr/bin/composer /usr/local/bin

# System Dependencies
RUN apt-get update && apt-get install -y \
        awscli \
        default-mysql-client \
        git \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libldap2-dev \
        libzip-dev \
        unzip \
# Configure and install PHP extensions required by Snipe-IT
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        gd \
        ldap \
        mysqli \
        pdo_mysql \
        zip \
# Install and enable the PHP Redis extension for TPS
    && pecl install \
        redis-${PECL_REDIS_VERSION} \
    && docker-php-ext-enable \
        redis \
# Install Heroku CLI
    && curl -sL https://cli-assets.heroku.com/install.sh | sh \
# AWS RDS Certificate Bundle
    && ( \
      mkdir -p /etc/ssl/aws/rds \
      && cd /etc/ssl/aws/rds \
      && curl -s -L -O ${X_AWS_RDS_GLOBAL_BUNDLE_PEM} \
    ) \
# Enable Apache Rewrite module
    && a2enmod rewrite \
# Clean up cache and temporary files
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
