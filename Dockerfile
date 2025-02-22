
# Based on Ubuntu 20.04 LTS
FROM ubuntu:20.04

# Build arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=0.0.12

# Labels
LABEL com.wiorca.build-date=$BUILD_DATE \
      com.wiorca.vcs-url="https://github.com/wiorca/docker-windscribe.git" \
      com.wiorca.vcs-ref=$VCS_REF \
      com.wiorca.schema-version=$VERSION

# The volume for the docker_user home directory, and where configuration files should be stored.
VOLUME [ "/config" ]

# Some environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Toronto \
    PUID=1000 \
    PGID=1000 \
    WINDSCRIBE_USERNAME=username \
    WINDSCRIBE_PASSWORD=password \
    WINDSCRIBE_PROTOCOL=stealth \
    WINDSCRIBE_PORT=80 \
    WINDSCRIBE_PORT_FORWARD=9999 \
    WINDSCRIBE_LOCATION=US \
    WINDSCRIBE_LANBYPASS=on \
    WINDSCRIBE_FIREWALL=on

# Update ubuntu container, and install the basics, Add windscribe ppa, Install windscribe, and some to be removed utilities
RUN apt -y update && apt -y dist-upgrade && apt install -y gnupg apt-utils ca-certificates expect iptables iputils-ping && \
     apt-key adv --keyserver keyserver.ubuntu.com --recv-key FDC247B7 && echo 'deb https://repo.windscribe.com/ubuntu bionic main' | tee /etc/apt/sources.list.d/windscribe-repo.list && \
     echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections && \
     apt -y update && apt -y dist-upgrade && apt install -y windscribe-cli && \
     apt install -y curl net-tools iputils-tracepath build-essential automake git && \
     apt -y autoremove && apt -y clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add in the docker user
RUN groupadd -r docker_group && useradd -r -d /config -g docker_group docker_user

# Install tinyproxy
RUN cd /opt && git clone https://github.com/tinyproxy/tinyproxy.git &&\
    cd tinyproxy && ./autogen.sh && ./configure && make && make install &&\
    mkdir -p /usr/local/var/log/tinyproxy &&\
    touch /usr/local/var/log/tinyproxy/tinyproxy.log &&\
    chown docker_user:docker_group /usr/local/var/log/tinyproxy/tinyproxy.log

# Add in scripts for health check and start-up
ADD scripts /opt/scripts/
COPY tinyproxy.conf.tmpl /opt/tinyproxy/

# Enable the health check for the VPN and app
HEALTHCHECK --interval=5m --timeout=60s \
  CMD /opt/scripts/health-check.sh || exit 1

# Run the container
CMD [ "/bin/bash", "/opt/scripts/vpn-startup.sh" ]
