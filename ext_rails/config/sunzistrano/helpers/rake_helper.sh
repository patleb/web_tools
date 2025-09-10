rake() {
  if [[ $1 =~ ^(assets|shakapacker): ]]; then
    if [[ -v BASH_OUTPUT && "$BASH_OUTPUT" != false ]]; then
      RAKE_OUTPUT=true bin/rake $@
    else
      bin/rake $@
    fi
  else
    if [[ -v BASH_OUTPUT && "$BASH_OUTPUT" != false ]]; then
      PACK=false RAKE_OUTPUT=true bin/rake $@
    else
      PACK=false bin/rake $@
    fi
  fi
}
