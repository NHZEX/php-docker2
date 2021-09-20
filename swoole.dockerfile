ARG SWOOLE_VERSION

FROM phpswoole/swoole:${SWOOLE_VERSION}

ARG PHP_JIT="0"
ARG MIRROR_CN="0"

RUN set -eux \
    && ([ "${MIRROR_CN}" = "0" ] || sed -i "s@http://deb.debian.org@http://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list) \
    && ([ "${MIRROR_CN}" = "0" ] || sed -i "s|security.debian.org/debian-security|mirrors.tuna.tsinghua.edu.cn/debian-security|g" /etc/apt/sources.list) \
    && apt-get update \
    && apt-get -y install procps libpq-dev unzip git libevent-dev libssl-dev \
    && docker-php-source extract \
    && docker-php-ext-install -j$(nproc) bcmath mysqli pdo_mysql pdo_pgsql pcntl sockets \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && pecl install inotify \
    && docker-php-ext-enable inotify \
    && pecl install event \
    && docker-php-ext-enable --ini-name z-event.ini event \
    && curl -L -o ext-postgresql.tar.gz https://github.com/swoole/ext-postgresql/archive/f5eda17f89d160d0a89ac7c5db4636bdaefd48e6.tar.gz && tar -xvf ext-postgresql.tar.gz && cd ext-postgresql-f5eda17f89d160d0a89ac7c5db4636bdaefd48e6 && phpize && ./configure && make -j && make install && docker-php-ext-enable swoole_postgresql && php --ri swoole_postgresql\
    && ( \
        [ $(php -r "echo PHP_VERSION_ID < 80000 ? 1 : 0;") = "0" ] \
        || (pecl install hprose && docker-php-ext-enable hprose) \
    ) \
    && echo "zend_extension=opcache.so" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && ( \
        [ "${PHP_JIT}" = "0" ] \
        || ( \
            echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
            && echo "opcache.jit_buffer_size=64M" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
            && echo ">> enable opcache" \
        ) \
    ) \
    && docker-php-source delete \
    && apt-get autoremove -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*
