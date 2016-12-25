FROM php:7.0.11-fpm
MAINTAINER Petter Kjelkenes <kjelkenes@gmail.com>

RUN apt-get update \
  && apt-get install -y \
    git \
    cron \
    pdftk \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libxslt1-dev \
    python-pip


RUN pip install awscli


RUN docker-php-ext-configure \
  gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

RUN docker-php-ext-install \
  gd \
  intl \
  mbstring \
  mcrypt \
  pdo_mysql \
  xsl \
  zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=1.2.0

ENV PHP_MEMORY_LIMIT 1G
ENV PHP_PORT 9000
ENV PHP_PM dynamic
ENV PHP_PM_MAX_CHILDREN 10
ENV PHP_PM_START_SERVERS 4
ENV PHP_PM_MIN_SPARE_SERVERS 2
ENV PHP_PM_MAX_SPARE_SERVERS 6


ENV COMPOSER_HOME /home/composer

ENV GITHUB_OAUTH_TOKEN ""

ENV AWS_ACCESS_KEY_ID ""
ENV AWS_SECRET_ACCESS_KEY ""
ENV AWS_DEFAULT_REGION "eu-west-1"


# S3 for storage
ENV MEDIA_S3_ACCESS_KEY ""
ENV MEDIA_S3_SECRET_KEY ""
ENV MEDIA_S3_BUCKET ""
ENV MEDIA_S3_REGION "eu-west-1"
ENV MEDIA_S3_SECURE_URL ""
ENV MEDIA_S3_WEBSITE_URL ""


# LARAVEL Specifics, rest of envs should be defined in beanstalk aws config panel.

ENV APP_KEY "base64:JIiitjB44NCn3ymIb0c+ogKLl4J4i7sLC81LfrogM7s"
ENV MEMCACHED_PERSISTENT_ID "app"
ENV DB_CONNECTION "mysql"



COPY resources/conf/php.ini /usr/local/etc/php/
COPY resources/conf/php-fpm.conf /usr/local/etc/
COPY resources/bin/* /usr/local/bin/

RUN mkdir -p /home/composer
COPY resources/conf/auth.json /home/composer/

# Create dir for www home user, to store .ssh keys.
RUN mkdir -p /var/www

WORKDIR /src

RUN apt-get update && apt-get install -y gcc g++ unzip jq
RUN curl -o clusterclient-aws-php7.zip https://s3.amazonaws.com/elasticache-downloads/ClusterClient/PHP-7.0/latest-64bit && \
     unzip clusterclient-aws-php7.zip && \
     cp artifact/amazon-elasticache-cluster-client.so "$(php -r 'echo ini_get("extension_dir");')" && \
     docker-php-ext-enable amazon-elasticache-cluster-client



CMD ["/usr/local/bin/start-laravel"]