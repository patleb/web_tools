### References
# https://www.digitalocean.com/community/tutorials/how-to-harden-openssh-on-ubuntu-20-04
# https://www.sshaudit.com/hardening_guides.html#ubuntu_24_04_lts
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
echo -e "\nHostKey /etc/ssh/ssh_host_ed25519_key\nHostKey /etc/ssh/ssh_host_rsa_key" | sudo tee -a /etc/ssh/sshd_config > /dev/null

# Restrict supported key exchange, cipher, and MAC algorithms
echo -e "# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\nKexAlgorithms sntrup761x25519-sha512@openssh.com,gss-curve25519-sha256-,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256,gss-group16-sha512-,diffie-hellman-group16-sha512\n\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-gcm@openssh.com,aes128-ctr\n\nMACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com\n\nRequiredRSASize 3072\n\nHostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nCASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nGSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-\n\nHostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nPubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256" | sudo tee /etc/ssh/sshd_config.d/ssh-audit_hardening.conf > /dev/null

mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh
<%= Sh.concat('$HOME/.ssh/authorized_keys', "${owner_public_key} #{sun.env}", escape: false, unique: true) %>
chmod 600 $HOME/.ssh/authorized_keys
echo -e "${owner_private_key}" > $HOME/.ssh/id_rsa
chmod 600 $HOME/.ssh/id_rsa
chown -R ${owner_name}:${owner_name} $HOME/.ssh

if [[ "${env}" == 'production' ]]; then
  <%= Sh.delete_line! '$HOME/.ssh/authorized_keys', 'staging', escape: false %>
fi

systemctl restart ssh
