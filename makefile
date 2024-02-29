include .env

REMOTE=root@deployment-host.comp-soc.com

# .SILENT:

# Get the latest logs in real time, without any previous logs (i.e. only newer ones)
tail:
	ssh ${REMOTE} 'docker logs -f --tail 0 service-${SERVICE_NAME}'

# Get all logs
logs:
	ssh ${REMOTE} 'docker logs service-${SERVICE_NAME}'

# Synchronise Discord bot tokens
sync-secrets:
	rsync -r ./.secrets/ ${REMOTE}:/secrets/service-${SERVICE_NAME}

# After cloning this repo locally, you can run this to set up the .secrets
# directory both locally and remotely. Harmless even if run multiple times.
initialise:
	mkdir -p .secrets
	ssh ${REMOTE} "mkdir -p /secrets/service-${SERVICE_NAME}"
	rsync -r ${REMOTE}:/secrets/service-${SERVICE_NAME}/ ./.secrets/

# Start the Docker container on the remote. This is needed to refresh secret
# .env files after a sync-secrets -- for this reason, it's recommended to use
# the restart target instead, which covers it.
start:
	ssh ${REMOTE} 'docker run -d --name service-${SERVICE_NAME} \
		--network traefik-net \
		--label "traefik.enable=true" \
		--env-file /secrets/service-${SERVICE_NAME}/.env \
		--label "com.centurylinklabs.watchtower.enable=true" \
		ghcr.io/compsoc-edinburgh/service-${SERVICE_NAME}'

# Most used command, restarts the service after syncing secrets (i.e. new
# Discord bot tokens). Can be run even if this is the first time you're
# deploying the service.
restart: teardown sync-secrets start

# Stop and remove the Docker container on the remote. The || true is to ignore
# errors if the container doesn't exist, without supressing SSH errors or
# exiting the make command.
teardown:
	ssh ${REMOTE} 'docker stop service-${SERVICE_NAME} || true'
	ssh ${REMOTE} 'docker rm service-${SERVICE_NAME} || true'
