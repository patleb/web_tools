rake() {
  if [[ $1 =~ ^(assets|shakapacker): ]]; then
    bin/rake $@
  else
    PACK=false bin/rake $@
  fi
}
