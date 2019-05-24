# TODO https://www.digitalocean.com/community/tutorials/how-to-create-an-intranet-with-openvpn-on-ubuntu-16-04

export LOCAL_NETWORK=$(sun.network $(sun.internal_ip) 16)/16
export SAMBA_DATA='/opt/samba_data'

sun.install "samba"
sun.install "samba-common"
sun.install "system-config-samba"
sun.install "smbclient"

sun.backup_compile '/etc/samba/smb.conf'

mkdir -p "$SAMBA_DATA"
chmod 0777 "$SAMBA_DATA"
chown nobody:nogroup "$SAMBA_DATA"

ufw allow samba
ufw reload

# testparm -v /etc/samba/smb.conf
systemctl enable smbd
systemctl restart smbd
