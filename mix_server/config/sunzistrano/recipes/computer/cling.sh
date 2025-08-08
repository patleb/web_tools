sun.add_repo "ppa:ppa-verse/cling"
sun.update

sun.install "cling"
sun.install "seergdb"

echo 'set history save on' >> $HOME/.gdbinit
echo 'set history size unlimited' >>  $HOME/.gdbinit
echo 'set history remove-duplicates unlimited' >> $HOME/.gdbinit
echo -e "define c\n  continue\n  refresh\nend" >> $HOME/.gdbinit
echo -e "define n\n  next\n  refresh\nend" >> $HOME/.gdbinit
