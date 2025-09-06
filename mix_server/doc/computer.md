# Linux Mint 22.1 ([Extras](https://easylinuxtipsproject.blogspot.com/p/1.html))

## Bootable USB (Dell laptop)

- Download most recent Dell BIOS executable on a FAT-32 formatted USB, then update from file in BIOS Update menu
- Switch from RAID to AHCI: https://gist.github.com/chenxiaolong/4beec93c464639a19ad82eeccc828c63
- Deactivate secure boot
- Download 22.1 cinnamon, make a bootable USB
  - if mmx64.efi error, then add boot option pointing to /EFI/BOOT/grubx64.efi from USB drive
  - remove boot option when done

## BIOS:

- Power Management / Wake on Dell USB-C Dock (deactivate)
- Power Management / Power On Lid Open (deactivate)
- Power Management / Battery Charge Configuration (Custom 50-80)

## Keyboard Quirks

- Home / End keys only in text editors (doesn't work in terminals):

Fn + Up    --> Pg Up
Fn + Down  --> Pg Dn
Fn + Left  --> Home
Fn + Right --> End

- [Touchpad Toggle](https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles/blob/master/useful_scripts/touchpad_toggle.sh):

## Extra hard drive

- Open "Disks"
- Format extra disk with ext4 (optional)
- Edit mount options: change mount point to `/mnt/storage` and identify as `LABEL=storage`

## User

```shell
sudo passwd root
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$USER"
sudo chmod 440 "/etc/sudoers.d/$USER"
```

## Sunzistrano

```shell
sudo apt install -y ruby ruby-dev ruby-bundler libyaml-dev libpq-dev git moreutils
echo 'gem: --no-document' > ~/.gemrc
mkdir .gems
mkdir ~/code && cd ~/code
git clone https://github.com/patleb/web_tools.git
cd web_tools
GEM_HOME=~/.gems bundle install
GEM_HOME=~/.gems bin/sun computer install
echo 'export PATH=".git/safe/../../bin:$PATH"' >> ~/.bashrc
```

Note: run `mkdir -p .git/safe` with every new `git clone` of a trusted project.

## WebTools

```shell
gem install bundler
bundle install
sudo chown -R $USER:$USER "$HOME/.npm"
rm -f ~/package.json
yarn install
cp config/secrets.example.yml config/secrets.yml
sudo chmod 600 .multipass/key
sudo chmod 644 .multipass/key.pub
```

## VirtualBox

- https://itsfoss.com/install-linux-mint-in-virtualbox/

## System Settings

- Mouse and Touchpad / Reverse scrolling direction (deactivate)
- Firewall (enable)
- Power Management / Power / Turn off the screen when inactive for (a/c: never, battery: 10 minutes)
- Power Management / Power / When the lid is closed (lock screen)
- Power Management / Power / Perform lid-closed action event with external monitors attached (activate)
- Power Management / Brightness / Dim screen after inactive for (10 minutes)
- Power Management / Brightness / Keyboard backlight (0%)
- Screensaver / Delay before starting the screensaver (never)
- Login Window > Users > Hide the user list
- Login Window > Users > Allow Manual Login
- Login Window > Settings > Hostname (deactivate)
- Display [1440x810]
- Panel / Panel height [25]
- Privacy / Remember recently accessed files [false]

### Panel buttons (click Preferences / Configure)

- Grouped Window List applet > Middle click action [Launch new app instance] 
- Window List add applet

### File explorer

- Edit / Preferences / Views / View new folders using [List View]
- View / Show Hidden Files [true]

### Panel Shortcuts

- system monitor, files, terminator, calculator, chromium, vscodium

## Chromium Settings

- Privacy and security > Security > Toggle to "Always use secure connections."
- Appearance           > Use Classic
- Appearance           > Toggle "Show Home button" and Use "https://startpage.com"
- Appearance           > Remove "Use system title bar and borders"
- Search Engine        > Startpage
- Default Browser      > Make default
- On start-up          > Continue where you left off
- Languages            > Preferred languages > Move to top "English (United States)"
- Languages            > Google Translate > Never offer to translate > Add Languages "French"
- Password Manager     > Offer to save passwords [false]

## KeePassXC Settings

- Startup > Toggle "Automatically launch KeePassXC at system startup
- Startup > Minimize window after unlocking database
- User Interface > Minimize instead of app exit
- User Interface > Show a system tray icon
- User Interface > Hide window to system tray when minimized

## Audacious [Skins](https://archive.org/details/winampskins)

```shell
cd ~
wget -q https://archive.org/download/winampskin_Nucleo_AlienMind_v5/Nucleo_AlienMind_v5.wsz
sudo unzip Nucleo_AlienMind_v5.wsz -d /usr/share/audacious/Skins/NucleoAlienMind_v5
rm -f Nucleo_AlienMind_v5.wsz
```

- File > Settings > Plugins > General > Status Icon [true] > Settings > Close to the system tray [true]

### VSCodium

```shell
sudo apt install dirmngr software-properties-common apt-transport-https curl -y
curl -fSsL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo gpg --dearmor | sudo tee /usr/share/keyrings/vscodium.gpg > /dev/null
echo deb [signed-by=/usr/share/keyrings/vscodium.gpg] https://download.vscodium.com/debs vscodium main | sudo tee /etc/apt/sources.list.d/vscodium.list
sudo apt update && sudo apt install codium -y
```

- User > Text Editor > Font > Font Size [12]
- User > Editor > Line Height [1.7]
- User > Window > Density > Editor Tab Height [compact]
- User > Window > Open Folders In New Window [on]
- User > Window > New Window Dimensions [inherit]
- Theme > High contrast
- Extensions: GitLens, Docker, DBCode, Ruby LSP, Crystal Language, clangd, Octave Execution
  - Clangd: Fallback Flags:
    - -I/usr/include/c++/13
    - -I/usr/lib/gcc/x86_64-linux-gnu/13/include
    - -I/usr/include/ruby-3.2.0
    - -I/usr/include/x86_64-linux-gnu/ruby-3.2.0

## Rubymine

- [inotify](https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit):
- Appearance & Behavior > Appearance > Theme [High Contrast]
- Editor > Font > Font [DejaVu Sans Mono], Size [12], Line spacing [1.3]
- Editor > Inspections > Proofreading > Typo [false]
- Editor > Inspections > Ruby > Code metrics [false]
- Editor > Inspections > Code style issues > Class variable usage [false]
- Editor > Inspections > Probable bugs > Unresolved reference [false]
- Plugins: Classic UI
- Settings > Version Control > Commit > Use non-modal commit interface [false]
- Settings > Editor > Inlay Hints > Code vision, Parameter names, Types [false]

## Terminator

- Preferences / Profiles / Scrolling / Infinite Scrollback [true]
- Preferences / Profiles / General / Show titlebar [false]
- Preferences / Global / Appearance / Terminal separator size [4]
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

## SSH Config

Add the following to your `~/.ssh/config` file ([references](https://carlosbecker.dev/posts/ssh-tips-and-tricks/)):

```sh
# ~/.ssh/config
# -------------
Host *
  ServerAliveInterval   300s
Host virtual.test
  UserKnownHostsFile    /dev/null
  StrictHostKeyChecking no
  User                  ubuntu
  User                  deployer
  ForwardAgent          yes
  ControlMaster         auto
  ControlPath           ~/.ssh/%r@%h:%p.sock
  ControlPersist        300s
```

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

## Other Softwares

- Gpick

## Software Manager

- Cling
- Calibre
- Remmina

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
