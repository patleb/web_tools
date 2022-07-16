DOCKER_COMPOSE_VERSION=<%= sun.docker_compose || '1.27.4' %>

curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` > $HOME/docker-compose
chmod +x $HOME/docker-compose
mv $HOME/docker-compose /usr/local/bin/docker-compose

docker-compose --version
