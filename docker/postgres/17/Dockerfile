FROM postgis/postgis:17-3.5
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      sudo \
      apt-utils \
      git \
      vim \
      build-essential \
      postgresql-server-dev-17 \
      postgresql-17-repack
RUN git clone -q https://github.com/pjungwir/aggs_for_vecs.git \
 && cd aggs_for_vecs \
 && make && sudo make install
