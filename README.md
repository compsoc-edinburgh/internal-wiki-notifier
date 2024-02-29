# Internal Wiki Notifier

A service (read: a bash script) that runs in a Docker container and notifies
a select Discord channel using webhooks of any updates to the Internal CompSoc
Wiki.

Deployed automatically through GitHub CI and Watchtower. The CompSoc TechSec
will have SSH access to the deployment VM to configure webhook URLs and API keys
(for Wiki.js) through environment variables.

## First Time Setup

For new local copies (e.g. new TechSec), clone this repository, and run
`make initialise`. As a prerequisite, this will require you to have SSH access
configured in `~/.ssh/config` for `root@deployment-host.comp-soc.com`. The
initialisisation will download any production keys to your computer if the
service is already deployed and running.

For new remote setups, after running the above initialisation, create a new
local `.secrets/.env` directory if it does not exist yet, and specify the
arguments to pass to the Docker container.

## Continuous Development

Commit any changes to the code to Git and push to GitHub to trigger an automatic
Docker image build. This will then trigger Watchtower to re-download the latest
image and re-deploy the production instance. This is all you need to update a
deployment's code.

However, to update a deployment's environment variables (i.e. those in .secretes),
you will need to manually sync them over via SSH because they are *secrets*!
Not meant to be publicly embedded in Docker images.

There is a helper script within the makefile, so after any local changes to the
secrets (either after first creation or edits), run `make restart` which will
stop remote services if any are running, sync the secrets, and start the service.
