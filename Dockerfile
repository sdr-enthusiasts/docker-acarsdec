FROM ghcr.io/sdr-enthusiasts/docker-baseimage:acars-decoder-soapy

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
  /opt/acars-bridge.arm64 \
  /opt/acars-bridge.amd64 \
  && \
  # remove foreign architecture binaries
  /rename_current_arch_binary.sh && \
  rm -fv \
  /opt/acars-bridge.* \
  && \
  # install libcjson
  git clone https://github.com/DaveGamble/cJSON.git /src/cJSON && \
  pushd /src/cJSON && \
  mkdir -p /src/cJSON/build && \
  pushd /src/cJSON/build && \
  cmake .. && \
  make && \
  make install && \
  ldconfig && \
  popd && popd && \
  # acarsdec
  #git clone --depth 1 --single-branch --branch master https://github.com/TLeconte/acarsdec /src/acarsdec && \
  #git clone --depth 1 --single-branch --branch master https://github.com/wiedehopf/acarsdec.git /src/acarsdec && \
  git clone --depth 1 --single-branch --branch master https://github.com/fredclausen/acarsdec.git /src/acarsdec && \
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
