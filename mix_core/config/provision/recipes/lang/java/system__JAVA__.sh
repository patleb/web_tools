__JAVA__=${__JAVA__:-11}

case "$OS" in
ubuntu)
  sun.install "openjdk-$__JAVA__-jdk-headless"
;;
centos)
  if sun.version_is_smaller "$__JAVA__" "11"; then
    __JAVA__="1.$__JAVA__.0"
  fi
  sun.install "java-$__JAVA__-openjdk"
  sun.install "java-$__JAVA__-openjdk-devel"
;;
esac

sh -c "echo export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which javac))))) >> /etc/environment"
