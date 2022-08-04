FROM ghcr.io/sdr-enthusiasts/docker-baseimage:acars-decoder

ENV DEVICE_INDEX="" \
    QUIET_LOGS="TRUE" \
    FREQUENCIES="" \
    FEED_ID="" \
    PPM="0"\
    GAIN="-10" \
    RTLMULT="160" \
    SERIAL="" \
    SERVER="acarshub" \
    SERVER_PORT="5550" \
    MODE="J"

# hadolint ignore=DL3008,SC2086,SC2039,SC3054
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
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}"\
    && \
    # acarsdec
    #git clone https://github.com/fredclausen/acarsdec.git /src/acarsdec && \
    #git clone --single-branch --branch testing https://github.com/airframesio/acarsdec.git /src/acarsdec && \
    git clone --depth 1 --single-branch --branch master https://github.com/TLeconte/acarsdec /src/acarsdec && \
    #git clone --depth 1 --single-branch --branch master https://github.com/wiedehopf/acarsdec.git /src/acarsdec && \
    pushd /src/acarsdec && \
    #git checkout master && \
    #git checkout testing && \
    sed -i -e 's/-march=native//' CMakeLists.txt && \
    mkdir build && \
    pushd build && \
    cmake ../ -Drtl=ON -DCMAKE_BUILD_TYPE=Debug && \
    make && \
    make install && \
    popd && popd && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*


COPY rootfs/ /

# ENTRYPOINT [ "/init" ]

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
