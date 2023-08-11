# syntax=docker/dockerfile:1
# usage:
# docker build --tag webapp-build .

# docker build
FROM ubuntu:latest as webapp-build

# Installing debian build tools
RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
    git \
    gcc \
    curl \
    clang \
    doxygen \
    python3 \
    pip \
    # configure/build with Boost as system lib - this should be orders of magnitude faster to configure than
    # downloading via CPM.cmake while Boost's CMake support is still experimental
    libboost-thread-dev \
    ;

# Installing build tools with pip
RUN pip install wheel cmake ninja #XXX cmake-format gcovr
#XXX RUN pip install -r requirements.txt

#NO! WORKDIR /

# Copying files
COPY . .

# Building the application
RUN cd standalone && cmake --workflow --preset=default

# deploy
FROM ubuntu:latest as webapp-run

# Installing debian runtime packages
# TBD: snmp snmp-mibs-downloader \
RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
    curl \
    traceroute \
    iputils-ping \
    netbase \
    network-manager \
    python3 \
    pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Installing build tools with pip
RUN pip install wheel pyftpdlib

COPY --from=webapp-build /standalone/service_test.sh .
COPY --from=webapp-build /build/standalone/GreeterStandalone .
COPY --from=webapp-build /build/standalone/GreeterStandalone-1.0-Linux.tar.gz .
RUN tar -xzf GreeterStandalone-1.0-Linux.tar.gz --strip-components=1 GreeterStandalone-1.0-Linux/lib

ENV LANG=C.UTF8
ENV LD_LIBRARY_PATH=/app/lib/Greeter-1.0:/app/lib:$LD_LIBRARY_PATH

EXPOSE 3080/tcp
HEALTHCHECK --interval=1m --timeout=3s \
  CMD /app/service_test.sh /bin/echo || exit 1

# Running application as a simple service forever
CMD ["./GreeterStandalone"]

# example query:
# curl http://127.0.0.1:3080/hello?language=de
# {"answer":"Hallo Crow & Greeter!"}root@cec7ca507295:/app#
