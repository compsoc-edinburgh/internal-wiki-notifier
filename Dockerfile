FROM alpine

# Create directory for the working directory slash cache
RUN mkdir -p /etc/internal-wiki-notifier
# Copy script which should be run
COPY ./notify-wikijs-recent-updates.sh /usr/local/bin/notify-wikijs-recent-updates.sh
RUN chmod +x /usr/local/bin/notify-wikijs-recent-updates.sh

# Install curl and jq
RUN apk add --no-cache curl jq

WORKDIR /etc/internal-wiki-notifier

# Run the cron every 5 minutes
RUN echo '*/5  *  *  *  *    cd /etc/internal-wiki-notifier && /usr/local/bin/notify-wikijs-recent-updates.sh' > /etc/crontabs/root

# Run the cron with log level 2, and in foreground so it doesn't exit immediately
CMD ["crond", "-l2", "-f"]
