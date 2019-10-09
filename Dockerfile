FROM rubensa/ubuntu-dev
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Copy script to user's home directory
COPY set-software-path.sh ${HOME}

# Configure PATH in .profile for the non-root user
RUN printf "\n. set-software-path.sh\n" >> ~/.profile

# Define software group id's
ARG SOFTWARE_GROUP_ID=2000

# Define software group and installation folder
ENV SOFTWARE_GROUP=software SOFTWARE_INSTALL_DIR=/software

# Tell docker that all future commands should be run as root
USER root

# Set root home directory
ENV HOME=/root

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    # 
    # Install ACY and pulseaudio
    && apt-get -y install acl pulseaudio \
    #
    # Create a software group
    && addgroup --gid ${SOFTWARE_GROUP_ID} ${SOFTWARE_GROUP} \
    #
    # Assign software group to non-root user
    && usermod -a -G ${SOFTWARE_GROUP} ${DEV_USER} \
    #
    # Create software installation directory
    && mkdir -p ${SOFTWARE_INSTALL_DIR} \
    #
    # Install common desktop software libraries
    && apt-get -y install libnss3 libxss1 libgl1 libgtk-3-0 libdbus-glib-1-2 libxt6 libcanberra-gtk-module libcanberra-gtk3-module  \
    #
    # Assign software group folder ownership
    && chgrp -R ${SOFTWARE_GROUP} ${SOFTWARE_INSTALL_DIR} \
    #
    # Give write acces to the group
    && chmod -R g+wX ${SOFTWARE_INSTALL_DIR} \
    #
    # Set ACL to files created in the folder
    && setfacl -d -m u::rwX,g::rwX,o::r-X ${SOFTWARE_INSTALL_DIR} \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

# Tell docker that all future commands should be run as the non-root user
USER ${DEV_USER}

# Set user home directory (see: https://github.com/microsoft/vscode-remote-release/issues/852)
ENV HOME /home/$DEV_USER
