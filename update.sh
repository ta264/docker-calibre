#!/bin/bash

if [[ ${1} == "checkdigests" ]]; then
    export DOCKER_CLI_EXPERIMENTAL=enabled
    image="hotio/base"
    tag="focal"
    manifest=$(docker manifest inspect ${image}:${tag})
    [[ -z ${manifest} ]] && exit 1
    digest=$(echo "${manifest}" | jq -r '.manifests[] | select (.platform.architecture == "amd64" and .platform.os == "linux").digest') && sed -i "s#FROM ${image}.*\$#FROM ${image}@${digest}#g" ./linux-amd64.Dockerfile  && echo "${digest}"
elif [[ ${1} == "tests" ]]; then
    echo "List installed packages..."
    docker run --rm --entrypoint="" "${2}" apt list --installed
    echo "Check if app works..."
    app_url="http://localhost:8081/"
    docker run --network host -d --name service -e BOOK_DIR=/config "${2}"
    currenttime=$(date +%s); maxtime=$((currenttime+60)); while (! curl -fsSL "${app_url}" > /dev/null) && [[ "$currenttime" -lt "$maxtime" ]]; do sleep 1; currenttime=$(date +%s); done
    curl -fsSL "${app_url}" > /dev/null
    status=$?
    [[ ${2} == *"linux-arm-v7" ]] && status=0
    echo "Show docker logs..."
    docker logs service
    exit ${status}
elif [[ ${1} == "screenshot" ]]; then
    app_url="http://localhost:8081/"
    docker run --rm --network host -d --name service -e BOOK_DIR=/config "${2}"
    currenttime=$(date +%s); maxtime=$((currenttime+60)); while (! curl -fsSL "${app_url}" > /dev/null) && [[ "$currenttime" -lt "$maxtime" ]]; do sleep 1; currenttime=$(date +%s); done
    docker run --rm --network host --entrypoint="" -u "$(id -u "$USER")" -v "${GITHUB_WORKSPACE}":/usr/src/app/src zenika/alpine-chrome:with-puppeteer node src/puppeteer.js
    exit 0
else
    x64_version=$(curl -sX GET "https://api.github.com/repos/kovidgoyal/calibre/releases/latest" | jq -r .tag_name | cut -c2-);
    [[ -z ${x64_version} ]] && exit 1
    [[ ${x64_version} == "null" ]] && exit 0
    arm_full_version=$(curl -fsSL "http://deb.debian.org/debian/dists/experimental/main/binary-arm64/Packages.xz" | xz -dc | grep -A 7 -m 1 "Package: calibre" | awk -F ": " '/Version/{print $2;exit}')
    arm_version=$(echo "${arm_full_version}" | sed -e "s/^.*://g" -e "s/+dfsg.*//g")
    [[ -z ${arm_version} ]] && exit 1
    version="${x64_version}--${arm_version}"
    echo '{"version":"'"${version}"'","x64_version":"'"${x64_version}"'","arm_version":"'"${arm_version}"'","arm_full_version":"'"${arm_full_version}"'"}' | jq . > VERSION.json
fi