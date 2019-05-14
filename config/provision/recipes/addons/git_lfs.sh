curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sun.update

sun.install "git-lfs"

git lfs install
