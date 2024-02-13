FROM hashicraft/minecraft:v1.20.1-fabric

# Add nodejs
RUN apt-get update && apt-get install -y \
  gnupg

RUN mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
  apt-get update && \
  apt-get install nodejs \
    ca-certificates \
	  p11-kit \
		gnupg -y

# Copy and install the bot
COPY ./bot /bot
RUN cd /bot && npm install

# Add the config
COPY ./Entrypoint.sh /Entrypoint.sh
ENTRYPOINT ["/bin/bash", "/Entrypoint.sh"]