git_ssh_src="$(sun.template_path /tmp/git_ssh.sh)"
git_ssh_dst=/tmp/git_ssh-$(openssl rand -hex 10).sh
cp $git_ssh_src $git_ssh_dst
chmod 700 $git_ssh_dst
export GIT_SSH=$git_ssh_dst
export GIT_ASKPASS=/bin/echo
