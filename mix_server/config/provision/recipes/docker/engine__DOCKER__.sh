# https://gist.github.com/BretFisher/deaa626107d4b976410946b243001bb4#file-docker-xenial-copy-paste-sh
# https://sandro-keil.de/blog/2017/01/23/docker-daemon-tuning-and-json-file-configuration/

DEPLOYER_NAME=<%= sun.deployer_name %>
DOCKER_VERSION=<%= "=#{sun.docker || '18.09.3~ce-0~ubuntu'}" %>
DOCKER_MANIFEST=$(sun.manifest_path 'docker-ce')

if [[ ! -s "$DOCKER_MANIFEST" ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=$ARCH] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable"
  sun.update

  systemctl disable lxcfs

  sun.install "docker-ce$DOCKER_VERSION --allow-change-held-packages"
  apt-mark hold docker-ce

  usermod -aG docker $DEPLOYER_NAME

  <%= Sh.sub! '/etc/default/grub', %{GRUB_CMDLINE_LINUX="#{'net.ifnames=0 biosdevname=0 ' if sun.env.vagrant?}"}, 'GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"' %>
  update-grub

  sun.move '/etc/logrotate.d/docker' 0440 root:root
  mkdir -p '/opt/docker_data'
  # printf '{ "userns-remap" : "default" , "storage-driver" : "overlay2" }' > /etc/docker/daemon.json
else
  sun.update

  apt-mark unhold docker-ce
  sun.install "docker-ce$DOCKER_VERSION --allow-change-held-packages"
  apt-mark hold docker-ce
fi

echo "$DOCKER_VERSION" >> "$DOCKER_MANIFEST"

systemctl restart docker

# docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' portainer

# https://ypereirareis.github.io/blog/2015/05/04/docker-with-shell-script-or-makefile/
# https://blog.xebialabs.com/2017/05/18/5-docker-utilities-you-should-know/
# https://github.com/veggiemonk/awesome-docker
