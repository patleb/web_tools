set +u
if [[ ! -z "$GIT_SSH" ]]; then
  if [[ $GIT_SSH == "/tmp/git_ssh-*" ]]; then
    rm -f $GIT_SSH
  fi
fi
set -u
