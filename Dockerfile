FROM php:7.0.24-apache
MAINTAINER skybosh <skybosh@daedalist.net>

RUN apt-get update && apt-get install -y \
        bzip2 \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libldap2-dev \
        libmcrypt-dev \
        libmemcached-dev \
        libpng12-dev \
        libpq-dev \
        libxml2-dev \
        && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
        && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
        && docker-php-ext-install exif gd intl ldap mbstring mcrypt mysqli opcache pdo_mysql pdo_pgsql pgsql zip ctype dom json xml posix simplexml xmlwriter curl fileinfo #bz2

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
                echo 'opcache.enable=1'; \
                echo 'opcache.enable_cli=1'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=10000'; \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.save_comments=1'; \
                echo 'opcache.revalidate_freq=1'; \
        } > /usr/local/etc/php/conf.d/opcache-recommended.ini
RUN a2enmod rewrite

# PECL extensions
RUN set -ex \
        && pecl install APCu \
        && pecl install redis \
        && docker-php-ext-enable apcu redis

ENV NEXTCLOUD_VERSION 12.0.3
VOLUME /var/www/html

RUN curl -fsSL -o nextcloud-${NEXTCLOUD_VERSION}.tar.bz2 \
                "https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" \
	&& curl -fsSL -o nextcloud-${NEXTCLOUD_VERSION}.tar.bz2.md5 \
                "https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2.md5" \
	&& md5sum -c nextcloud-${NEXTCLOUD_VERSION}.tar.bz2.md5 < nextcloud-${NEXTCLOUD_VERSION}.tar.bz2 \
        && tar -xjf nextcloud-${NEXTCLOUD_VERSION}.tar.bz2 -C /usr/src/ \
	&& rm -r nextcloud-${NEXTCLOUD_VERSION}.tar.bz2.md5 \
        && rm nextcloud-${NEXTCLOUD_VERSION}.tar.bz2

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
