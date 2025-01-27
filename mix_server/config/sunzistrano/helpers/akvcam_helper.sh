akvcam.status() { # PUBLIC
  local device=$(akvcam.device)
  if [[ -z "${device}" ]]; then
    echo.warning "No device found"
  else
    v4l2-ctl -d $device --all
  fi
}

akvcam.device() { # PUBLIC
  v4l2-ctl --list-devices # TODO
}

akvcam.load() { # PUBLIC
  cd.akvcam
  sudo modprobe videodev
  sudo insmod akvcam.ko
  cd.back
}

akvcam.unload() { # PUBLIC
  cd.akvcam
  sudo rmmod akvcam.ko
  cd.back
}

akvcam.install() { # PUBLIC
  cd.akvcam
  sudo make dkms_install
  cd.back
}

akvcam.uninstall() { # PUBLIC
  cd.akvcam
  sudo make dkms_uninstall
  cd.back
}

akvcam.version() { # PUBLIC
  echo $(tail -n1 $(sun.manifest_path 'akvcam'))
}

cd.akvcam() {
  local version=$(akvcam.version)
  cd "$(git.dir.release webcamoid akvcam $version)/src"
}
