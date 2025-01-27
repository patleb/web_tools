### Examples
# https://github.com/fangfufu/Linux-Fake-Background-Webcam/blob/master/akvcam/config.ini
# https://github.com/webcamoid/akvcam/blob/master/share/config_example.ini
versions=$(sun.manifest_path 'akvcam')

sun.install "dkms v4l-utils"

if [ -f $versions ]; then
  akvcam.unload
  akvcam.uninstall
fi

if git.clone.latest webcamoid akvcam; then
  version=$(basename $(dirname $(pwd)))
  cd src
  make && sudo make install
  echo "$version" >> $versions
fi

akvcam.install
