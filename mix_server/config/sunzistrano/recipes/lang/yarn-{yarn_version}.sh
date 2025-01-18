sun.update
sun.install "npm"

echo "nodejs $(nodejs --version)"

npm install -g corepack
corepack enable

sudo su - deployer << 'EOF'
  set -eu
  yarn_version=<%= sun.yarn_version || 'stable' %>

  yes | yarn set version $yarn_version
  echo "yarn $(yarn --version)"
EOF
