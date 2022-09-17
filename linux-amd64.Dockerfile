FROM hotio/base@sha256:68dd8f68bfeaa5efac3a2a9d1135e44fb11712ef378d6538806cfcb6c7a9b4cf

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

ARG VERSION
RUN mkdir "${APP_DIR}/bin" && \
  curl -fsSL "https://download.calibre-ebook.com/${VERSION}/calibre-${VERSION}-x86_64.txz" | tar xJf - -C "${APP_DIR}/bin" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/tmp/* && \
    chmod -R u=rwX,go=rX "${APP_DIR}"

COPY root/ /
