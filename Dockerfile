# @file Dockerfile
# @brief Build and run the semver application.
#
# @description This Dockerfile is designed to simplify and streamline the build process of the
# link:https://www.fb-brunnenbau.de[www.fb-brunnenbau.de] website by integrating and building its various
# components. The main purpose of this Dockerfile is to generate the documentation sites and the
# landing page of the website using different tools and configurations.
#
# Once all sites are built, the last stage starts a httpd server, making the website accessible over
# HTTP.
#
# === Example
#
# Use the xref:AUTO-GENERATED:bash-docs/build-and-run-sh.adoc[``build-and-run.sh``] script to build
# this image and start a container.
#
# == Prerequisites
#
# This image has been developed and tested with Docker version 24.0.2 on top of Ubuntu 22.10. 
#
# == Multistage Image
#
# This image is a multistage image, which means that the Dockerfile is structured to use multiple stages
# during the build process. The multistage build feature was introduced to Docker to help create more
# efficient and smaller Docker images.
#
# === Stage: ``build-antora``
#
# The Dockerfile leverages link:https://antora.org[Antora], a documentation site generator, to build the
# documentation sites of the website. Antora allows the documentation to be sourced from different
# repositories, making it easier to manage and update documentation across various projects. The
# configuration for Antora can be found in the ``configs/docs`` folder. The contents from all repos
# are cloned from GitHub because (a) project files from the local machine filesystem (the docker-host)
# are not present inside container and (b) maybe not all relevant repositories are cloned on the local
# workstation, making it impossible to mount everything into the container.
#
# // === Stage: ``build-hugo``
# // 
# // Apart from the documentation, the Dockerfile also handles the startpage of the website using
# // link:https://gohugo.io[Hugo]. Hugo is a flexible and efficient tool for creating static websites. The
# // contents, theme and other dependencies for Hugo can be found in the ``sites/root`` folder. 
# // 
# // The stage follows the instructions from https://gohugo.io/installation/linux.
#
# === Stage: ``run``
#
# Once all the sites are built, the last stage of the image initiates an HTTP server using the Docker image
# link:https://hub.docker.com/_/httpd[httpd]. This HTTP server makes the entire website accessible over
# HTTP. The resulting image from this stage only includes the built files needed for serving the website,
# avoiding any unnecessary dependencies or intermediate build artifacts from previous stages. This
# approach helps to create a more efficient and smaller Docker image, which is advantageous for
# production deployment and distribution and reduces the surface for protential attacks.
#
# To avoid running the image as ``rot``, permssions of ``/usr/local/apache2/logs`` are changed. This
# allows access for the ``www-data`` user and the default http port is changed to ``7888``. That way
# the image can be used without root permissions because the htpd server is started by the already existing
# ``www-data`` user,


FROM antora/antora:3.1.4 AS build-antora
LABEL maintainer="sebastian@sommerfeld.io"

COPY docs /docs
WORKDIR /docs

RUN yarn add @asciidoctor/core@~3.0.2 \
    && yarn add asciidoctor-kroki@~0.17.0 \
    && yarn add @antora/lunr-extension@~1.0.0-alpha.8

RUN antora --version \
    && antora playbook.yml --stacktrace --clean --fetch

# sleep for a moment ... otherwise the search-index.js is not built correctly
RUN sleep 5



# FROM node:20-bookworm-slim AS build-hugo
# LABEL maintainer="sebastian@sommerfeld.io"

# RUN npm install --location=global --ignore-scripts sass@1.64.1 \
#     && apt-get update \
#     && apt-get install -y --no-install-recommends hugo=0.111.3-1 \
#     && apt-get install -y --no-install-recommends asciidoctor=2.0.18-2 \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/*

# COPY sites /sites

# WORKDIR /sites/root/static/assets
# RUN npm install
# WORKDIR /sites/root
# RUN hugo



FROM httpd:2.4.58-alpine3.18 AS run
LABEL maintainer="sebastian@sommerfeld.io"

ARG USER=www-data
RUN sed -i "/Listen 80/s/.*/Listen 7888/" /usr/local/apache2/conf/httpd.conf \
    && chown -hR "$USER:$USER" /usr/local/apache2

RUN rm /usr/local/apache2/htdocs/index.html

COPY --from=build-antora /tmp/antora/fb-brunnenbau/public /usr/local/apache2/htdocs/docs

# COPY --from=build-hugo /sites/root/public /usr/local/apache2/htdocs

USER "$USER"
