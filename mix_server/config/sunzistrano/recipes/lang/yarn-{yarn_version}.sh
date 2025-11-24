sun.update
sun.install "npm"

echo "nodejs $(nodejs --version)"

# https://github.com/bodadotsh/npm-security-best-practices?tab=readme-ov-file#3-disable-lifecycle-scripts
npm config set ignore-scripts true --global

npm install -g n
n lts

echo "node $(node --version)"

npm install -g corepack
corepack enable

sudo su - ${deployer_name} << 'EOF'
  set -eu
  yarn_version=<%= sun.yarn_version || 'stable' %>

  yes | yarn set version $yarn_version
  echo "yarn $(yarn --version)"
EOF
