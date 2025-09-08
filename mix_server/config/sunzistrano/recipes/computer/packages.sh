if [ -f /etc/apt/preferences.d/nosnap.pref ]; then
  mv /etc/apt/preferences.d/nosnap.pref "$HOME/nosnap.backup"
fi

sun.add_repo "ppa:ubuntuhandbook1/apps"
sun.add_repo "ppa:phoerious/keepassxc"
sun.update

#  scilab
#  wxmaxima
#  xcas
#  freecad
#  openscad
<% %W(
  age
  audacious audacious-plugins
  chromium
  filezilla
  gimp
  gparted
  graphviz
  keepassxc
  lftp
  octave octave-dev
  psensor
  shutter
  snapd
  terminator
  virtualbox
  vlc
  xournalpp
  yt-dlp
).compact_blank.each do |package| %>
  sun.install "<%= package %>"
<% end %>

<% %W(
  multipass
  teams-for-linux
  zoom-client
).compact_blank.each do |package| %>
  snap install "<%= package %>"
<% end %>
