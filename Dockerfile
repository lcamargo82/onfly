FROM php:8.4-apache

RUN apt-get update && apt-get install -y \
    gnupg2 \
    curl \
    unzip \
    git \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    pkg-config \
    unixodbc \
    apt-transport-https \
    libpq-dev \
    netcat-openbsd \
    openssl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd mysqli pdo pdo_mysql mbstring zip opcache intl xml pdo_pgsql

RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/debian/11/prod bullseye main" > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && apt-get install -y unixodbc-dev || true \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 || true \
    && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /etc/environment

RUN pecl install pdo_sqlsrv sqlsrv \
    && docker-php-ext-enable pdo_sqlsrv sqlsrv

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN a2enmod rewrite && service apache2 restart

WORKDIR /var/www/html

COPY ./api /var/www/html

RUN echo "User www-data" >> /etc/apache2/apache2.conf \
    && echo "Group www-data" >> /etc/apache2/apache2.conf

# RUN chown -R www-data:www-data /var/www/html \
#     && chmod -R 755 /var/www/html \
#     && chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/000-default.conf \
    && echo '    DocumentRoot /var/www/html/public' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    <Directory /var/www/html/public>' >> /etc/apache2/sites-available/000-default.conf \
    && echo '        AllowOverride All' >> /etc/apache2/sites-available/000-default.conf \
    && echo '        Require all granted' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    </Directory>' >> /etc/apache2/sites-available/000-default.conf \
    && echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

RUN a2ensite 000-default.conf

RUN composer install --no-interaction --no-dev --optimize-autoloader --working-dir=/var/www/html -vvv

EXPOSE 80

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
