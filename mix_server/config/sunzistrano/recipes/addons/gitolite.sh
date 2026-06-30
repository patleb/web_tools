sun.install "gitolite3"

echo "${gitolite_key}" > /tmp/admin.pub
useradd --system --home /home/git --create-home git
sudo -i -u git gitolite setup -pk /tmp/admin.pub

sed -i '/^AllowUsers / {/ git *$/! s/$/ git/}' /etc/ssh/sshd_config
systemctl restart ssh
