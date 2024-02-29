# Internal Wiki Notifier

A service (read: a bash script) that runs in a Docker container and notifies
a select Discord channel using webhooks of any updates to the Internal CompSoc
Wiki.

Deployed automatically through GitHub CI and Watchtower. The CompSoc TechSec
will have SSH access to the deployment VM to configure webhook URLs and API keys
(for Wiki.js) through environment variables.

## First Time Setup

For new local copies (e.g. new TechSec after a handover), clone this repository,
and run `make initialise`. As a prerequisite, this will require you to have SSH
access configured in `~/.ssh/config` for `root@deployment-host.comp-soc.com`.
The initialisisation will download any production keys to your computer if the
service is already deployed and running. After this, edit as you like locally
and follow steps in the Continuous Development section.

For new remote setups (e.g. deploying to a new VM or under a different service
name), run the above initialisation step first. Then, create a new local
`.secrets/.env` file if it does not exist yet, and specify the environment keys
to pass to the Docker container. Then run `make sync-secrets` and `make restart`.
Then follow the steps in Continus Development.

## Continuous Development

During development, commit any changes to the code to Git and push to GitHub to
trigger an automatic Docker image build and a notification to Watchtower on the
production to VM. If there was a previous production instance, Watchtower will
re-download the latest image and re-deploy with the latest image. This is all
you need to update a deployment's code.

However, to update a deployment's environment variables (i.e. those in .secrets),
you will need to manually sync them over via SSH because they are *secrets*!
Not meant to be publicly embedded in Docker image builds.

There is a helper script within the makefile, so after any local changes to the
secrets, run `make restart` to stop remote services if any are running, sync the
secrets, and start the service.

## Logs

To view production logs (prerequisite: SSH access), use `make logs` or `make tail`.
