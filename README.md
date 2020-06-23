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
        - /servers/cluster_ark/mods:/home/steam/Steam/steamapps/workshop
        - /servers/cluster_ark/config:/config
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

- Volumes: (three entrys explained by example)
    - ``` /servers/cluster_ark/ARK_Valguero:/server ``` This is where your actual ark install lives, the first half of this path is your local-machine (and can be wherever you want), the second part `/server` is required.
    - ``` /servers/cluster_ark/mods:/home/steam/Steam/steamapps/workshop ``` This is wwhere steam will download mods (seperate from installing them). This is an optional mount, but will massively spead up startup when changing docker images
    - ``` /servers/cluster_ark/config:/config ``` configurations that will be merged into ARKs configs, this can include custom mod configurations, complete (or partial) ark configs
- Environment: 
    - serverMap: this can be any of the official (or not) maps, but it should be set
    - ark_SessionName: while not required, highly suggested you set your session name so you can distinquish multiple instances.
    - ark_Port: must match the port you are exposing (7778:7778/udp & 7778:7778/tcp) are normal defaults.
    - ark_QueryPort: this is the steam query protocol port, used for game discovery etc, this also needs to match its exposed port (27015:27015/tcp)
    - ark_RCONPort: while this is not technically required, if you wish to perform administrative actions on your server it is highly recommended you expose RCON or setup your secret admin password (default 32330:32330/tcp).
- Ports: As mentioned above, all of the ports you run the game on inside of the container need to be exposed and matching. If you are running multiple instances of the game (cluster mode) these ports will need to be unique and not overlap for each server.

If you are planning on using a paid DLC you will need a (seperate from your client) steam account with ARK, and the DLC required. This account will need to have steamguard disabled, and have a password which does not contain special characters (sorry this seems to be an issue with how the steamCMD accepts inline passwords).

Add the following lines to your environment variables (or pass them in at runtime so they don't need to be written down!)
```
steam_user: example
steam_pass: fakePass
```


## Configuration Options:

There are two different configuration options provided.

1. Loose configuration provided by the volume mount ```/your_configs_live_here:/configs``` This is the preferred configuration method as you can provide multiple configuration files with piecemeal configuration, for mods, or repeat values (like overriding recipes etc).
2. ENV variable passing. There is a rather lengthy system defined below which allows passing configuration for most things to the ARK environment (mod configuration and repeat values are not supported).

## Loose Configuration files mounted by Volume

This is the preferred way of providing configuration and gives you a great deal of configuration choices.

The basis of this is that you will need to mount a volume for the supervisor container at `/configs`, everything under this directory (recursively) will be inspected and considered for configuration ingest. This means you can provide partial configurations for many different aspects of ARK here.

EG:
```
/servers/ARK/configs/
                    - openstructures_configs.ini
                    - recipe_overrides.ini
                    - player_xp_settings.ini
                    - stat_scaling.ini
```

When mounting the above directory to /configs eg: ``` /servers/ARK/configs/:/configs ``` all of these files will be read and added to your ARK configuration.

### Config File Format

There are a options to ensure these configs are ingested in the way you would like.

1. Rely on the auto-sorter
There is a config matcher which will look for `[/Script/ShooterGame.ShooterGameMode]` as a header in the config file, if it does not find this it will place the configuration in `gameUserSettings.ini`
This can be overwritten with the use of a moniker, detailed below. Either way, your config file must make use of section headers to be ingested in a useful way.

```
[/Script/ShooterGame.ShooterGameMode]
ResolutionSizeX=2560
ResolutionSizeY=1080
...
```

2. Specify a moniker
EG: 
```
#!gameuser
[ServerSettings]
ListenServerTetherDistanceMultiplier=1.000000
RaidDinoCharacterFoodDrainMultiplier=1.000000
```
Setting the first line to `#!gameuser` or `#!game` will ensure that the files configs are merged into the correct file.




## ENV Variable Passing Configuration:

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
these values will be passed to the GameUserSettings.ini file on startup and will override values they match. This file will be generated each time at startup; using existing values, updating existing values with provided configuration and setting any values which are not found, but have been provided as environment variables.

```
gameuser_*="value"
eg:
gameuser_ShowMapPlayerLocation=True
```