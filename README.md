# ARKSwarm
ARK Swarm is a docker deployed ARK: Survival Evolved maintained server. The goal of this is to provide a self-updating easily configured ark-server which can be clustered as neeeded with shared configurations.

Most of these features are provided by the excellent tooling of [Ark Server Tools](https://github.com/FezVrasta/ark-server-tools). However, most of the configuration and usage of that is abstracted in this implementation.

Current features:
- Automatic updates, server will check for ark updates on a regular interval and when it finds one, will wait until the server is empty and stop, update and start back up (this applies to mods too)
- Automatic installation of mods, no longer do you need to copy windows files to your linux server to install new mods or update existing ones.
- Sharable configuration, configuration files for ark are generated from variables provided to the container. Meaning you can have multiple servers running with the same shared values easily.

Planned features:
- Proper local clustering support, currently you can run multiple servers, but automatic cluster connectivity and configuration is not handled yet.


## How to setup

The provided docker-compose should give you a reasonable idea of what is required in order to setup this dockerized ARK server.

There are a couple pieces which are required:

```
image: midnightsfx/arkswarm:v0.2.26
    volumes:
        - /servers/cluster_ark/ARK_Valguero:/server
    environment:
      serverMap: "Valguero_P" # required
      ark_SessionName: "ARK-Server"
      ark_Port: 7778
      ark_QueryPort: 27015
      ark_RCONPort: 32330
    ports:
        - 7778:7778/udp
        - 7778:7778
        - 27015:27015/udp
        - 27015:27015
        - 32330:32330
```

- Volumes: this is where the actual arkserver gamefiles will live on your docker host machine.
- Environment: 
    - serverMap: this can be any of the official (or not) maps, but it should be set
    - ark_SessionName: while not required, highly suggested you set your session name so you can distinquish multiple instances.
    - ark_Port: must match the port you are exposing (7778:7778/udp & 7778:7778/tcp) are normal defaults.
    - ark_QueryPort: this is the steam query protocol port, used for game discovery etc, this also needs to match its exposed port (27015:27015/tcp)
    - ark_RCONPort: while this is not technically required, if you wish to perform administrative actions on your server it is highly recommended you expose RCON or setup your secret admin password (default 32330:32330/tcp).
- Ports: As mentioned above, all of the ports you run the game on inside of the container need to be exposed and matching. If you are running multiple instances of the game (cluster mode) these ports will need to be unique and not overlap for each server.


## Configuration Options:

All of these configuration options are passed in as environment variables. It is highly recommended to pass these environment variables that are shared between servers as a single .env file in the docker-compose setup or in the kubernetes deployment.

---
### arkflag_ 
these values are command-line flags which will be passed to the game at startup
```
arkflag_*="true/false"
eg:  
arkflag_NoBattlEye: "true"
```
---
### arkgame_
these values will be passed to the Game.ini file on startup and will be used to generate its configuration (any existing hand edits will be overriten)
```
arkgame_*="value"
eg: 
arkgame_PerLevelStatsMultiplier_Player[0]=1.5
arkgame_bPvEDisableFriendlyFire=True
```
---
### gameuser_
these values will be passed to the GameUserSettings.ini file on startup and will override values they match (or be added to the [ServerSettings] section) this file will be generated each time at startup, using existing values and updating/setting any values which are found

```
gameuser_*="value"
eg:
gameuser_ShowMapPlayerLocation=True
```