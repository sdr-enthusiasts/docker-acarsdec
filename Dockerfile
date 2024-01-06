FROM ghcr.io/sdr-enthusiasts/docker-baseimage:acars-decoder

ENV DEVICE_INDEX="" \
    QUIET_LOGS="TRUE" \
    FREQUENCIES="" \
    FEED_ID="" \
    PPM="0"\
    GAIN="-10" \
    RTLMULT="160" \
    SERIAL="" \
    SOAPYSDR="" \
    OUTPUT_SERVER="acars_router" \
    OUTPUT_SERVER_PORT="5550" \
    OUTPUT_SERVER_MODE="udp" \
    MODE="J"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY ./rootfs /
COPY ./bin/acars-bridge.armv7/acars-bridge /opt/acars-bridge.armv7
COPY ./bin/acars-bridge.arm64/acars-bridge /opt/acars-bridge.arm64
COPY ./bin/acars-bridge.amd64/acars-bridge /opt/acars-bridge.amd64

# hadolint ignore=DL3008,SC2086,SC2039
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
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    KEPT_PACKAGES+=(libzmq5) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}" && \
    # ensure binaries are executable
    chmod -v a+x \
    /opt/acars-bridge.armv7 \
    /opt/acars-bridge.arm64 \
    /opt/acars-bridge.amd64 \
    && \
    # remove foreign architecture binaries
    /rename_current_arch_binary.sh && \
    rm -fv \
    /opt/acars-bridge.* \
    && \
    # install sdrplay
    curl --location --output /tmp/install_sdrplay.sh https://raw.githubusercontent.com/sdr-enthusiasts/install-libsdrplay/main/install_sdrplay.sh && \
    chmod +x /tmp/install_sdrplay.sh && \
    /tmp/install_sdrplay.sh && \
    # deploy airspyone host
    git clone https://github.com/airspy/airspyone_host.git /src/airspyone_host && \
    pushd /src/airspyone_host && \
    mkdir -p /src/airspyone_host/build && \
    pushd /src/airspyone_host/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON && \
    make && \
    make install && \
    ldconfig && \
    popd && popd && \
    # remove the source code
    rm -rf /src/airspyone_host && \
    # Deploy SoapySDR
    git clone https://github.com/pothosware/SoapySDR.git /src/SoapySDR && \
    pushd /src/SoapySDR && \
    BRANCH_SOAPYSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYSDR" && \
    mkdir -p /src/SoapySDR/build && \
    pushd /src/SoapySDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Debug && \
    make all && \
    make test && \
    make install && \
    popd && popd && \
    ldconfig && \
    # remove the source code
    rm -rf /src/SoapySDR && \
    # Deploy SoapyRTLTCP
    git clone https://github.com/pothosware/SoapyRTLTCP.git /src/SoapyRTLTCP && \
    pushd /src/SoapyRTLTCP && \
    mkdir -p /src/SoapyRTLTCP/build && \
    pushd /src/SoapyRTLTCP/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Debug && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # remove the source code
    rm -rf /src/SoapyRTLTCP && \
    # Deploy SoapyRTLSDR
    git clone https://github.com/pothosware/SoapyRTLSDR.git /src/SoapyRTLSDR && \
    pushd /src/SoapyRTLSDR && \
    BRANCH_SOAPYRTLSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYRTLSDR" && \
    mkdir -p /src/SoapyRTLSDR/build && \
    pushd /src/SoapyRTLSDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Debug && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # remove the source code
    rm -rf /src/SoapyRTLSDR && \
    # install sdrplay support for soapy
    git clone https://github.com/pothosware/SoapySDRPlay.git /src/SoapySDRPlay && \
    pushd /src/SoapySDRPlay && \
    mkdir build && \
    pushd build && \
    cmake .. && \
    make && \
    make install && \
    popd && \
    popd && \
    ldconfig && \
    # remove the source code
    rm -rf /src/SoapySDRPlay && \
    # Deploy Airspy
    git clone https://github.com/pothosware/SoapyAirspy.git /src/SoapyAirspy && \
    pushd /src/SoapyAirspy && \
    mkdir build && \
    pushd build && \
    cmake .. && \
    make    && \
    make install   && \
    popd && \
    popd && \
    ldconfig && \
    # remove the source code
    rm -rf /src/SoapyAirspy && \
    # acarsdec
    #git clone --depth 1 --single-branch --branch master https://github.com/TLeconte/acarsdec /src/acarsdec && \
    git clone --depth 1 --single-branch --branch master https://github.com/wiedehopf/acarsdec.git /src/acarsdec && \
    pushd /src/acarsdec && \
    #git checkout master && \
    #git checkout testing && \
    sed -i -e 's/-march=native//' CMakeLists.txt && \
    mkdir build && \
    pushd build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Debug -Drtl=OFF -Dsdrplay=OFF -Dairspy=OFF -Dsoapy=ON && \
    make && \
    make install && \
    popd && popd && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

# ENTRYPOINT [ "/init" ]

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
