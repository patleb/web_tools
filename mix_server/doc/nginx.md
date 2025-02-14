# Add Nginx configs subtree

```shell
git stash --include-untracked
git remote add -t main -f nginx_configs https://github.com/h5bp/server-configs-nginx.git
git subtree add --prefix mix_server/vendor/server-configs-nginx nginx_configs main --squash --debug
git stash pop
```

# Remove git subtree

```shell
git rm -rf mix_server/vendor/server-configs-nginx
rm -rf mix_server/vendor/server-configs-nginx
git remote remove nginx_configs
```

# Update git subtree

```shell
git fetch nginx_configs main
git subtree pull --prefix mix_server/vendor/server-configs-nginx nginx_configs main --squash
```
