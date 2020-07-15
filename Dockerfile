FROM ruby:2.7.1-buster

# Author MidnightsFX

# Update Packages & Install packages for ark-server-tools & ark
RUN apt-get update \
    && apt-get -y install curl lsof libc6-i386 lib32gcc1 bzip2 wget perl-modules

# Cleanup packages
RUN rm -rf /var/lib/apt/lists/* \
    && apt-get clean autoclean

# Install steamcmd
RUN useradd -m steam \
    && su steam -c \
        "mkdir home/steam/steamcmd \
        && cd home/steam/steamcmd \
        && curl 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar -vxz"

# Setting user back to root & Give permission to the steam user so it can write out files in the container
RUN usermod -aG sudo steam
USER root

WORKDIR /home/steam

# Install ARK server tools
RUN curl -sL http://git.io/vtf5N | bash -s steam

COPY global.cfg /etc/arkmanager/arkmanager.cfg
COPY main.cfg /etc/arkmanager/instances/main.cfg
COPY arkswarm/pkg/arkswarm-0.1.0.gem /gem/arkswarm-0.1.0.gem
# Since this is a local install the dependencies need to be already installed
RUN gem install thor
RUN gem install --local /gem/arkswarm-0.1.0.gem 

# Use a persistent volume for game data, setup, saves and backups
VOLUME /server/

# EXPOSE 7778:7778/udp 7778:7778 27015:27015/udp 27015:27015 32330:32330

WORKDIR /server
ENTRYPOINT ["arkswarm start"]