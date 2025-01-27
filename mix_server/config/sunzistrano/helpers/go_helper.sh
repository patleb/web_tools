sun_setup_attributes_after+=('go.set_bin_path')

go.set_bin_path() {
  export PATH="$HOME/go/bin:$PATH"
}
