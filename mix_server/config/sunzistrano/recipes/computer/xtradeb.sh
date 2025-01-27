sun.add_repo "ppa:xtradeb/apps"
sun.update

sun.copy "/etc/apt/preferences.d/xtradeb.pref" 0644 root:root
