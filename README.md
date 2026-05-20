# solarscout-squid

Ubuntu-based [Squid](https://www.squid-cache.org/) 7.3 image (made for SolarScout), with reproducible build and healthcheck

This repository contains the files needed to build the standalone Squid image, available [here](https://hub.docker.com/repository/docker/sjtobin/solarscout-squid/general) on [Dockerhub](https://hub.docker.com/) used to route SolarScout's outbound traffic via proxy. Squid is a forward proxy for outbound HTTP/HTTPS traffic. Here, Squid 7.3 is built in two stages from a pinned upstream source in Ubuntu 24.04.

## Features
 - Squid 7.3 built from pinned upstream source
 - Multi-stage build to minimize image size
 - Healthcheck included
 - Default configuration file provided for general container-network use

## Prerequisites
 - [Docker](https://www.docker.com/) installed

## Build
```bash
docker build -t sjtobin/solarscout-squid:7.3 .
```

Don't forget the final `.`

## Run
```bash 
docker run --rm -p 3128:3128 sjtobin/solarscout-squid:7.3
```

## Apply your own configuration
To use your own Squid configuration (`squid.conf`), mount it into the container:

```bash
docker run --rm -p 3128:3128 \
  -v "$(pwd)/squid.conf:/etc/squid/squid.conf:ro" \
  sjtobin/solarscout-squid:7.3
```

The default `squid.conf` file forces IPv4 for outbound connections. This prevents unintended IPv6 routing where it is unavailable or unreliable: `tcp_outgoing_address 0.0.0.0`

## Usage in SolarScout 
In SolarScout, this image can be pulled directly from Docker Hub to avoid recompiling Squid during the local build. As mentioned above, a project-specific `squid.conf` can be mounted into the container to enforce stricter outbound whitelists, blacklists or other access rules.

## Image

Docker Hub:

- [sjtobin/solarscout-squid:7.3](https://hub.docker.com/repository/docker/sjtobin/solarscout-squid/general)

