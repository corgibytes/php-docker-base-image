FROM php:7.4-apache

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y \
        apt-transport-https \
        apt-utils \
        curl \
        gnupg \
        libmcrypt-dev \
        libpng-dev \
        libzip-dev \
        locales \
        mariadb-client \
        postfix \
        unixodbc-dev \
        unzip \
        wget \
        zlib1g-dev

ADD https://curl.haxx.se/ca/cacert.pem /etc/ssl/certs/mozilla.pem

RUN cp /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled
RUN service postfix start
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update
ENV ACCEPT_EULA=Y
RUN apt-get install -y \
    msodbcsql17 \
    mssql-tools

RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
RUN . ~/.bashrc

RUN docker-php-ext-install \
    gd \
    mysqli \
    opcache \
    pdo \
    pdo_mysql \
    zip
RUN pear config-set php_ini `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"` system

RUN pecl install \
    pdo_sqlsrv-5.7.1preview \
    sqlsrv-5.7.1preview \
    xdebug

RUN echo "extension=$(find /usr/local/lib/php/extensions/ -name pdo_sqlsrv.so)" > /usr/local/etc/php/conf.d/pdo_sqlsrv.ini
RUN echo "extension=$(find /usr/local/lib/php/extensions/ -name sqlsrv.so)" > /usr/local/etc/php/conf.d/sqlsrv.ini

RUN echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini
RUN echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini
RUN echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini

RUN echo "short_open_tag=off" > /usr/local/etc/php/conf.d/php.ini
RUN echo "post_max_size=32M" >> /usr/local/etc/php/conf.d/php.ini
RUN echo "upload_max_filesize=32M" >> /usr/local/etc/php/conf.d/php.ini

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer