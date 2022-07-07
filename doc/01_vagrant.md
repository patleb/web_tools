# Vagrant

## Base box

Make sure that your `Vagrantfile` has `config.vm.box = 'bento/ubuntu-20.04'`. Then:

    $ vagrant up

Provision the base box with:

    $ sun provision vagrant

Then keep that base box with:

    $ vagrant package --base web_tools --output web-tools-v0.box

Add this new box to your boxes with:

    $ vagrant box add web_tools file://web-tools-v0.box

Then you can delete or save elsewhere the generated box
and set your `Vagrantfile` box to `config.vm.box = 'web_tools'`.

Afterward, to use this box exclusively from now on et free up some space, execute:

    $ vagrant destroy -f && vagrant up

Then prepare the first snapshot:

    $ sun provision vagrant
    $ cap vagrant provision
    $ vagrant snapshot save provision
