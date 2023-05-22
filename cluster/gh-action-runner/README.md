## provision gh action runner template and VM on ovirt

### create gh-action oVirt template based on fedora
```
source utils.sh
gh_action_template_create [-t cleanup]
```

### create gh-action VM from oVirt template
```
source utils.sh
gh_action_runner_create [-t cleanup]
```

### Register the runner VM in Github Repository
```
source utils.sh
gh_action_register_runner [-t cleanup]
```