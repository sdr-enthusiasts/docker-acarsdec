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

## Up and running

```yaml
version: '2.0'

services:
  acarsdec:
    image: fredclausen/acarsdec:latest
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
| `GAIN`| The gain applied to the RTL-SDR dongle. Recommended to leave at the default autogain. If you want to set the gain manually it is set in tenth of db (ie -g 90 for +9db) | No | `A` for autogain |
| `SERVER` | The server where messages will be forwarded to. If blank it will output to `stdout`. | No | Blank |
| `SERVER_PORT` | The port where the server will receive messages on. | No | `5550` |
| `MODE` | The output mode. `P` for planeplotter, `J` for JSON and `A` for acarsdec. | No | `J` |
