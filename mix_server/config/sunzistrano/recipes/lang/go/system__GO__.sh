# https://gist.github.com/yrsdi/7ee60bbf3c62a6c168ff36ac1192aff5
# https://computingforgeeks.com/how-to-install-latest-go-on-centos-7-ubuntu-18-04/
GO_VERSION=<%= sun.go || '1.11.4' %>
PROFILE=/home/deployer/.bashrc

wget -c https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz
tar -xvf go$GO_VERSION.linux-amd64.tar.gz
chown -R root:root ./go
mv go /usr/local

echo 'export GOROOT=/usr/local/go' >> $PROFILE
echo "export GOPATH=/home/deployer/go" >> $PROFILE
echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> $PROFILE
