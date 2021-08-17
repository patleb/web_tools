### References
# https://www.digitalocean.com/community/tutorials/how-to-harden-openssh-on-ubuntu-18-04
# https://www.sshaudit.com/
sun.backup_compile '/etc/ssh/sshd_config'

# Re-generate the RSA and ED25519 keys
rm /etc/ssh/ssh_host_*
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

# Remove small Diffie-Hellman moduli
awk '$5 >= 3071' /etc/ssh/moduli | sudo tee /etc/ssh/moduli.safe > /dev/null
mv /etc/ssh/moduli.safe /etc/ssh/moduli

# Enable the RSA and ED25519 keys
sed -i 's/^\#HostKey \/etc\/ssh\/ssh_host_\(rsa\|ed25519\)_key$/HostKey \/etc\/ssh\/ssh_host_\1_key/g' /etc/ssh/sshd_config

# Restrict supported key exchange, cipher, and MAC algorithms
echo -e "\n# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\nKexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\nHostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com" | sudo tee /etc/ssh/sshd_config.d/ssh-audit_hardening.conf > /dev/null

mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh
<%= Sh.concat('$HOME/.ssh/authorized_keys', '$__OWNER_PUBLIC_KEY__', escape: false, unique: true) %>
chmod 600 $HOME/.ssh/authorized_keys
echo -e "$__OWNER_PRIVATE_KEY__" > $HOME/.ssh/id_rsa
chmod 600 $HOME/.ssh/id_rsa
chown -R $__OWNER_NAME__:$__OWNER_NAME__ $HOME/.ssh

systemctl restart ssh
