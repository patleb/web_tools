JAVA_VERSION=<%= @sun.java || '8' %>

case "$OS" in
ubuntu)
  sun.install "openjdk-$JAVA_VERSION-jdk-headless"
;;
centos)
  sun.install "java-1.$JAVA_VERSION.0-openjdk"
  sun.install "java-1.$JAVA_VERSION.0-openjdk-devel"
;;
esac

sh -c "echo export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which javac))))) >> /etc/environment"
