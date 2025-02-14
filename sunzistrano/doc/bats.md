# Add Bats git submodules

```shell
git submodule add https://github.com/bats-core/bats-core.git vendor/bats-core/bats-core
git submodule add https://github.com/bats-core/bats-support.git vendor/bats-core/bats-support
git submodule add https://github.com/bats-core/bats-assert.git vendor/bats-core/bats-assert
git submodule add https://github.com/bats-core/bats-file.git vendor/bats-core/bats-file
```

# Remove git submodule

```shell
git rm --force vendor/bats-core/bats-core
git config --remove-section submodule.vendor/bats-core/bats-core
```

# Update git submodules

```shell
`git submodule update --remote`
```

# Clone git submodules

```shell
git clone --recurse-submodules <path>
```

or if already cloned

```shell
git submodule update --init --recursive
```
