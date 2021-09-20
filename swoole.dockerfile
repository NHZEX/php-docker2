ARG SWOOLE_VERSION

FROM phpswoole/swoole:${SWOOLE_VERSION}

ARG PHP_JIT="0"
ARG MIRROR_CN=""
ARG POSTGRESQL_VER=""

COPY script/ /tmp/script

RUN set -eux \
    && if [ -n "${MIRROR_CN}" ]; then \
      sed -i "s@//deb.debian.org@//mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list \
      && sed -i "s|security.debian.org/debian-security|mirrors.tuna.tsinghua.edu.cn/debian-security|g" /etc/apt/sources.list \
    ; fi \
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
    # install swoole postgresql \
    && /tmp/script/swoole_postgresql.sh ${POSTGRESQL_VER} \
    && /tmp/script/hprose.sh \
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
