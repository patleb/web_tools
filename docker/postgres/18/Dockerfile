FROM postgis/postgis:18-3.6
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      sudo \
      apt-utils \
      git \
      vim \
      build-essential \
      postgresql-server-dev-18 \
      postgresql-18-repack
RUN git clone -q https://github.com/pjungwir/aggs_for_vecs.git \
 && cd aggs_for_vecs \
 && make && sudo make install
