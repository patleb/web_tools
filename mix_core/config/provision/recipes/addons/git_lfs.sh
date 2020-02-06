curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
sun.update

sun.install "git-lfs"

git lfs install
