[<img src="https://raw.githubusercontent.com/kovidgoyal/calibre/master/resources/images/lt.png" alt="logo" height="130" width="130">](https://github.com/kovidgoyal/calibre)

## Starting the container

CLI:

```shell
docker run --rm \
    --name calibre \
    -p 8081:8081 \
    -e PUID=1000 \
    -e PGID=1000 \
    -e UMASK=002 \
    -e TZ="Etc/UTC" \
    -v /<host_folder_config>:/config \
    -v /<host_folder_books>:/books \
    ta264/docker-calibre
```

Compose:

```yaml
version: "3.7"

services:
  calibre:
    container_name: calibre
    image: ta264/docker-calibre
    ports:
      - "8081:8081"
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
    volumes:
      - /<host_folder_config>:/config
      - /<host_folder_books>:/books
```

### Alternative library location
If you want calibre to use a book library somewhere other than `/books`, set the `BOOK_DIR` environment variable to the directory you want to use.

### Authentication
To enable authentication, set environment variables `USER` and `PASSWORD`.  You can also set the environment variable `AUTH_MODE` to set the authentication mode.  Set to "basic" if you are putting this server behind an SSL proxy. Otherwise, leave it unset, which will use "basic" if SSL is configured otherwise it will use "digest".

### URL Prefix
A prefix to prepend to all URLs. Useful if you wish to run this server behind a reverse proxy. For example use, `/calibre` as the URL prefix.  To enable, set the environment variable `URL_PREFIX` to the desired prefix.

### Additional arguments to `calibre-server`
If the environment variable `ARGS` is set it will be passed to `calibre-server` on startup.