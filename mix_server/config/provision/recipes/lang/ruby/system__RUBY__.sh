case "$OS" in
ubuntu)
  sun.install "ruby-full"
  echo 'gem: --no-document' > $HOME/.gemrc
  gem install bundler
;;
centos)
  sun.install "ruby-devel"
  echo 'gem: --no-document' > $HOME/.gemrc
  echo 'gem: --no-document' > ~/.gemrc
  gem install bundler -v=1.17.3
;;
esac
