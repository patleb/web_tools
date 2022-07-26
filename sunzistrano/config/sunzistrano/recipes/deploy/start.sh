desc 'Check that the repository is reachable'
git config --global url."https://github.com/".insteadOf git@github.com:
git config --global url."https://".insteadOf git://
git ls-remote ${repo_url} HEAD

desc 'Check shared and release directories exist'
mkdir -p "$shared_path" "$releases_path"
