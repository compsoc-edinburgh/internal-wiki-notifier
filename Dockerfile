FROM python:3.12@sha256:72e5baf244fb1a9ddc985800340b48c2a0c72fdc9479e95d0f39987284f9f1cd

# Create directory for the working directory slash cache
RUN mkdir -p /etc/internal-wiki-notifier
WORKDIR /etc/internal-wiki-notifier

# Copy script and requirements
COPY ./notify_dokuwiki.py ./requirements.txt .

# Install python dependencies
RUN pip install -r requirements.txt

# Python script should do scheduling for us
CMD ["python3", "notify_dokuwiki.py"]
