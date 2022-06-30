FROM postgis/postgis:14-3.2
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      sudo \
      apt-utils \
      git \
      vim \
      build-essential \
      liblz4-dev \
      postgresql-server-dev-14 \
      postgresql-14-repack \
      pgxnclient \
 && pgxn install vector \
 && git clone git://github.com/pjungwir/aggs_for_vecs.git \
 && cd aggs_for_vecs \
 && make && sudo make install
