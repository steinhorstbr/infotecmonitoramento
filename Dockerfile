FROM debian:buster-slim
LABEL maintainer="Rodrigo Steinhorst T <suporte@infoteccr.com.br>"

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="extra/Dockerfile" \
    org.label-schema.license="GPLv3" \
    org.label-schema.name="infotecmonitoramento" \
    org.label-schema.url="https://github.com/steinhorstbr/motioneye/wiki" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/steinhorstbr/infotecmonitoramento.git"

# By default, run as root.
ARG RUN_UID=0
ARG RUN_GID=0

COPY . /tmp/infotecmonitoramento

RUN echo "deb https://snapshot.debian.org/archive/debian/20200628T204444Z sid main contrib non-free" >>/etc/apt/sources.list && \
    apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -t stable --yes --option Dpkg::Options::="--force-confnew" --no-install-recommends install \
      curl \
      ffmpeg \
      libmicrohttpd12 \
      libpq5 \
      lsb-release \
      mosquitto-clients \
      python-jinja2 \
      python-pil \
      python-pip \
      python-pip-whl \
      python-pycurl \
      python-setuptools \
      python-tornado \
      python-tz \
      python-wheel \
      v4l-utils && \
    DEBIAN_FRONTEND="noninteractive" apt-get -t sid --yes --option Dpkg::Options::="--force-confnew" --no-install-recommends install \
      motion \
      libmysqlclient20 && \
    # Change uid/gid of user/group motion to match our desired IDs.  This will
    # make it easier to use execute motion as our desired user later.
    sed -i -e "s/^\(motion:[^:]*\):[0-9]*:[0-9]*:\(.*\)/\1:${RUN_UID}:${RUN_GID}:\2/" /etc/passwd && \
    sed -i -e "s/^\(motion:[^:]*\):[0-9]*:\(.*\)/\1:${RUN_GID}:\2/" /etc/group && \
    pip install /tmp/infotecmonitoramento && \
    # Cleanup
    rm -rf /tmp/infotecmonitoramento && \
    apt-get purge --yes python-setuptools python-wheel && \
    apt-get autoremove --yes && \
    apt-get --yes clean && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

ADD extra/motioneye.conf.sample /usr/share/infotecmonitoramento/extra/

# R/W needed for motioneye to update configurations
VOLUME /etc/infotecmonitoramento

# Video & images
VOLUME /var/lib/infotecmonitoramento

CMD test -e /etc/infotecmonitoramento/motioneye.conf || \
    cp /usr/share/infotecmonitoramento/extra/motioneye.conf.sample /etc/infotecmonitoramento/motioneye.conf ; \
    # We need to chown at startup time since volumes are mounted as root. This is fugly.
    chown motion:motion /var/run /var/log /etc/infotecmonitoramento /var/lib/infotecmonitoramento /usr/share/infotecmonitoramento/extra ; \
    su -g motion motion -s /bin/bash -c "/usr/local/bin/meyectl startserver -c /etc/infotecmonitoramento/motioneye.conf"

EXPOSE 8765
