FROM debian:stable-20211220-slim

ENV BRANCH_RTLSDR="ed0317e6a58c098874ac58b769cf2e609c18d9a5" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    SERIAL="" \
    DEVICE_INDEX="" \
    GAIN="-10" \
    QUIET_LOGS="TRUE" \
    PPM="0"\
    RTL_MULTI="" \
    FREQUENCIES="" \
    STATION_ID="" \
    ACARSHUB_SERVER="acarshub-server"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy needs to be prior to any curl/wget so SSL certs from GitHub runner are loaded
COPY rootfs/ /

# hadolint ignore=DL3008,SC2086
RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Required for building multiple packages.
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(pkg-config) && \
    TEMP_PACKAGES+=(cmake) && \
    TEMP_PACKAGES+=(git) && \
    TEMP_PACKAGES+=(automake) && \
    TEMP_PACKAGES+=(autoconf) && \
    TEMP_PACKAGES+=(wget) && \
    # logging
    KEPT_PACKAGES+=(gawk) && \
    KEPT_PACKAGES+=(pv) && \
    # required for S6 overlay
    # curl kept for healthcheck
    # ca-certificates kept for python
    TEMP_PACKAGES+=(gnupg2) && \
    TEMP_PACKAGES+=(file) && \
    KEPT_PACKAGES+=(curl) && \
    KEPT_PACKAGES+=(ca-certificates) && \
    # libusb-1.0-0 + dev - Required for rtl-sdr, libiio (bladeRF/PlutoSDR).
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
    # packages for libacars
    TEMP_PACKAGES+=(zlib1g-dev) && \
    TEMP_PACKAGES+=(libxml2-dev) && \
    KEPT_PACKAGES+=(zlib1g) && \
    KEPT_PACKAGES+=(libxml2) && \
    # packages for acarsserv
    TEMP_PACKAGES+=(libsqlite3-dev) && \
    KEPT_PACKAGES+=(libsqlite3-0) && \
    # packages for network stuff
    KEPT_PACKAGES+=(socat) && \
    KEPT_PACKAGES+=(ncat) && \
    KEPT_PACKAGES+=(net-tools) && \
    # process management
    KEPT_PACKAGES+=(procps) && \
    # install packages
    ## Builder fixes...
    mkdir -p /usr/sbin/ && \
    ln -s /usr/bin/dpkg-split /usr/sbin/dpkg-split && \
    ln -s /usr/bin/dpkg-deb /usr/sbin/dpkg-deb && \
    ln -s /bin/tar /usr/sbin/tar && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}"\
        && \
    # python3 -m pip install --no-cache-dir \
    #     -r /webapp/requirements.txt \
    #     && \
    # rtl-sdr
    git clone git://git.osmocom.org/rtl-sdr.git /src/rtl-sdr && \
    pushd /src/rtl-sdr && \
    git checkout "${BRANCH_RTLSDR}" && \
    echo "rtl-sdr ${BRANCH_RTLSDR}" >> /VERSIONS && \
    mkdir -p /src/rtl-sdr/build && \
    pushd /src/rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -Wno-dev && \
    make -Wstringop-truncation && \
    make -Wstringop-truncation install && \
    cp -v /src/rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/ && \
    popd && popd && \
    # libacars
    git clone git://github.com/szpajder/libacars.git /src/libacars && \
    pushd /src/libacars && \
    git checkout master && \
    mkdir build && \
    pushd build && \
    cmake ../ && \
    make && \
    make install && \
    popd && popd && \
    # acarsdec
    #git clone https://github.com/fredclausen/acarsdec.git /src/acarsdec && \
    git clone --single-branch --branch testing https://github.com/airframesio/acarsdec.git /src/acarsdec && \
    pushd /src/acarsdec && \
    #git checkout master && \
    git checkout testing && \
    mkdir build && \
    pushd build && \
    cmake ../ -Drtl=ON && \
    make && \
    make install && \
    popd && popd && \
    # directory for logging
    mkdir -p /run/acars && \
    # extract webapp
    tar -xzvf /src/webapp.tar.gz -C / && \
    # install S6 Overlay
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    # deploy healthchecks framework
    git clone \
      --depth=1 \
      https://github.com/mikenye/docker-healthchecks-framework.git \
      /opt/healthchecks-framework \
      && \
    rm -rf \
      /opt/healthchecks-framework/.git* \
      /opt/healthchecks-framework/*.md \
      /opt/healthchecks-framework/tests \
      && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

ENTRYPOINT [ "/init" ]

EXPOSE 80

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
