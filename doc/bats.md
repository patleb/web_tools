# Add Bats git submodules

git submodule add https://github.com/bats-core/bats-core.git vendor/bats-core/bats-core
git submodule add https://github.com/bats-core/bats-support.git vendor/bats-core/bats-support
git submodule add https://github.com/bats-core/bats-assert.git vendor/bats-core/bats-assert
git submodule add https://github.com/bats-core/bats-file.git vendor/bats-core/bats-file

# Remove git submodule

git rm --force vendor/bats-core/bats-core
git config --remove-section submodule.vendor/bats-core/bats-core
