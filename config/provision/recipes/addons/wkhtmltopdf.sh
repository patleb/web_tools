# Instead, use https://github.com/zakird/wkhtmltopdf_binary_gem
sun.install "libxrender1"
sun.install "fontconfig"
sun.install "xvfb"
sun.install "xfonts-75dpi"

wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz -P /tmp/
tar xf /tmp/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz -C /opt
ln -s /opt/wkhtmltox/bin/wkhtmltopdf /usr/bin/wkhtmltopdf
