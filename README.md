# Docker image for GUI apps

This image provides an Ubuntu environment useful for launching X11 GUI applications.
This image is based on [rubensa/ubuntu-dev](https://github.com/rubensa/docker-ubuntu-dev).

There is a /software directory where you can downaload and install software.

## Running

build
```
#!/usr/bin/env bash
docker build --no-cache \
  -t "rubensa/desktop" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .
```

run

```
#!/usr/bin/env bash

USER_UID=$(id -u)
USER_GID=$(id -g)

prepare_docker_caps_parameters() {
  # Allow SUID sandbox in container
  CAPABILITIES+=" --cap-add=SYS_ADMIN"
}

prepare_docker_security_parameters() {
  # Start a container without an AppArmor profile
  SECURITY+=" --security-opt apparmor:unconfined"
}

prepare_docker_device_parameters() {
  # Allow webcam access
  for device in /dev/video*
  do
    if [[ -c $device ]]; then
      DEVICES+=" --device $device"
    fi
  done
  # GPU support (Direct Rendering Manager)
  [ -d /dev/dri ] && DEVICES+=" --device /dev/dri"
  # Sound device (Advanced Linux Sound Architecture)
  [ -d /dev/snd ] && DEVICES+=" --device /dev/snd"
}

prepare_docker_env_parameters() {
  # X11 Unix-domain socket
  ENV_VARS+=" --env=DISPLAY=unix${DISPLAY}"
  # Credentials in cookies used by xauth for authentication of X sessions
  ENV_VARS+=" --env=XAUTHORITY=/tmp/.Xauthority"
  # https://github.com/TheBiggerGuy/docker-pulseaudio-example/issues/1
  ENV_VARS+=" --env=PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native"
  # DBus unix socket
  ENV_VARS+=" --env=DBUS_SESSION_BUS_ADDRESS=unix:path=${XDG_RUNTIME_DIR}/bus"
  # XDG_RUNTIME_DIR
  ENV_VARS+=" --env=XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}"
  # CUPS (https://github.com/mviereck/x11docker/wiki/CUPS-printer-in-container)
  ENV_VARS+=" --env CUPS_SERVER=/run/cups/cups.sock"
}

prepare_docker_volume_parameters() {
  # https://github.com/SeleniumHQ/docker-selenium/issues/388
  VOLUMES+=" --volume=/dev/shm:/dev/shm"
  # X11 Unix-domain socket
  VOLUMES+=" --volume=/tmp/.X11-unix:/tmp/.X11-unix"
  # Credentials in cookies used by xauth for authentication of X sessions
  VOLUMES+=" --volume=${XAUTHORITY}:/tmp/.Xauthority"
  # XDG_RUNTIME_DIR defines the base directory relative to which user-specific non-essential runtime files and other file objects (such as sockets, named pipes, ...) should be stored.
  VOLUMES+=" --volume=${XDG_RUNTIME_DIR}:${XDG_RUNTIME_DIR}"
  # Pulseaudio unix socket
  #VOLUMES+=" --volume=${XDG_RUNTIME_DIR}/pulse:${XDG_RUNTIME_DIR}/pulse:ro"
  # DBus
  # https://github.com/mviereck/x11docker/wiki/How-to-connect-container-to-DBus-from-host
  #VOLUMES+=" --volume=${XDG_RUNTIME_DIR}/bus:${XDG_RUNTIME_DIR}/bus"
  VOLUMES+=" --volume /run/dbus/system_bus_socket:/run/dbus/system_bus_socket"
  # CUPS (https://github.com/mviereck/x11docker/wiki/CUPS-printer-in-container)
  VOLUMES+=" --volume /run/cups/cups.sock:/run/cups/cups.sock"
}

prepare_docker_userdata_volumes() {
  # User shared working directory
  [ -d $HOME/work ] || mkdir -p $HOME/work
  VOLUMES+=" --volume=$HOME/work:/work"
}

prepare_docker_user_groups() {
  # Allow access to audio devices
  USER_GROUPS+=" --group-add audio"
  # Allow access to video devices
  USER_GROUPS+=" --group-add video"
  # Allow access to installed software
  USER_GROUPS+=" --group-add software"
}

prepare_docker_caps_parameters
prepare_docker_security_parameters
prepare_docker_device_parameters
prepare_docker_env_parameters
prepare_docker_volume_parameters
prepare_docker_userdata_volumes
prepare_docker_user_groups

docker run -d -it \
  --name "desktop" \
  ${CAPABILITIES} \
  ${SECURITY} \
  ${ENV_VARS} \
  ${DEVICES} \
  ${VOLUMES} \
  ${USER_GROUPS} \
  -u $USER_UID:$USER_GID \
  rubensa/desktop \
  bash -l
```

connect
```
#!/usr/bin/env bash

docker exec -it "desktop" bash -l
```

stop
```
#!/usr/bin/env bash

docker stop "desktop"
```

start
```
#!/usr/bin/env bash

docker start "desktop"
```

remove
```
#!/usr/bin/env bash

docker rm "desktop"
```

extract home
```
#!/usr/bin/env bash

USER_UID=$(id -u)
USER_GID=$(id -g)

# Create a temporary container
docker run -d -it \
  --name "temporal" \
  -u $USER_UID:$USER_GID \
  rubensa/desktop \
  bash -l

# Copy home to host
docker cp -a temporal:/home/developer/. $HOME/desktop/home

# Stop the temporary container
docker stop temporal

# Destroy the temporary container
docker rm temporal
```

Docker in Docker (run)
```
prepare_docker_userdata_volumes() {
  # Docker
  VOLUMES+=" --volume=/var/run/docker.sock:/var/run/docker.sock"
  VOLUMES+=" --volume=$(which docker):/home/developer/.local/bin/docker"
  ...
}
```
```
prepare_docker_user_groups() {
  # Allow access to docker
  USER_GROUPS+=" --group-add $(cut -d: -f3 < <(getent group docker))"
  ...
```
