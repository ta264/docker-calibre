FROM hotio/base@sha256:453a0df72a0639063c43d39bfa60063ef0657a99b2fe8f4ce55d20b2ad353bd7

ARG DEBIAN_FRONTEND="noninteractive"

ENV CALIBRE_CONFIG_DIRECTORY=${CONFIG_DIR}
ENV BOOK_DIR="/books"

EXPOSE 8081

# install packages
RUN apt update && \
    apt install -y --no-install-recommends --no-install-suggests \
        xz-utils libgl1-mesa-glx libfontconfig1 && \
# clean up
    apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

ARG X64_VERSION
RUN mkdir "${APP_DIR}/bin" && \
  curl -fsSL "https://download.calibre-ebook.com/${X64_VERSION}/calibre-${X64_VERSION}-x86_64.txz" | tar xJf - -C "${APP_DIR}/bin" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/tmp/* && \
    chmod -R u=rwX,go=rX "${APP_DIR}"

COPY root/ /
