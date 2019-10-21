FROM rubensa/ubuntu-dev
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Define software group id's
ARG SOFTWARE_GROUP_ID=2000

# Define software group and installation folder
ENV SOFTWARE_GROUP=software SOFTWARE_INSTALL_DIR=/software

# Tell docker that all future commands should be run as root
USER root

# Set root home directory
ENV HOME=/root

# Copy script to run AppImage files
COPY runapp /usr/local/bin/

ARG GIMP_VERSION=GIMP_AppImage-release-2.10.8-withplugins-x86_64
#ARG INKSCAPE_VERSION=Inkscape-0.92.3%2B68.glibc2.15-x86_64


# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    # 
    # Install software and needed libraries
    && apt-get -y install acl pulseaudio software-properties-common qtwayland5 libavcodec-extra libcanberra-gtk-module libcanberra-gtk3-module qml-module-qtquick-controls libgconf-2-4 libxkbfile1 \
    #
    # Give execution permmision to runapp script
    && chmod +x /usr/local/bin/runapp \
    #
    # Add Repos
    #
    # Chrome repo
    && printf "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && curl -O https://dl.google.com/linux/linux_signing_key.pub \
    && apt-key add linux_signing_key.pub \
    && rm linux_signing_key.pub \
    #
    # Thunderbird repo
    && sudo add-apt-repository -y ppa:mozillateam/ppa \
    #
    # VideoLAN repo
    && add-apt-repository -y ppa:videolan/master-daily \
    #
    # Inkscape repo
    && add-apt-repository -y ppa:inkscape.dev/stable \
    #
    # Krita repo
    && add-apt-repository -y ppa:kritalime/ppa \
    #
    # LibreOffice repo
    && add-apt-repository -y ppa:libreoffice/ppa \
    #
    # Deluge repo
    && add-apt-repository ppa:deluge-team/ppa \
    #
    # Install software
    && apt-get -y install firefox thunderbird google-chrome-stable vlc inkscape krita libreoffice deluge filezilla \
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
    # Install software
    # GIMP AppImage
    && curl -L -o ${SOFTWARE_INSTALL_DIR}/${GIMP_VERSION}.AppImage https://github.com/aferrero2707/gimp-appimage/releases/download/continuous/${GIMP_VERSION}.AppImage \
    && chmod +x ${SOFTWARE_INSTALL_DIR}/${GIMP_VERSION}.AppImage \
    && printf "runapp %s.AppImage \"\$@\"" ${GIMP_VERSION} > /usr/local/bin/gimp \
    && chmod +x /usr/local/bin/gimp \
    # Inkscape AppImage
    #curl -L -o ${SOFTWARE_INSTALL_DIR}/${INKSCAPE_VERSION}.AppImage https://bintray.com/probono/AppImages/download_file?file_path=${INKSCAPE_VERSION}.AppImage \
    #&& chmod +x ${SOFTWARE_INSTALL_DIR}/${INKSCAPE_VERSION}.AppImage \
    #&& printf "runapp %s.AppImage \"\$@\"" ${INKSCAPE_VERSION} > /usr/local/bin/inkscape \
    #&& chmod +x /usr/local/bin/inkscape \
    #
    # Calibre
    && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin install_dir=${SOFTWARE_INSTALL_DIR} \
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

# Create some user directories
RUN mkdir -p $HOME/.config \
    && mkdir -p $HOME/.local/bin
