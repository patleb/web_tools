sun.add_repo "ppa:ppa-verse/cling"
sun.update

sun.install "cling"

echo 'set history save on' >> $HOME/.gdbinit
echo 'set history size unlimited' >>  $HOME/.gdbinit
echo 'set history remove-duplicates unlimited' >> $HOME/.gdbinit
