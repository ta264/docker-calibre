FROM ubuntu@sha256:2581c675b3727523ea723a0d9a99361a547d03743bd2820cbe58eb48355eac2c

ARG DEBIAN_FRONTEND="noninteractive"

ENV APP_DIR="/app" CONFIG_DIR="/config" PUID="1000" PGID="1000" UMASK="002" TZ="Etc/UTC" ARGS=""
ENV XDG_CONFIG_HOME="${CONFIG_DIR}/.config" XDG_CACHE_HOME="${CONFIG_DIR}/.cache" XDG_DATA_HOME="${CONFIG_DIR}/.local/share" LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"

VOLUME ["${CONFIG_DIR}"]
ENTRYPOINT ["/init"]

RUN mkdir "${APP_DIR}" && \
# create user
    useradd -u 1000 -U -d "${CONFIG_DIR}" -s /bin/false hotio && \
        usermod -G users hotio

# install packages
RUN apt update && \
    apt install -y --no-install-recommends --no-install-suggests \
        ca-certificates jq curl wget2 unzip p7zip-full unrar python3 \
        locales tzdata && \
# generate locale
    locale-gen en_US.UTF-8 && \
# clean up
    apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# https://github.com/just-containers/s6-overlay/releases
ARG S6_VERSION=2.2.0.3

# install s6-overlay
RUN file="/tmp/s6-overlay.tar.gz" && curl -fsSL -o "${file}" "https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-amd64.tar.gz" && \
    tar xzf "${file}" -C / --exclude="./bin" && \
    tar xzf "${file}" -C /usr ./bin && \
        rm "${file}"

ENV CALIBRE_CONFIG_DIRECTORY=${CONFIG_DIR}
ENV BOOK_DIR="/books"

EXPOSE 8081

# install calibre
RUN apt update && \
    apt install -y --no-install-recommends --no-install-suggests calibre && \
    echo "deb http://deb.debian.org/debian buster main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian experimental main" >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC && \
    apt update && \
    apt install -y --no-install-recommends --no-install-suggests -t experimental calibre && \
    mkdir "${APP_DIR}/bin" && \
    ln -s /usr/bin/calibredb "${APP_DIR}/bin/calibredb" && \
    ln -s /usr/bin/calibre-server "${APP_DIR}/bin/calibre-server" && \
    apt clean && \
        rm -rf \
        /tmp/* \
        /var/tmp/*

COPY root/ /
