# syntax=docker/dockerfile:1
# usage:
# docker build --tag webapp-build .

FROM gcc:11 as webapp-build
# root@24c61d90f38f:/app# ldd GreeterStandalone
#         linux-vdso.so.1 (0x00007ffff97e5000)
#         libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007ffbb046e000)
#         libstdc++.so.6 => /usr/local/lib64/libstdc++.so.6 (0x00007ffbb025a000)
#         libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007ffbb0116000)
#         libgcc_s.so.1 => /usr/local/lib64/libgcc_s.so.1 (0x00007ffbb00fb000)
#         libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007ffbaff27000)
#         /lib64/ld-linux-x86-64.so.2 (0x00007ffbb049a000)
# root@24c61d90f38f:/app#

#FIXME: FROM debian:bullseye as webapp-build
# No CMAKE_CXX_COMPILER could be found!

# build
RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
    clang \
    doxygen \
    python \
    pip \
    # configure/build with Boost as system lib - this should be orders of magnitude faster to configure than
    # downloading via CPM.cmake while Boost's CMake support is still experimental
    libboost-thread-dev \
    ;

# Installing build tools
RUN pip install cmake ninja #XXX cmake-format gcovr doxygen
#XXX RUN pip install -r requirements.txt

#NO! WORKDIR /

# Copying files
COPY . .

# Building the application
RUN cd standalone && cmake --workflow --preset=default
# RUN cmake -S standalone -B build/standalone -G Ninja -D CMAKE_BUILD_TYPE=Release
# RUN ninja -C build/standalone
# RUN ninja -C build/standalone install

# deploy
FROM gcc:11 as webapp-run
#FIXME: FROM debian:bullseye-slim as webapp-run
# ./GreeterStandalone: /usr/lib/x86_64-linux-gnu/libstdc++.so.6: version `GLIBCXX_3.4.29' not found
# ./GreeterStandalone: /usr/lib/x86_64-linux-gnu/libstdc++.so.6: version `CXXABI_1.3.13' not found

WORKDIR /app
COPY --from=webapp-build /build/standalone/GreeterStandalone .
COPY --from=webapp-build /build/standalone/GreeterStandalone-1.0-Linux.tar.gz .
RUN tar -xzf GreeterStandalone-1.0-Linux.tar.gz --strip-components=1 GreeterStandalone-1.0-Linux

# Running application as a simple service forever
CMD ["./GreeterStandalone"]

# queries:
# curl localhost:3080/hello?
# curl localhost:3080/hello?language=
# curl localhost:3080/hello?language='bla'
# curl localhost:3080/hello?language='en'
