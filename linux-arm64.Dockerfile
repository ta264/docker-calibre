FROM hotio/base@sha256:0cf39af5d888b36b0cb1d6513279680e652a8a0671795d61fcfbb14a6adba39c

ARG DEBIAN_FRONTEND="noninteractive"

ENV CALIBRE_CONFIG_DIRECTORY=${CONFIG_DIR}
ENV BOOK_DIR="/books"

EXPOSE 8081

# install packages
RUN apt update && \
    apt install -y --no-install-recommends --no-install-suggests \
        xz-utils libglx0 libegl1 libopengl0 libfontconfig1 libx11-6 libxkbcommon0 && \
# clean up
    apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# install calibre
ARG VERSION
RUN mkdir "${APP_DIR}/bin" && \
  curl -fsSL "https://download.calibre-ebook.com/${VERSION}/calibre-${VERSION}-arm64.txz" | tar xJf - -C "${APP_DIR}/bin" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/tmp/* && \
    chmod -R u=rwX,go=rX "${APP_DIR}"

COPY root/ /
