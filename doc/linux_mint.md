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

## Rubymine

- [https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit](inotify):
- File / Settings / Editor / Font / Font [DejaVu Sans Mono], Size [12], Line spacing [1.3]
- File / Settings / Editor / Color Scheme / Scheme [Classic Light]
- File / Settings / Editor / Color Scheme / Language Defaults / Italic [false]

## Panel Shortcuts

- show desktop, files, system monitor, terminator, chromium, calculator, vscode, rubymine

## Keyboard Quirks

- Home / End keys only in text editors (doesn't work in terminals):

Fn + Up    --> Pg Up
Fn + Down  --> Pg Dn
Fn + Left  --> Home
Fn + Right --> End

- [https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles/blob/master/useful_scripts/touchpad_toggle.sh](Touchpad Toggle):

```sh

```

## Directories/Files (backup/restore)

```sh
sudo apt-get install acl
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

- QGIS
- VSCode
- Toolbox App, Rubymine
- CLion, Cling
- Cheese, Deluge
- VLC, Spotify
- Calibre, Shutter
- Remmina
- VirtualBox

# TODO bash copy-paste safeguard --> https://unix.stackexchange.com/questions/309786/disable-default-copypaste-behaviour-in-bash/309798#309798

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
  dirmngr gnupg \
  imagemagick \
  libcurl4-openssl-dev \
  libffi-dev \
  libgdbm5 libgdbm-dev \
  libgmp-dev \
  libncurses5-dev \
  libreadline-dev \
  libssl-dev \
  libvips libvips-dev libvips-tools \
  libxml2-dev libxml2-utils \
  libxslt1-dev \
  libyaml-dev \
  m4 \
  mmv \
  openssh-server \
  openssl \
  patch \
  pigz \
  pssh \
  pv \
  sqlite3 libsqlite3-dev \
  software-properties-common \
  time \
  zlib1g-dev
sudo apt-get -y install \
  python-dev \
  python-pip \
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
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update && sudo apt-get -y install libpq-dev postgresql-client-11
```

## Docker

```bash
source /etc/os-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable"
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
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt-get -y install nodejs
...
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt-get -y install yarn
```

## QGIS

```bash
sudo add-apt-repository ppa:ubuntugis/ubuntugis-unstable
wget -O - https://qgis.org/downloads/qgis-2019.gpg.key | gpg --import
gpg --fingerprint 51F523511C7028C3
gpg --export --armor 51F523511C7028C3 | sudo apt-key add -
sudo apt update && sudo apt-get -y install qgis python-qgis
```

### QGIS pip3 troubleshoot

- https://stackoverflow.com/questions/47955397/pip3-error-namespacepath-object-has-no-attribute-sort

## Ruby

```bash
sudo apt-get -y install libjemalloc-dev
...
git clone git@github.com:rbenv/rbenv.git ~/.rbenv
... yes
git clone git@github.com:rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
git clone git@github.com:rbenv/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash
git clone git://github.com/dcarley/rbenv-sudo.git ~/.rbenv/plugins/rbenv-sudo
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
echo 'gem: --no-document' > ~/.gemrc
. ~/.bashrc
RBENV_OPTIONS='--with-jemalloc --enable-shared --disable-install-doc --disable-install-rdoc --disable-install-capi'
RUBY_CONFIGURE_OPTS=$RBENV_OPTIONS rbenv install 2.6.5
rbenv global 2.6.5
echo 'require "irb/ext/save-history"' > ~/.irbrc
echo 'IRB.conf[:SAVE_HISTORY] = 1000' >> ~/.irbrc
echo $'IRB.conf[:HISTORY_FILE] = "#{ENV[\'HOME\']}/.irb-history"' >> ~/.irbrc
echo 'export PATH=".git/safe/../../bin:$PATH"' >> ~/.bashrc
echo 'alias be="bundle exec "' >> ~/.bashrc
```

## Terminator

- Preferences / Profiles / Scrolling / Infinite Scrollback [true]

## VirtualBox + Vagrant

- https://www.virtualbox.org/wiki/Downloads
- https://www.vagrantup.com/downloads.html

```bash
vagrant plugin install vagrant-hostmanager
```

## Python GIS + Openstack

```bash
sudo pip3 install --upgrade cython
sudo pip3 install python-openstackclient
sudo pip3 install matplotlib==3.2.1
sudo pip3 install pyproj==2.6.1
sudo apt-get install -y python3-psycopg2 python3-numpy python3-tk python3-netcdf4 netcdf-bin gdal-bin libgdal-dev ncview
```

# TODO https://www.reddit.com/r/programming/comments/js5go2/90_frequently_used_linux_commands/
