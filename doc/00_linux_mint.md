# Linux Mint 19.3 (for Dell)

## From bootable USB

- Download most recent Dell BIOS executable on a FAT-32 formatted USB, then update from file in BIOS Update menu
- Switch from RAID to AHCI: https://gist.github.com/chenxiaolong/4beec93c464639a19ad82eeccc828c63
- Deactivate secure boot
- Download 19.3 cinnamon, make a bootable USB
  - if mmx64.efi error, then add boot option pointing to /EFI/BOOT/grubx64.efi from USB drive
  - remove boot option when done

## Extra hard drive

- Open "Disks"
- Format extra disk with ext4
- Edit mount options: change mount point to /mnt/storage and identify as LABEL=storage

## Timeshift

- Update Manager / Edit / System Snapshots
- Wizard / RSYNC / chose extra disk / daily 5, weekly 3, monthly 2 / finish
- Create (5.5GB)

## Updates

- Language packages
- NVIDIA proprietary drivers

## Swap

- Increase swap:

```sh
sudo swapoff -a
sudo rm /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1M count=8192
sudo chmod 0600 /swapfile
sudo mkswap /swapfile
sudo swapon -a
```

- Improve usage:

```sh
sudo vi /etc/sysctl.conf
### Add ###
vm.swappiness=10
vm.vfs_cache_pressure=50
```

## User

- Set password to root user: `sudo passwd root`
- Set sudoless user:

```sh
sudo echo "$USER ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/$USER
sudo chmod 0440 /etc/sudoers.d/$USER
sudo chown root:root /etc/sudoers.d/$USER
```

## Software Manager

- replace Blueberry with Blueman
- remove Transmission-gtk
- chromium-browser (and use Manage Sync to transfer --> stop after usage, it slows the browser)
- terminator, filezilla, deluge, vlc, gimp, shutter

## BIOS:

- Power Management / Wake on Dell USB-C Dock (deactivate)
- Power Management / Power On Lid Open (deactivate)
- Power Management / Battery Charge Configuration (Custom 50-80)

## System Settings

- Mouse and Touchpad / Reverse scrolling direction (deactivate)
- Bluetooth (deactivate)
- Firewall (enable)
- Power Management / Power / Turn off the screen when inactive for (a/c: never, battery: 5 minutes)
- Power Management / Power / When the lid is closed (lock screen)
- Power Management / Power / Perform lid-closed action event with external monitors attached (activate)
- Power Management / Brightness / Dim screen after inactive for (5 minutes)
- Power Management / Brightness / Keyboard backlight (0%)
- Screensaver / Delay before starting the screensaver (never)
- Login Window / Users / Hide the user list
- Login Window / Settings / Hostname (deactivate)
- Display [1368x768]
- Font Selection [10 --> 9]
- Panel / Panel height [22], Font size [8.5pt], Allow the pointer to pass through the edges of the panels [true]
- Privacy / Remember recently accessed files [false]

## Panel buttons (click Preferences / Configure)

- Replace Grouped Window List applet with Window List and Panel Launcher (use Desktop shortcuts to find configs)
- Show window thumbnails on hover [false]

## File explorer

- Edit / Preferences / Views / View new folders using [List View]
- View / Show Hidden Files [true]

## Rhythmbox

- Tools / Plugins / Notification [false]

## Chromium

- Set as default
- Settings / Appearance / Use system title bar and borders [false]

## Deluge

- Set as default for torrents
- Edit / Preferences / Downloads / Download to [storage/deluge]
- Edit / Preferences / Queue / Active torrents [16 actives = (12 + 4)]
- Edit / Preferences / Interface / System tray / Minimize to tray on close [true], Enable application indicator [false]
- Edit / Preferences / Other / Associate Magnet links with Deluge [true]
- ~/.config/deluge/gtkui.conf --> "ntf_tray_blink": false

## Panel Shortcuts

- show desktop, files, system monitor, terminator, chromium, calculator, rubymine

## Keyboard Quirks

- Home / End keys only in text editors (doesn't work in terminals):

Fn + Up    --> Pg Up
Fn + Down  --> Pg Dn
Fn + Left  --> Home
Fn + Right --> End

- [Touchpad Toggle](https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles/blob/master/useful_scripts/touchpad_toggle.sh):

```sh

```

## Directories/Files (backup/restore)

```sh
sudo apt-get install -y acl
cd /path/to/dir_name && sudo getfacl -R . > permissions.txt
cd .. && sudo tar -czf dir_name.tar.gz dir_name
...
tar -C /path/to -xf dir_name.tar.gz
cd /path/to/dir_name
sed -i '/# owner: old_owner/c\# owner: new_owner' permissions.txt
sed -i '/# group: old_group/c\# group: new_group' permissions.txt
sudo setfacl --restore=permissions.txt
```

## GUI Softwares (check if better in software manager)

- Tor Browser Launcher
- QGIS
- Toolbox App, Rubymine
- CLion, Cling
- Deluge, VLC
- Calibre, Shutter, Xournal
- Remmina
- VirtualBox

## Terminator

- Preferences / Profiles / Scrolling / Infinite Scrollback [true]
- TODO dircolors --> https://ubuntuforums.org/showthread.php?p=4779965

```bash
vi $HOME/.config/terminator/config
...
    [[[window0]]]
      parent = ""
      type = Window
      size = 1320, 800
...
```

## Packages

```bash
sudo apt update

sudo apt-get -y install \
  apt-transport-https \
  autoconf \
  bc \
  bison \
  build-essential \
  ca-certificates \
  castxml \
  clang \
  cmake \
  git \
  graphviz \
  dirmngr gnupg \
  imagemagick libpng-dev libjpeg-dev \
  libcurl4-openssl-dev \
  libffi-dev \
  libgdbm5 libgdbm-dev \
  libgmp-dev \
  libncurses5-dev \
  libreadline-dev \
  libssl-dev \
  libxml2-dev libxml2-utils \
  libxslt1-dev \
  libyaml-dev \
  m4 \
  mmv \
  net-tools \
  openssh-server \
  openssl \
  patch \
  pigz \
  pssh \
  pv \
  sqlite3 libsqlite3-dev \
  software-properties-common \
  time \
  whois \
  zlib1g-dev \
sudo apt-get -y install \
  python3-pip \
  python3-dev
```

## Git

```bash
git config --global user.name "Firstname Lastname"
git config --global user.email "firstname_lastname@domain.com"
git config --global core.excludesfile "~/.gitignore_global"
git config --global core.autocrlf "input"
echo '.idea/*' > ~/.gitignore_global
echo '/.vscode/' >> ~/.gitignore_global
echo '/.history/' >> ~/.gitignore_global
echo '/node_modules/' >> ~/.gitignore_global
```

## PostgreSQL Client

```bash
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RELEASE=$(. /etc/os-release && echo $UBUNTU_CODENAME)
echo "deb [arch=$(dpkg --print-architecture)] http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update && sudo apt-get -y install libpq-dev postgresql-client
```

## Docker

```bash
source /etc/os-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable"
sudo apt update
sudo apt-get -y install docker-ce
...
sudo usermod -aG docker $USER
sudo sed -ri -- 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cgroup_enable=memory\ swapaccount=1"/' /etc/default/grub
sudo update-grub
sudo mkdir -p '/opt/docker_data'
sudo systemctl restart docker
curl -L https://github.com/docker/compose/releases/download/1.27.4/docker-compose-`uname -s`-`uname -m` > ~/docker-compose
sudo chmod +x ~/docker-compose
sudo mv ~/docker-compose /usr/local/bin/docker-compose
```

## Nodejs

```bash
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get -y install nodejs
...
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb [arch=$(dpkg --print-architecture)] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt-get -y install yarn
echo 'export PATH="$(yarn global bin):$PATH"' >> ~/.bashrc
```

## Ruby

```bash
sudo apt-get -y install libjemalloc-dev
...
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
... yes
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
git clone https://github.com/rbenv/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash
git clone https://github.com/dcarley/rbenv-sudo.git ~/.rbenv/plugins/rbenv-sudo
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
echo 'gem: --no-document' > ~/.gemrc
. ~/.bashrc
RBENV_OPTIONS='--with-jemalloc --enable-shared --disable-install-doc --disable-install-rdoc --disable-install-capi'
RUBY_CONFIGURE_OPTS=$RBENV_OPTIONS rbenv install 2.7.6
rbenv global 2.7.6
echo 'require "irb/ext/save-history"' > ~/.irbrc
echo 'IRB.conf[:SAVE_HISTORY] = 1000' >> ~/.irbrc
echo $'IRB.conf[:HISTORY_FILE] = "#{ENV[\'HOME\']}/.irb-history"' >> ~/.irbrc
echo 'export PATH=".git/safe/../../bin:$PATH"' >> ~/.bashrc
echo 'alias be="bundle exec "' >> ~/.bashrc

gem install mailcatcher
```

Note: run `mkdir -p .git/safe` with every new `git clone` of a trusted project.

## Parallel

```bash
wget https://git.savannah.gnu.org/cgit/parallel.git/plain/src/parallel
chmod 755 parallel
sudo cp parallel sem
sudo cp parallel /bin
sudo cp sem /bin
sudo mv parallel sem /usr/bin/
```

## AGE

```bash
VERSION=$(curl -s "https://api.github.com/repos/FiloSottile/age/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
curl -Lo age.tar.gz "https://github.com/FiloSottile/age/releases/latest/download/age-v${VERSION}-linux-amd64.tar.gz"
tar xf age.tar.gz
sudo mv age/age /usr/local/bin
sudo mv age/age-keygen /usr/local/bin
rm -rf age.tar.gz
rm -rf age
```

## Osquery (optional)

```bash
export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $OSQUERY_KEY
sudo add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
sudo apt-get update
sudo apt-get install -y osquery
```

## RocksDB (optional)

```bash
sudo apt-get install -y libgflags-dev libsnappy-dev zlib1g-dev libbz2-dev liblz4-dev libzstd-dev
export rocksdb=6.20.3
sudo wget "https://github.com/facebook/rocksdb/archive/v${rocksdb}.zip"
sudo unzip "v${rocksdb}.zip"
cd "rocksdb-${rocksdb}"
sudo make -j8 static_lib && sudo make install-static
sudo make clean && sudo make -j8 shared_lib && sudo make install-shared
sudo ldconfig
sudo rm -f "v${rocksdb}.zip"
sudo rm -rf "rocksdb-${rocksdb}"
```

## VirtualBox + Vagrant

- https://www.virtualbox.org/wiki/Downloads (add Oracle VM VirtualBox Extension Pack)
- https://www.vagrantup.com/downloads.html

```bash
vagrant plugin install vagrant-hostmanager
```

## Openstack Client

```bash
sudo -H pip3 install python-openstackclient
```

## Python GIS

```bash
sudo -H pip3 install --upgrade cython
sudo -H pip3 install matplotlib==3.2.1
sudo -H pip3 install pyproj==2.6.1
sudo -H pip3 install rasterio==1.1.8
sudo apt-get install -y python3-psycopg2 python3-numpy python3-tk python3-netcdf4 netcdf-bin gdal-bin libgdal-dev ncview
```

## QGIS

```bash
# https://github.com/qgis/QGIS-Website/blob/master/source/site/forusers/alldownloads.rst
source /etc/os-release
wget -qO - https://qgis.org/downloads/qgis-2021.gpg.key | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import
sudo add-apt-repository "deb https://qgis.org/ubuntu $UBUNTU_CODENAME main"
sudo chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg
sudo apt update && sudo apt-get install -y qgis qgis-plugin-grass
```

## C++

```bash
sudo apt-get install -y libspdlog-dev libboost-all-dev
```

## VSCode

Download and install [VSCode](https://code.visualstudio.com/docs/setup/linux)

- https://code.visualstudio.com/docs/supporting/faq#_how-to-disable-telemetry-reporting
- https://code.visualstudio.com/docs/editor/settings-sync

## Rubymine

- [inotify](https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit):
- File / Settings / Editor / Font / Font [DejaVu Sans Mono], Size [12], Line spacing [1.3]
- File / Settings / Editor / Color Scheme / Scheme [Classic Light]
- File / Settings / Editor / Color Scheme / Language Defaults / Italic [false]

## Webcamoid

```
sudo apt-get install -y dkms v4l-utils
v4l2-ctl --list-devices
...
git clone https://github.com/webcamoid/akvcam.git
cd akvcam/src
make
VERSION=1.1.1
sudo mkdir -p /usr/src/akvcam-${VERSION}
sudo cp -ar * /usr/src/akvcam-${VERSION}
sudo dkms install akvcam/${VERSION}
cd ..
sudo mkdir -p /etc/akvcam
sudo cp share/config_example.ini /etc/akvcam/config.ini
sudo chmod -vf 644 /etc/akvcam/config.ini
echo akvcam | sudo tee /etc/modules-load.d/akvcam.conf
...
# download at https://webcamoid.github.io/
cd ~/Downloads
chmod +x webcamoid-installer-*
./webcamoid-installer-*
...
# reset settings
rm -rf ~/.config/Webcamoid
```

Download and install [Zoom](https://zoom.us/download?os=linux)

## KeePassXC

```sh
sudo apt-get install -y keepassxc
```

## SSH Config

Add the following to your `~/.ssh/config` file ([references](https://carlosbecker.dev/posts/ssh-tips-and-tricks/)):

```sh
# ~/.ssh/config
# -------------
Host *
  ServerAliveInterval   300s
Host vagrant-*.test
  UserKnownHostsFile    /dev/null
  StrictHostKeyChecking no
Host vagrant-*.test
  User                  deployer
  ForwardAgent          yes
  ControlMaster         auto
  ControlPath           ~/.ssh/%r@%h:%p.sock
  ControlPersist        300s
```
