__JAVA__=${__JAVA__:-11}

sun.install "openjdk-$__JAVA__-jdk-headless"

sh -c "echo export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which javac))))) >> /etc/environment"
