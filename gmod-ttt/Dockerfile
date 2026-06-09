FROM debian:bookworm-slim

ARG BUILD_ENV=local
ENV DEBIAN_FRONTEND=noninteractive

# SRCDS and GMod requirements
RUN dpkg --add-architecture i386 \
	&& apt update \
	&& apt upgrade -y \
	&& apt install -y \
	tar \
	wget \
	curl \
	gcc \
	g++ \
	lib32gcc-s1 \
	libgcc1 \
	libcurl4-gnutls-dev:i386 \
	libssl3:i386 \
	libcurl4:i386 \
	lib32tinfo6 \
	libtinfo6:i386 \
	lib32z1 \
	lib32stdc++6 \
	libncurses5:i386 \
	libcurl3-gnutls:i386 \
	libsdl2-2.0-0:i386 \
	libtcmalloc-minimal4:i386 \
	libgoogle-perftools4 \
	iproute2 \
	gdb \
	libsdl1.2debian \
	libfontconfig1 \
	telnet \
	net-tools \
	netcat-traditional \
	tzdata \
	jq \
	p7zip-full \
	procps \
	bc \
	rsync \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Create user since srcds can't run as root
RUN useradd -d /home/container -m container
ENV USER=container HOME=/home/container

# Install SteamCMD to /opt and bake game files into /opt/gmod-server
USER root
RUN mkdir -p /opt/steamcmd /opt/gmod-server
RUN wget -q -O /tmp/steamcmd_linux.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
	&& tar -xzf /tmp/steamcmd_linux.tar.gz -C /opt/steamcmd \
	&& rm -f /tmp/steamcmd_linux.tar.gz \
	&& chown -R container:container /opt/steamcmd /opt/gmod-server

COPY --chown=container:container update.txt /opt/gmod-update.txt
USER container
RUN /opt/steamcmd/steamcmd.sh +runscript /opt/gmod-update.txt +quit || true
RUN /opt/steamcmd/steamcmd.sh +runscript /opt/gmod-update.txt +quit || true

# Copy addons and content into baked server directory
USER root
COPY --chown=container:container addons /opt/gmod-server/garrysmod/addons
COPY --chown=container:container lua/bin /opt/gmod-server/garrysmod/lua/bin

# gmsv_rdb_linux should only be in local dev
RUN if [ "$BUILD_ENV" != "local" ]; then rm -f /opt/gmod-server/garrysmod/lua/bin/gmsv_rdb_linux.dll; fi
COPY --chown=container:container models /opt/gmod-server/garrysmod/models
COPY --chown=container:container data/gmcore /opt/gmod-server/garrysmod/data/gmcore
COPY --chown=container:container data/ulib /opt/gmod-server/garrysmod/data/ulib
COPY --chown=container:container data/ulx /opt/gmod-server/garrysmod/data/ulx
COPY --chown=container:container cfg/server.cfg.template /opt/gmod-server/garrysmod/cfg/server.cfg.template


# Entrypoint and helper scripts
COPY --chown=container:container entrypoint.sh start.sh check-maps.sh generate-server-cfg.sh healthcheck.sh start-with-healthcheck.sh /
RUN sed -i 's/\r$//' /entrypoint.sh /start.sh /check-maps.sh /generate-server-cfg.sh /healthcheck.sh /start-with-healthcheck.sh || true \
	&& chmod +x /entrypoint.sh /start.sh /check-maps.sh /generate-server-cfg.sh /healthcheck.sh /start-with-healthcheck.sh

USER container
WORKDIR /home/container

CMD ["/bin/bash", "/entrypoint.sh"]
