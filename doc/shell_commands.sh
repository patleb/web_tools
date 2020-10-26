# consult concatenated logs in reverse order
zcat -f -- staging.log* | tac
