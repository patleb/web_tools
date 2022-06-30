FROM postgis/postgis:13-3.1
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get install -y sudo apt-utils
RUN apt-get -qq install --no-install-recommends vim > /dev/null
