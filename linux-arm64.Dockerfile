FROM ubuntu@sha256:0fb0d395bd896ff4670143d0515fb431c638cf9accc7f543114e33b392700eb2 AS builder

ARG DEBIAN_FRONTEND="noninteractive"

ENV APP_DIR="/app" CONFIG_DIR="/config" PUID="1000" PGID="1000" UMASK="002" TZ="Etc/UTC" ARGS=""
ENV XDG_CONFIG_HOME="${CONFIG_DIR}/.config" XDG_CACHE_HOME="${CONFIG_DIR}/.cache" XDG_DATA_HOME="${CONFIG_DIR}/.local/share" LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"

RUN mkdir "${APP_DIR}" && \
# create user
    useradd -u 1000 -U -d "${CONFIG_DIR}" -s /bin/false hotio && \
        usermod -G users hotio

# system depends
RUN apt update && apt install -y --no-install-recommends --no-install-suggests \
        xvfb libgl1-mesa-glx libfontconfig1 libhunspell-1.7-0 libhyphen0 libicu67 libpodofo0.9.7 libstdc++6 python3
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        fonts-liberation imagemagick libjpeg-turbo-progs libjxr-tools optipng poppler-utils 
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libxrandr2 libxcomposite1 libxcursor1 libxi6 libxtst6 libasound2
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libgdal28
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libqt5core5a
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libqt5network5
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libqt5webenginewidgets5

# python deps
RUN apt install -y --no-install-recommends --no-install-suggests \
        python3-openssl python3-pkg-resources python3-psutil python3-regex python3-apsw python3-bs4 \
        python3-chardet python3-chm python3-css-parser python3-cssselect python3-cssutils python3-dateutil python3-dbus python3-feedparser python3-html2text
RUN apt install -y --no-install-recommends --no-install-suggests \
        python3-html5-parser python3-html5lib python3-lxml python3-markdown python3-mechanize python3-msgpack python3-netifaces python3-pil python3-pygments
RUN apt install -y --no-install-recommends --no-install-suggests \
        python3-pyparsing python3-routes python3-zeroconf
RUN apt install -y --no-install-recommends --no-install-suggests \
        python3-pyqt5 python3-pyqt5.qtsvg python3-pyqt5.qtwebengine 

# dev depends
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        build-essential
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libboost-dev libchm-dev libegl1-mesa-dev
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libhunspell-dev libhyphen-dev libicu-dev libmagickwand-dev 
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        qtbase5-dev qtbase5-private-dev
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libqt5svg5-dev libsqlite3-dev libusb-1.0-0-dev
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libpodofo-dev libmtp-dev
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libgdal-dev
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        qt5-qmake pkg-config
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        python3-dev
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        pyqt5-dev python3-sipbuild python3-pyqtbuild python3-setuptools 

# to move up
RUN apt-get install -y --no-install-recommends --no-install-suggests \
    curl xz-utils ca-certificates

ARG VERSION
ARG PACKAGE_VERSION=${VERSION}

RUN mkdir -p "${APP_DIR}/bin" && \
        chown -R 1000:1000 "${APP_DIR}/bin"

USER 1000:1000
RUN curl -fsSL "https://download.calibre-ebook.com/${VERSION}/calibre-${VERSION}.tar.xz" | tar xJf - --strip-components 1 -C "${APP_DIR}/bin"

RUN  cd "${APP_DIR}/bin" && \
  LANG='en_US.UTF-8' python3 setup.py build && \
  LANG='en_US.UTF-8' python3 setup.py iso639 && \
  LANG='en_US.UTF-8' python3 setup.py iso3166 && \
  LANG='en_US.UTF-8' python3 setup.py translations && \
  LANG='en_US.UTF-8' python3 setup.py gui && \
  LANG='en_US.UTF-8' python3 setup.py resources --path-to-liberation_fonts /usr/share/fonts/truetype/liberation --system-liberation_fonts && \
  LANG='en_US.UTF-8' python3 setup.py install --staging-root="${APP_DIR}/bin/root"

FROM ubuntu@sha256:0fb0d395bd896ff4670143d0515fb431c638cf9accc7f543114e33b392700eb2

ARG DEBIAN_FRONTEND="noninteractive"

ENV APP_DIR="/app" CONFIG_DIR="/config" PUID="1000" PGID="1000" UMASK="002" TZ="Etc/UTC" ARGS=""
ENV XDG_CONFIG_HOME="${CONFIG_DIR}/.config" XDG_CACHE_HOME="${CONFIG_DIR}/.cache" XDG_DATA_HOME="${CONFIG_DIR}/.local/share" LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

VOLUME ["${CONFIG_DIR}"]
ENTRYPOINT ["/init"]

# make folders
RUN mkdir "${APP_DIR}" && \
# create user
    useradd -u 1000 -U -d "${CONFIG_DIR}" -s /bin/false hotio && \
        usermod -G users hotio

# install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        ca-certificates jq curl wget2 unzip p7zip-full unrar python3 \
        locales tzdata && \
# generate locale
    locale-gen en_US.UTF-8

# https://github.com/just-containers/s6-overlay/releases
ARG S6_VERSION=2.2.0.3

# install s6-overlay
RUN file="/tmp/s6-overlay.tar.gz" && curl -fsSL -o "${file}" "https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-amd64.tar.gz" && \
    tar xzf "${file}" -C / --exclude="./bin" && \
    tar xzf "${file}" -C /usr ./bin && \
    rm "${file}"

EXPOSE 8081

# system depends
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        xvfb libgl1-mesa-glx libfontconfig1 libhunspell-1.7-0 libhyphen0 libicu67 libpodofo0.9.7 libstdc++6 python3
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        fonts-liberation imagemagick libjpeg-turbo-progs libjxr-tools optipng poppler-utils 
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libxrandr2 libxcomposite1 libxcursor1 libxi6 libxtst6 libasound2
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libqt5core5a
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libqt5network5
RUN apt-get install -y --no-install-recommends --no-install-suggests \
        libqt5webenginewidgets5

# python deps
RUN apt install -y --no-install-recommends --no-install-suggests \
        python3-openssl python3-pkg-resources python3-psutil python3-regex python3-apsw python3-bs4 \
        python3-chardet python3-chm python3-css-parser python3-cssselect python3-cssutils python3-dateutil python3-dbus python3-feedparser python3-html2text
RUN apt install -y --no-install-recommends --no-install-suggests \
        python3-html5-parser python3-html5lib python3-lxml python3-markdown python3-mechanize python3-msgpack python3-netifaces python3-pil python3-pygments
RUN apt install -y --no-install-recommends --no-install-suggests \
        python3-pyparsing python3-routes python3-zeroconf
RUN apt install -y --no-install-recommends --no-install-suggests \
        python3-pyqt5 python3-pyqt5.qtsvg python3-pyqt5.qtwebengine 

COPY --from=builder "${APP_DIR}/bin/root" /usr

RUN apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/tmp/*

COPY root/ /
