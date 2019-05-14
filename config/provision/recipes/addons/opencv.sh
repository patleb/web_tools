### TODO
# https://stackoverflow.com/questions/9166146/rails-options-for-build-bundler-gemfile

pip3 install --upgrade pip
pip3 install numpy
pip3 install --user scipy
pip3 install --user tensorflow
pip3 install --user opencv-contrib-python

bundle config build.ruby-opencv --with-opencv-dir=$(which opencv)
