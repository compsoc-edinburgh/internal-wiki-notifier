FROM alpine

# Copy script which should be run
COPY ./notify-wikijs-recent-updates.sh /usr/local/bin/notify-wikijs-recent-updates.sh
RUN chmod +x /usr/local/bin/notify-wikijs-recent-updates.sh

# Install curl and jq
RUN apk add --no-cache curl jq

# Run the cron every 5 minutes
RUN echo '*/5  *  *  *  *    /usr/local/bin/notify-wikijs-recent-updates.sh' > /etc/crontabs/root

# Run the cron with log level 2, and in foreground so it doesn't exit immediately
CMD ["crond", "-l2", "-f"]
