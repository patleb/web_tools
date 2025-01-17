sun_setup_attributes_after+=('go.set_bin_path')

git.clone() {
  mkdir $HOME/github
  cd $HOME/github
  git clone "$@"
}

go.set_bin_path() {
  export PATH="$HOME/go/bin:$PATH"
}
