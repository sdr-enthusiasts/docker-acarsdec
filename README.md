# Docker acarsdec

![Banner](https://github.com/fredclausen/docker-acarshub/blob/16ab3757986deb7c93c08f5c7e3752f54a19629c/Logo-Sources/ACARS%20Hub.png "banner")
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/fredclausen/docker-acarshub/Deploy%20to%20Docker%20Hub)](https://github.com/fredclausen/docker-acarshub/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/fredclausen/acarshub.svg)](https://hub.docker.com/r/fredclausen/acarshub)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/fredclausen/acarshub/latest)](https://hub.docker.com/r/fredclausen/acarshub)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container for running [airframe's fork of acarsdec](https://github.com/airframesio/acarsdec) and forwarding the received JSON messages to another system or docker container. Best used alongside [ACARS Hub](https://github.com/fredclausen/acarshub).

Builds and runs on `amd64`, `arm64`, `arm/v7`, `arm/v6` and `386` architectures.

## Note for Users running 32-bit Debian Buster-based OSes on ARM

Please see: [Buster-Docker-Fixes](https://github.com/fredclausen/Buster-Docker-Fixes)!

## Required hardware

A computer host on a suitable architecture and one USB RTL-SDR dongle connected to an antenna.

## ACARS Hub integration

The default `SERVER` and `SERVER_PORT` values are suitable for automatically working with ACARS Hub, provided ACARS Hub is **on the same pi as the decoder**. If ACARS Hub is not on the same Pi, please provide the correct host name in the `SERVER` variable. Very likely you will not have to change the `SERVER_PORT`, but if you did change the port mapping on your ACARS Hub (and you will know if you did) please set the server port correctly as well.

## Up and running

```yaml
version: '2.0'

services:
  acarsdec:
    image:  ghcr.io/sdr-enthusiasts/docker-acarsdec:latest
    tty: true
    container_name: acarsdec
    restart: always
    devices:
      - /dev/bus/usb:/dev/bus/usb
    ports:
    environment:
      - TZ="America/Denver"
      - SERIAL=13305
      - FEED_ID=ACARS
      - FREQUENCIES=130.025;130.450;131.125;131.550
    tmpfs:
      - /run:exec,size=64M
      - /var/log
```

## Configuration options

| Variable | Description | Required | Default |
|----------|-------------|---------|--------|
| `TZ` | Your timezone | No | UTC |
| `SERIAL` | The serial number of your RTL-SDR dongle | Yes | Blank |
| `FEED_ID` | Used by the decoder to insert a unique ID in to the output message | Yes | Blank |
| `FREQUENCIES` | Colon-separated list of frequencies, but to a maximum of 8, for the decoder to list to | Yes | Blank |
| `PPM` | Parts per million correction of the decoder | No | 0 |
| `GAIN`| The gain applied to the RTL-SDR dongle. Recommended to leave at the default autogain. To set manually, gain in in db (0 to 49.6; >52 and -10 will result in AGC; default is AGC) | No | `-10` for autogain |
| `SERVER` | The server where messages will be forwarded to. | No | Blank |
| `SERVER_PORT` | The port where the server will receive messages on. | No | `5550` |
| `MODE` | The output mode. `P` for planeplotter, `J` for JSON and `A` for acarsdec. | No | `J` |
| `QUIET_LOGS` | Mute log output to the bare minimum. Set to `false` to see all of the log messages.| No | `TRUE` |
