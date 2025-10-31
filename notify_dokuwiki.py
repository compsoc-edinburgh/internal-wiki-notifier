import feedparser
import requests

import os
import json
import sched
import time
import sys

from dotenv import load_dotenv

class Updates:
    schedule_sleep_seconds = 5 # how many seconds between updates
    last_update = None

# I basically directly translated the bash script that existed previously into python
# which is why it's structured like this. - Emily, 31/10/2025 
def run_script():
    print("Running script.")

    # Load authentication tokens
    load_dotenv()
    dokuwiki_token = os.environ.get("DOKUWIKI_AUTH_TOKEN")
    if not dokuwiki_token:
        raise Exception("No dokuwiki token given in .env file or environment variable DOKUWIKI_AUTH_TOKEN.")
    webhook_token = os.environ.get("DISCORD_WEBHOOK_TOKEN")
    if not webhook_token:
        raise Exception("No discord webhook token given in .env file or environment variable DISCORD_WEBHOOK_TOKEN.")
    webhook_id = os.environ.get("DISCORD_WEBHOOK_ID")
    if not webhook_id:
        raise Exception("No discord webhook token given in .env file or environment variable DISCORD_WEBHOOK_ID.")

    # Pull request from dokuwiki
    req = requests.get("https://wiki.internal.comp-soc.com/feed.php.xml", headers={"X-DokuWiki-Token": dokuwiki_token})
    req.raise_for_status()

    # Parse feed and get updates
    feed = feedparser.parse(req.content)
    titles = [entry.title for entry in feed.entries if not Updates.last_update or entry.updated_parsed > Updates.last_update]

    # Generate message to send
    title = "Wiki Updates"
    message = "\n".join(titles)

    # Send via webhook
    req = requests.post(f"https://discord.com/api/webhooks/{webhook_id}/{webhook_token}", 
                        headers={"Content-Type": "application/json"},
                        data=json.dumps({
                            "username": "CompSoc Internal Wiki Updates",
                            "avatar_url": "https://d7umqicpi7263.cloudfront.net/img/product/270b2d4d-7902-4fbf-b245-b6ea862ceea8/d2fde27f-c059-4140-8f13-ce17827af33c.PNG",
                            "embeds": [{
                                "title": title, 
                                 "type": "rich", 
                                 "description": message, 
                                 "color": 2697569
                            }]
                        }))
    req.raise_for_status()
    
    # Update last_update
    Updates.last_update = time.gmtime()

    print("Script finish running successfully!")

def scheduler_run(scheduler):
    scheduler.enter(Updates.schedule_sleep_seconds, 1, scheduler_run, (scheduler,))
    try:
        run_script()
    except Exception as e:
        print(f"Caught Exception: {e}")

def start_scheduler():
    print("Starting scheduler...")
    scheduler = sched.scheduler(time.time, time.sleep)
    scheduler.enter(Updates.schedule_sleep_seconds, 0, scheduler_run, (scheduler,))
    scheduler.run()

def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "run-once":
        run_script()
    elif len(sys.argv) == 1:
        start_scheduler()
    else:
        print(f"Bad arguments.\nUsage: python3 {sys.argv[0]} [run-once]")


if __name__ == '__main__':
    main()
