#Version 0.5
# Davical + postgres based on lighttpd and Alpine
#---------------------------------------------------------------------
#Default configuration: hostname: davical.example
#			default user: admin			
#			default pass: d4v1c4l
#TODO:
#->	Autentication for accounts postgres, davical_dba, davical_app
#
#->	Use locales (when alpine will use them)
#
#->	Remove 'sleep'when the following bug will be resolved
#	https://github.com/Supervisor/supervisor/issues/122
#
#-> Clean up and beautify ;-)
#---------------------------------------------------------------------

FROM 	akkarind/lighttpd:latest
LABEL maintainer="AkkarinD <carsten.vollmert (at) web.de>"

RUN	apk --update add \
	bash \
	less \
	nano \
	sed \
	rsyslog \
	supervisor \
	postgresql \
	php7 \
	php7-pgsql \
	php7-imap \
	php7-curl \
	php7-cgi \
	php7-xml \
	php7-gettext \ 
	php7-iconv \ 
	php7-ldap \
	php7-pdo \
	php7-pdo_pgsql \
	php7-calendar \
	perl \
	perl-yaml \
	perl-dbd-pg \
	perl-dbi \
	&& rm -rf /var/cache/apk/* \
	&& mkdir /var/run/sockets \
	&& chown lighttpd:lighttpd /var/run/sockets \
	&& mkdir /run/postgresql \
    && chown postgres:postgres /run/postgresql \
	&& rm -rf /etc/lighttpd 

# download davical and awl (a dependency of davical)
RUN cd /tmp \
    && mkdir -p /usr/share/awl \
    && mkdir -p /var/www/davical \
	&& wget "https://gitlab.com/davical-project/awl/repository/archive.tar.gz?ref=r0.60" -O awl.tar.gz \
    && wget "https://gitlab.com/davical-project/davical/repository/archive.tar.gz?ref=r1.1.8" -O davical.tar.gz \
    && tar -xf awl.tar.gz --strip 1 -C /usr/share/awl \
    && tar -xf davical.tar.gz --strip 1 -C /var/www/davical/ \
    && rm awl.tar.gz \
	&& rm davical.tar.gz \
	&& cd /var/www/davical/ \
	&& find ./ -type d -exec chmod u=rwx,g=rx,o=rx '{}' \; \
	&& find ./ -type f -exec chmod u=rw,g=r,o=r '{}' \; \
	&& find ./ -type f -name *.sh -exec chmod u=rwx,g=r,o=rx '{}' \; \
	&& find ./ -type f -name *.php -exec chmod u=rwx,g=rx,o=r '{}' \; \
	&& chmod o=rx /var/www/davical/dba/update-davical-database \
	&& chmod o=rx /var/www//davical \
	&& chown -R lighttpd:lighttpd /var/www/davical/htdocs \
	&& cd /usr/share/awl/ \
	&& find ./ -type d -exec chmod u=rwx,g=rx,o=rx '{}' \; \
	&& find ./ -type f -exec chmod u=rw,g=r,o=r '{}' \; \
	&& find ./ -type f -name *.sh -exec chmod u=rwx,g=rx,o=r '{}' \; \
	&& find ./ -type f -name *.sh -exec chmod u=rwx,g=r,o=rx '{}' \; \
	&& chmod o=rx /usr/share/awl

COPY	./config/lighttpd/ /config/lighttpd/	
COPY 	./scripts/* /sbin/
COPY	./docker-entrypoint.sh /sbin/docker-entrypoint.sh
COPY	./config/davical.php /config/davical.php
COPY	./config/supervisord.conf /config/supervisord.conf
COPY	./config/rsyslog.conf /config/rsyslog.conf
	
RUN    chmod 0755 /sbin/initialize_db.sh \
	&& chmod 0755 /sbin/backup_db.sh  \
	&& chmod 0755 /sbin/docker-entrypoint.sh \
	&& chmod 0755 /sbin/restore_db.sh \
	&& mkdir /etc/davical /etc/supervisor.d/ /etc/rsyslog.d \
	&& /bin/echo -e "\$IncludeConfig /etc/rsyslog.d/*.conf" > /etc/rsyslog.conf \
	&& chown -R root:lighttpd /etc/davical \
	&& chmod -R u=rwx,g=rx,o= /etc/davical \
	&& chown root:lighttpd /config/davical.php \
	&& chmod u+rwx,g+rx /config/davical.php \
	&& ln -s /config/lighttpd/ /etc/lighttpd \
	&& ln -s /config/davical.php /etc/davical/config.php \
	&& ln -s /sbin/backup_db.sh /etc/periodic/daily/backup \
	&& ln -s /config/supervisord.conf /etc/supervisor.d/supervisord.ini \
	&& ln -s /config/rsyslog.conf /etc/rsyslog.d/rsyslog-davical.conf	


EXPOSE 80
VOLUME 	["/var/lib/postgresql/data/"]
ENTRYPOINT ["/sbin/docker-entrypoint.sh"]
