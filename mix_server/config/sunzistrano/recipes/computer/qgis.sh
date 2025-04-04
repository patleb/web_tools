sun.install "gnupg software-properties-common"

mkdir -p /etc/apt/keyrings
wget -qO /etc/apt/keyrings/qgis-archive-keyring.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/qgis-archive-keyring.gpg] https://qgis.org/ubuntu-ltr $CODE main" | sudo tee /etc/apt/sources.list.d/qgis.list > /dev/null

sun.update
sun.install "qgis qgis-plugin-grass"
sun.install "ncview"
