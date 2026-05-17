# Compile Squid from pinned upstream release selected by SQUID_TAG
FROM ubuntu:24.04 AS builder

ARG SQUID_TAG=SQUID_7_3
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates wget xz-utils pkg-config perl \
    autoconf automake libtool libtool-bin libltdl-dev m4 bison flex \
    libssl-dev libxml2-dev libpam0g-dev libexpat1-dev libcap2-dev libkrb5-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN set -eux; \
    wget -O squid.tar.gz "https://github.com/squid-cache/squid/archive/refs/tags/${SQUID_TAG}.tar.gz"; \
    tar -xzf squid.tar.gz; \
    cd "squid-${SQUID_TAG}"; \
    ./bootstrap.sh; \
    ./configure \
      --prefix=/usr \
      --sysconfdir=/etc/squid \
      --localstatedir=/var \
      --with-default-user=proxy; \
    make -j"$(nproc)"; \
    make install; \
    rm -rf /tmp/*

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libssl3 libxml2 libpam0g libexpat1 libcap2 libkrb5-3 \
 && rm -rf /var/lib/apt/lists/*

# Create runtime user/group: we're building from source not installing via apt
RUN set -eux; \
    getent group proxy >/dev/null || groupadd --system proxy; \
    id -u proxy >/dev/null 2>&1 || useradd --system --gid proxy --no-create-home --shell /usr/sbin/nologin proxy

# Copy built Squid installation; override default config with our runtime config
COPY --from=builder /usr /usr
COPY --from=builder /etc/squid /etc/squid
COPY squid.conf /etc/squid/squid.conf

# Creat writable runtime directories that Squid expects
RUN mkdir -p /var/log/squid /var/spool/squid /var/run \
 && chown -R proxy:proxy /var/log/squid /var/spool/squid /var/run

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD pid="$(cat /var/run/squid.pid 2>/dev/null)" \
   && [ -n "$pid" ] \
   && kill -0 "$pid" >/dev/null 2>&1 \
   || exit 1

# Run Squid in foreground, clear any stale PID file from earlier container state
CMD ["sh", "-c", "rm -f /var/run/squid.pid && exec squid -N -f /etc/squid/squid.conf"]

