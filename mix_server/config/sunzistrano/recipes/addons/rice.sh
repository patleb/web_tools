sun.install "ccache"
sun.install "cmake"
sun.install "gfortran"
sun.install "libtbb-dev"
sun.install "libopenblas-dev"
sun.install "liblapacke-dev"
sun.install "gdb"
sun.install "valgrind"

echo 'set history save on' >> $HOME/.gdbinit
echo 'set history size unlimited' >>  $HOME/.gdbinit
echo 'set history remove-duplicates unlimited' >> $HOME/.gdbinit
echo -e "define c\n  continue\n  refresh\nend" >> $HOME/.gdbinit
echo -e "define n\n  next\n  refresh\nend" >> $HOME/.gdbinit
