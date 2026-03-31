# Multipass

## Up

Create a new VM or start a pre-existing one:
```shell
sun up
```

Default resources used without clustering are:
- Cores: 4
- RAM: 6GB
- Disk: 12GB

If you wish to use different resources and/or add clustering, you must change the settings for the `virtual` environment in your `config/sunzistrano.yml`, before creation, like so:

```yaml
virtual:
  vm_cpu: 2
  vm_ram: 2GB
  vm_disk: 8GB
  vm_clusters: 4
```

Note: there's no support for specific resources for each VM, they all share the same specifications.

## Halt

Shutdown the VM:
```shell
sun halt
```

## Destroy

Destroy the VM and free the resources:
```shell
sun destroy
```

## Status

Show the VM status and additional informations:
```shell
sun status
```

## SSH

Shell into the VM through a ssh connexion with:
```shell
sun ssh
```

Execute a command only:
```shell
sun ssh -c 'echo Hello World!'
```

## Snapshot

### Save

Create a snapshot of the VM at the current state:
```shell
sun snapshot save --name completed-step
```

### Restore

Restore the VM state to a specific snapshot:
```shell
sun snapshot restore --name completed-step
```

### List

List all the snapshots:
```shell
sun snapshot list
```

### Delete

Delete a specific snapshot:
```shell
sun snapshot delete --name completed-step
```
