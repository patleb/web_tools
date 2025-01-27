echo 'GRUB_TIMEOUT=1' | sudo tee -a /etc/default/grub
echo 'GRUB_RECORDFAIL_TIMEOUT="$GRUB_TIMEOUT"' | sudo tee -a /etc/default/grub
sudo update-grub
