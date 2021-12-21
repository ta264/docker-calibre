FROM debian@sha256:63a5164407e011d602600524d814e449925c87409276ade77b1fdf48c744d1c4

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
RUN sed -i 's/main/main non-free/' /etc/apt/sources.list && \
    apt update && \
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
RUN file="/tmp/s6-overlay.tar.gz" && curl -fsSL -o "${file}" "https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-arm.tar.gz" && \
    tar xzf "${file}" -C / --exclude="./bin" && \
    tar xzf "${file}" -C /usr ./bin && \
        rm "${file}"

ENV CALIBRE_CONFIG_DIRECTORY=${CONFIG_DIR}
ENV BOOK_DIR="/books"

EXPOSE 8081

# install calibre
ARG ARM_FULL_VERSION
RUN apt update && \
    apt install -y --no-install-recommends --no-install-suggests calibre=${ARM_FULL_VERSION} && \
    mkdir "${APP_DIR}/bin" && \
    for file in /usr/bin/calibre*; do ln -s $file $(echo "${file}" | sed "s|/usr/bin|${APP_DIR}/bin|"); done && \
    for file in /usr/bin/ebook-*; do ln -s $file $(echo "${file}" | sed "s|/usr/bin|${APP_DIR}/bin|"); done && \
    apt clean && \
        rm -rf \
        /tmp/* \
        /var/tmp/*

COPY root/ /
