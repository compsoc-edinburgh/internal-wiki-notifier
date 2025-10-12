# Internal Wiki Notifier

A service (read: a bash script) that runs in a container and notifies
a select Discord channel using webhooks of any updates to the Internal CompSoc
Wiki.

The CompSoc TechSec will have SSH access to the k8s cluster to configure webhook URLs and API keys
(for Wiki.js) through environment variables.

## Infrastructure

This is ran on the CompSoc k8s cluster. Updating this repository will automatically build a new container and upload them to ghcr. You can then use `kubectl rollout restart deployment internal-wiki-notifier` to reload the container.

See [the k8s repo](https://github.com/compsoc-edinburgh/CompSoc-k8s/tree/master/services/internal-wiki-notifier) for information about secrets management.
