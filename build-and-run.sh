#!/bin/bash
# @file build-and-run.sh
# @brief Build a Docker image containing the whole www.fb-brunnenbau.de website and run locally inside a Docker container.
#
# @description The script automates the process of creating a Docker image that encapsulates
# the entire link:https://www.fb-brunnenbau.de[fb-brunnenbau.de website] within an Apache httpd web
# server and launches it as a container for local testing. The website is built with Antora first.
# This script simplifies the setup and configuration required to run the website locally. The
# image is based on the official link:https://hub.docker.com/_/httpd[Apache httpd] image.
#
# After the image is successfully built, the script launches a Docker container based on the
# newly created image. The container is started in the foreground. The locally hosted website
# can be accessed via a web browser at http://localhost:7888.
#
# === Script Arguments
#
# The script does not accept any parameters.
#
# == The webserver image
#
# Per default, Apache httpd runs as ``root`` user because only root processes can listen to ports
# below 1024. The default http port for web applications is 80. But this means the user inside the
# container is ``root`` which poses a potential security risk. And since the webserver is running
# inside a Docker container it is not important what port is used inside the container. So the http
# port is changed to 7888 and the user is switched to the already present user ``www-data``.
#
# Apache is trying to write a file into ``/usr/local/apache2/logs``, but the ``www-data`` user does
# not have permission to create files in this directory. So permissions to this directory are
# updated as well.
#
# | What                      | Port | Protocol |
# | ------------------------- | ---- | -------- |
# | ``local/fbb-website:dev`` | 7888 | http     |
#
# The image is intended for local testing purposes only.


DOCKER_HOST_GATEWAY="$(ip -4 addr show scope global dev docker0 | grep inet | awk '{print $2}' | cut -d / -f 1 | sed -n 1p)"
readonly DOCKER_HOST_GATEWAY
readonly DOCKER_IMAGE="local/fbb-website:dev"
readonly PORT=7888


echo -e "$LOG_INFO Remove old versions of $DOCKER_IMAGE"
docker image rm "$DOCKER_IMAGE"

echo -e "$LOG_INFO Build Docker image $DOCKER_IMAGE"
echo -e "$LOG_INFO DOCKER_HOST_GATEWAY = $DOCKER_HOST_GATEWAY"
docker build --no-cache --add-host="docker-host-gateway:$DOCKER_HOST_GATEWAY" -t "$DOCKER_IMAGE" .

echo -e "$LOG_INFO Run Docker image"
docker run --rm mwendler/figlet "$PORT"
docker run --rm -p "$PORT:7888" "$DOCKER_IMAGE"
