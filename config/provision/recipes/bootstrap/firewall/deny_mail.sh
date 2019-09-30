ufw deny out smtp   # 25/tcp
ufw deny out urd    # 465/tcp
# ufw deny out pop2   # 109/tcp, 109/udp
ufw deny out pop3   # 110/tcp, 110/udp
ufw deny out pop3s  # 995/tcp, 995/udp
ufw deny out imap2  # 143/tcp, 143/udp
# ufw deny out imap3  # 220/tcp, 220/udp
ufw deny out imaps  # 993/tcp, 993/udp
ufw reload
