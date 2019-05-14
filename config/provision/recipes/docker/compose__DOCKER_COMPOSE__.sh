DOCKER_COMPOSE_VERSION=<%= @sun.docker_compose || '1.23.2' %>

curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` > ~/docker-compose
chmod +x ~/docker-compose
mv ~/docker-compose /usr/local/bin/docker-compose

docker-compose --version
