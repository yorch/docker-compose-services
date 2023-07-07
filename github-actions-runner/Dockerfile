# Originally from: https://testdriven.io/blog/github-actions-docker/
FROM ubuntu:22.04

# Set the github runner version
ARG RUNNER_VERSION="2.305.0"

# Update the base packages and add a non-sudo user
RUN apt-get update -y \
  && apt-get upgrade -y \
  && useradd -m docker

# Install python and the packages the your code depends on along with jq so we can parse JSON
# add additional packages as necessary
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  curl \
  jq \
  build-essential \
  libssl-dev \
  libffi-dev \
  python3 \
  python3-venv \
  python3-dev \
  python3-pip

ENV GHA_URL=https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/docker \
  && mkdir actions-runner \
  && cd actions-runner \
  && curl -o actions-runner-linux.tar.gz -L -s ${GHA_URL} \
  && tar xzf ./actions-runner-linux.tar.gz \
  && rm actions-runner-linux.tar.gz

# Install some additional dependencies
RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

# Copy over the start.sh script
COPY docker/start.sh start.sh

# Make the script executable
RUN chmod +x start.sh

# Since the config and run script for actions are not allowed to be run by root,
# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# Set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
