# Sunzistrano

Sunzistrano is a rewrite of [Sunzi](https://github.com/kenn/sunzi), a provisioning tool enabling infrastructure as code.

## Usage

Infrastructure code is organized through **roles** defining which **recipes** are run as Bash files.

Each Bash file can be embedded with Ruby using the [ERB](https://puppet.com/docs/puppet/7/lang_template_erb.html) syntax.

### Provision

```sh
  # 'vagrant' stage with default options
  sun provision vagrant

  # 'vagrant' stage and 'app_name' application
  sun provision vagrant:app_name

  # 'custom' role specified (default is 'system')
  sun provision vagrant custom

  # run only one recipe
  sun provision vagrant --recipe=lang/ruby/app-{rbenv_ruby}

  # reset ssh known hosts afterward
  sun provision vagrant --new-host

  # skip the 'reboot' recipe
  sun provision vagrant --no-reboot
```

See [cli.rb](./lib/sunzistrano/cli.rb) for more commands.

## Configuration

The configuration file is a YAML file located at `config/provision.yml` and is integrated with **[capistrano](../ext_capistrano/README.md)** and **[mix_setting](../mix_setting/README.md)** to reuse their configuration files as well.

Configurations are accessible in Bash through global variables with the following convention:

**uppercased variable name with 2 leading and 2 trailing underscores**

```yaml
# config/provision.yml
...
system:
  swap_size: 1G
  owner_name: ubuntu
  ...
```

```bash
# Bash file
...
${swap_size}
${owner_name}
```

It's important to note that collections (array or hash), empty strings, null values, discontinuous strings or ERB strings aren't accessible through global variables.

Otherwise, the whole Sunzistrano context is accessible through the `sun` accessor which exposes all the configurations and some contextual Ruby helpers:

```bash
VAR_NAME=<%= sun.var_name %>
```

The `provision.yml` file follows the same application and environment scoping conventions as `config/settings.yml` from **mix_setting**, but with an additional role scope.

```yaml
# all available scopes
shared:
  ...
system: # role
  ...
vagrant: # stage (environment)
  ...
vagrant_system:
  ...
app_name: # application
  ...
app_name_system:
  ...
app_name_vagrant:
  ...
app_name_vagrant_system:
  ...
```

See [provision.yml](../config/provision.yml) for an example.

## Roles

Each **role** is a Bash file located under the folder `config/provision/roles` and is meant to source the **recipes**.

### Role Helper

The `sun.role_recipes` Ruby helper adds some essential functionalities to the role:

- CLI option for running only one recipe;
- CLI option for skipping the `reboot` recipe;
- keeping the `reboot` recipe at the end of the list of recipes;
- appending/removing recipes through `config/provision.yml` with `append_recipes` and `remove_recipes` configurations;
- outputing the recipe names including variables with the actual values;

See [system.sh](../mix_server/config/provision/roles/system.sh) for an example.

### Role Hooks

Role hooks are Bash files located under the folder `config/provision/roles` with the following file names for system role:

 - `system_before.sh` is run before the recipes
 - `system_after.sh` is run after all the recipes ran successfully
 - `system_ensure.sh` is run before the program exits

## Recipes

Each **recipe** is a Bash file located under the folder `config/provision/recipes` and runs only once if it completed with success.

The recipe name is the file path in the recipes folder without the extension (.sh) and thus unique, but can include a variable in its name to make it evolve through time or different versions with the following convention:

**uppercased variable name with 2 leading and 2 trailing underscores**

For example, the recipe `config/provision/recipes/lang/ruby/app-{rbenv_ruby}.sh` with the configuration

```yaml
# config/provision.yml
...
shared:
  rbenv_ruby: 2.7.6
  ...
```

Would be sourced in the compiled role file as:

```bash
# config/roles/system.sh
...
sun.source_recipe "lang/ruby/app-{rbenv_ruby}" 'lang/ruby/app-2.7.6'
...
```

See [mix_server/config/provision/recipes](https://github1s.com/patleb/web_tools/tree/master/mix_server/config/provision/recipes) for more examples.

### Recipe Helpers

The `sun.source_recipe` Bash helper must be used to source the **recipe** and make sure that it runs only once. It's also required for more advanced features like the **specialize** and **rollback** commands.

## Files

Transferred **files** are located under the folder `config/provision/files` and must follow the actual location of the remote machine. For example, if the file `/etc/hosts` is expected to be replaced, then the file path would be `config/provision/files/etc/hosts`.

### File helpers

Some Bash **helpers** are available to ease/extend the usage/manipulation of transferred **files**. Some of the functionalities available are:

- ESH templating;
- Original file backup;
- Comparison between an expected file and the original file;
- Multi OS support;

See [template_helper.sh](./config/provision/helpers/sun/template_helper.sh) for more details.

## Helpers

Added Bash **helpers** are located under the folder `config/provision/helpers`.
