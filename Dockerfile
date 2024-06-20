FROM nginx:latest

RUN apt update -y
RUN apt install -y lsb-release apt-transport-https ca-certificates software-properties-common curl wget sudo supervisor cron

RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
RUN apt update -y

RUN apt install php8.2-common php8.2-fpm php8.2-mysql php8.2-ctype php8.2-curl php8.2-dom php8.2-gd php8.2-iconv php8.2-intl php8.2-mbstring php8.2-simplexml php8.2-xml php8.2-zip php8.2-soap php8.2-tokenizer php8.2-xmlrpc -y

COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

RUN curl -sL --retry 5 --retry-connrefused --retry-max-time 120 https://download.moodle.org/download.php/direct/stable404/moodle-latest-404.tgz | tar xz -C /usr/share/nginx/html

RUN sed -i "/^\/\/.*xsendfile = 'X-Accel-Redirect';/s/^\/\///" /usr/share/nginx/html/moodle/config-dist.php
RUN sed -i "/^\/\/.*xsendfilealiases = array(/s/^\/\///" /usr/share/nginx/html/moodle/config-dist.php
RUN sed -i "/xsendfilealiases = array($/s/xsendfilealiases = array(/xsendfilealiases = array('\\/dataroot\\/' => \\\$CFG->dataroot);/g" /usr/share/nginx/html/moodle/config-dist.php

RUN chown -R nginx:nginx /usr/share/nginx/html/moodle
RUN chmod -R 0755 /usr/share/nginx/html/moodle
RUN mkdir /usr/share/nginx/html/moodledata
RUN chown -R www-data:www-data /usr/share/nginx/html/moodledata
RUN chmod -R 0755 /usr/share/nginx/html/moodledata
RUN mkdir /usr/share/nginx/html/upload_tmp
RUN chown -R www-data:www-data /usr/share/nginx/html/upload_tmp
RUN chmod -R 0755 /usr/share/nginx/html/upload_tmp

RUN sed -i 's/^listen = .*/listen = 127.0.0.1:9000/' /etc/php/8.2/fpm/pool.d/www.conf
RUN sed -i 's/#gzip  on;/gzip on;/g' /etc/nginx/nginx.conf
RUN sed -i 's/#tcp_nopush     on;/tcp_nopush on;/g' /etc/nginx/nginx.conf

COPY ./php/moodle.ini /etc/php/8.2/fpm/conf.d/moodle.ini
COPY ./docker/supervisor/supervisord.conf /etc/supervisord.conf

COPY ./cron/crontab /etc/cron.d/moodle
RUN chmod 0644 /etc/cron.d/moodle
RUN crontab /etc/cron.d/moodle

COPY ./docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]