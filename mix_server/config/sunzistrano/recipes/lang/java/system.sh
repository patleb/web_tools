sun.install "default-jdk-headless"

JAVA_HOME="$(dirname $(dirname $(readlink $(readlink $(which javac)))))"

<%= Sh.delete_line! '/etc/environment', 'export JAVA_HOME=$JAVA_HOME', escape: false %>
sh -c "echo export JAVA_HOME=$JAVA_HOME >> /etc/environment"
