FROM python:3.9.12-slim-buster

# FROM https://github.com/SeleniumHQ/docker-selenium/blob/master/Base/Dockerfile
#================================================

#================================================
# Customize sources for apt-get
#================================================
# RUN  echo "deb http://archive.ubuntu.com/ubuntu focal main universe\n" > /etc/apt/sources.list \
#     && echo "deb http://archive.ubuntu.com/ubuntu focal-updates main universe\n" >> /etc/apt/sources.list \
#     && echo "deb http://security.ubuntu.com/ubuntu focal-security main universe\n" >> /etc/apt/sources.list

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
# Python, don't write bytecode!
ENV PYTHONDONTWRITEBYTECODE 1

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
    bzip2 \
    ca-certificates \
    # openjdk-11-jre-headless \
    tzdata \
    sudo \
    unzip \
    wget \
    jq \
    curl \
    # supervisor \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
    # && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-11-openjdk-amd64/conf/security/java.security

#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata

# from https://github.com/SeleniumHQ/docker-selenium/blob/master/NodeBase/Dockerfile

#==============
# Xvfb
#==============
RUN apt-get update -qqy \
    && apt-get -qqy install \
    xvfb \
    pulseaudio \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*
#==============================
# Locale and encoding settings
#==============================
ENV LANG_WHICH en
ENV LANG_WHERE US
ENV ENCODING UTF-8
ENV LANGUAGE ${LANG_WHICH}_${LANG_WHERE}.${ENCODING}
ENV LANG ${LANGUAGE}
# Layer size: small: ~9 MB
# Layer size: small: ~9 MB MB (with --no-install-recommends)
RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
    # language-pack-en \
    tzdata \
    locales \
    && locale-gen ${LANGUAGE} \
    && dpkg-reconfigure --frontend noninteractive locales \
    && apt-get -qyy autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -qyy clean

#================
# Font libraries
#================
# libfontconfig            ~1 MB
# libfreetype6             ~1 MB
# xfonts-cyrillic          ~2 MB
# xfonts-scalable          ~2 MB
# fonts-liberation         ~3 MB
# fonts-ipafont-gothic     ~13 MB
# fonts-wqy-zenhei         ~17 MB
# fonts-tlwg-loma-otf      ~300 KB
# ttf-ubuntu-font-family   ~5 MB
#   Ubuntu Font Family, sans-serif typeface hinted for clarity
# Removed packages:
# xfonts-100dpi            ~6 MB
# xfonts-75dpi             ~6 MB
# fonts-noto-color-emoji   ~10 MB
# Regarding fonts-liberation see:
#  https://github.com/SeleniumHQ/docker-selenium/issues/383#issuecomment-278367069
# Layer size: small: 50.3 MB (with --no-install-recommends)
# Layer size: small: 50.3 MB
RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
    libfontconfig \
    libfreetype6 \
    xfonts-cyrillic \
    xfonts-scalable \
    fonts-liberation \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-tlwg-loma-otf \
    # ttf-ubuntu-font-family \
    fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -qyy clean

#=========================================================================================================================================
# Run this command for executable file permissions for /dev/shm when this is a "child" container running in Docker Desktop and WSL2 distro
#=========================================================================================================================================
RUN chmod +x /dev/shm

#============================
# Some configuration options
#============================
ENV SE_SCREEN_WIDTH 1360
ENV SE_SCREEN_HEIGHT 1020
ENV SE_SCREEN_DEPTH 24
ENV SE_SCREEN_DPI 96
ENV SE_START_XVFB true
# Temporal fix for https://github.com/SeleniumHQ/docker-selenium/issues/1610
ENV START_XVFB true
ENV SE_START_NO_VNC true
ENV SE_NO_VNC_PORT 7900
ENV SE_VNC_PORT 5900
ENV DISPLAY :99.0
ENV DISPLAY_NUM 99
# Path to the Configfile
ENV CONFIG_FILE=/opt/selenium/config.toml
ENV GENERATE_CONFIG true
# Drain the Node after N sessions. 
# A value higher than zero enables the feature
ENV SE_DRAIN_AFTER_SESSION_COUNT 0



#========================
# Selenium Configuration
#========================
# As integer, maps to "max-concurrent-sessions"
ENV SE_NODE_MAX_SESSIONS 1
# As integer, maps to "session-timeout" in seconds
ENV SE_NODE_SESSION_TIMEOUT 300
# As boolean, maps to "override-max-sessions"
ENV SE_NODE_OVERRIDE_MAX_SESSIONS false
# Following line fixes https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

# Creating base directory for Xvfb
RUN  sudo mkdir -p /tmp/.X11-unix && sudo chmod 1777 /tmp/.X11-unix

# FROM https://github.com/SeleniumHQ/docker-selenium/blob/master/NodeChrome/Dockerfile

#============================================
# Google Chrome
#============================================
# can specify versions by CHROME_VERSION;
#  e.g. google-chrome-stable=53.0.2785.101-1
#       google-chrome-beta=53.0.2785.92-1
#       google-chrome-unstable=54.0.2840.14-1
#       latest (equivalent to google-chrome-stable)
#       google-chrome-beta  (pull latest beta)
#============================================
# ARG CHROME_VERSION="google-chrome-stable"
ARG CHROME_VERSION="google-chrome-stable"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update -qqy \
    && apt-get -qqy install \
    ${CHROME_VERSION:-google-chrome-stable} \
    && rm /etc/apt/sources.list.d/google-chrome.list \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=================================
# Chrome Launch Script Wrapper
#=================================
COPY wrap_chrome_binary /opt/bin/wrap_chrome_binary
RUN /opt/bin/wrap_chrome_binary

#============================================
# Chrome webdriver
#============================================
# can specify versions by CHROME_DRIVER_VERSION
# Latest released version will be used by default
#============================================
# ARG CHROME_DRIVER_VERSION="105.0.5195.52"
RUN if [ -z "$CHROME_DRIVER_VERSION" ]; \
    then CHROME_MAJOR_VERSION=$(google-chrome --version | sed -E "s/.* ([0-9]+)(\.[0-9]+){3}.*/\1/") \
    && NO_SUCH_KEY=$(curl -ls https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_MAJOR_VERSION} | head -n 1 | grep -oe NoSuchKey) ; \
    if [ -n "$NO_SUCH_KEY" ]; then \
      echo "No Chromedriver for version $CHROME_MAJOR_VERSION. Use previous major version instead" \
      && CHROME_MAJOR_VERSION=$(expr $CHROME_MAJOR_VERSION - 1); \
    fi ; \
    CHROME_DRIVER_VERSION=$(wget --no-verbose -O - "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_MAJOR_VERSION}"); \
    fi \
    && echo "Using chromedriver version: "$CHROME_DRIVER_VERSION \
    && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip \
    && rm -rf /opt/selenium/chromedriver \
    && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
    && rm /tmp/chromedriver_linux64.zip \
    && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
    && chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
    && sudo ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

#========================================
# Add normal user with passwordless sudo
#========================================
RUN useradd seluser \
    --shell /bin/bash  \
    --create-home \
    && usermod -a -G sudo seluser \
    && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && echo 'seluser:secret' | chpasswd
ENV HOME=/home/seluser

USER seluser
