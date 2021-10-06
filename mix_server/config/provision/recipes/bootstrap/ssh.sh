### References
# https://www.digitalocean.com/community/tutorials/how-to-harden-openssh-on-ubuntu-18-04
# https://www.sshaudit.com/
HOST_RSA="/etc/ssh/ssh_host_rsa_key"
HOST_ED25519="/etc/ssh/ssh_host_ed25519_key"

sun.backup_compile '/etc/ssh/sshd_config'

# Re-generate the RSA and ED25519 keys
rm /etc/ssh/ssh_host_*
<% if sun.ssh_host_rsa.present? %>
  touch "$HOST_RSA"
  chmod 600 "$HOST_RSA"
  echo -e '<%= sun.ssh_host_rsa.escape_newlines %>' > $HOST_RSA
  ssh-keygen -y -f $HOST_RSA > "$HOST_RSA.pub"
  chmod 644 "$HOST_RSA.pub"
<% else %>
  ssh-keygen -t rsa -b 4096 -f $HOST_RSA -N ""

  echo "$HOST_RSA should be kept in your settings.yml as :ssh_host_rsa"
  <%= Sh.escape_newlines "$HOST_RSA" %>
  echo ''
<% end %>
<% if sun.ssh_host_ed25519.present? %>
  touch "$HOST_ED25519"
  chmod 600 "$HOST_ED25519"
  echo -e '<%= sun.ssh_host_ed25519.escape_newlines %>' > $HOST_ED25519
  ssh-keygen -y -f $HOST_ED25519 > "$HOST_ED25519.pub"
  chmod 644 "$HOST_ED25519.pub"
<% else %>
  ssh-keygen -t ed25519 -f $HOST_ED25519 -N ""

  echo "$HOST_ED25519 should be kept in your settings.yml as :ssh_host_ed25519"
  <%= Sh.escape_newlines "$HOST_ED25519" %>
  echo ''
<% end %>

# Remove small Diffie-Hellman moduli
awk '$5 >= 3071' /etc/ssh/moduli | sudo tee /etc/ssh/moduli.safe > /dev/null
mv /etc/ssh/moduli.safe /etc/ssh/moduli

# Enable the RSA and ED25519 keys
sed -i 's/^\#HostKey \/etc\/ssh\/ssh_host_\(rsa\|ed25519\)_key$/HostKey \/etc\/ssh\/ssh_host_\1_key/g' /etc/ssh/sshd_config

# Restrict supported key exchange, cipher, and MAC algorithms
echo -e "\n# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\nKexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\nHostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com" | sudo tee /etc/ssh/sshd_config.d/ssh-audit_hardening.conf > /dev/null

mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh
<%= Sh.concat('$HOME/.ssh/authorized_keys', "$__OWNER_PUBLIC_KEY__ #{sun.env}", escape: false, unique: true) %>
chmod 600 $HOME/.ssh/authorized_keys
echo -e "$__OWNER_PRIVATE_KEY__" > $HOME/.ssh/id_rsa
chmod 600 $HOME/.ssh/id_rsa
chown -R $__OWNER_NAME__:$__OWNER_NAME__ $HOME/.ssh

if [[ "$__ENV__" == 'production' ]]; then
  <%= Sh.delete_line! '$HOME/.ssh/authorized_keys', 'staging', escape: false %>
fi

systemctl restart ssh
