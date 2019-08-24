# ARKSwarm
ARK Swarm is a docker deployed ARK: Survival Evolved maintained server.


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


Configuration Options:
