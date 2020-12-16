FROM ubuntu:20.04 as build-base

# necessary for tzdata
ENV DEBIAN_FRONTEND=noninteractive

RUN         apt-get -y update && apt-get -y upgrade
RUN         apt-get -y update && apt-get -y install             \
                                              autotools-dev     \
                                              build-essential   \
                                              cmake             \
                                              cpio              \
                                              debhelper         \
                                              devscripts        \
                                              gdb               \
                                              gcc               \
                                              git               \
                                              libattr1-dev      \
                                              libcap-dev        \
                                              libffi-dev        \
                                              libfuse-dev       \
                                              libfuse3-dev      \
                                              libssl-dev        \
                                              pkg-config        \
                                              python-dev        \
                                              python-setuptools \
                                              ruby              \
                                              ruby-dev          \
                                              rubygems          \
                                              unzip             \
                                              uuid-dev          \
                                              valgrind          \
					      zlib1g-dev

RUN sed -i /etc/apt/sources.list -e 's/main$/main universe/'

RUN apt-get -y update && apt-get -y install \
  autoconf \
  bison \
  doxygen \
  graphviz \
  gsfonts \
  dh-systemd \
  flex \
  libhesiod-dev \
  libkrb5-dev \
  libldap2-dev \
  libsasl2-dev \
  libxml2-dev \
  sssd-common \
  rsync

FROM build-base as builder

RUN git clone -b backblaze_https --depth=1 https://github.com/siscia/cvmfs && mkdir build
WORKDIR cvmfs/build
RUN cmake -DBUILD_SERVER=no \
        -DBUILD_RECEIVER=no \
        -DBUILD_GEOAPI=no \
        -DBUILD_LIBCVMFS=no \
        -DBUILD_LIBCVMFS_CACHE=no \
        -DINSTALL_BASH_COMPLETION=no \
        ..
RUN make -j4

RUN mkdir ~/root && \
        make DESTDIR=~/root install && \
        rm -rf ~/root/usr/lib*/libcvmfs_fuse.* \
        rm -rf ~/root/usr/lib*/libcvmfs_fuse_debug.* \
        rm -rf ~/root/usr/lib*/libcvmfs_fuse_stub.* \
        rm -rf ~/root/usr/lib*/cvmfs/auto.cvmfs

# the executables that we want are now in ~/root/usr
# however we need to isolate the runtime dependecies of those executables
# we start by finding all the files with `find`
# then we run ldd against each of those files to get their runtime dependencies
# the output of ldd is manipulated with awk, grep, sort and uniq to get only a list of dependencies
# finally we use rsync to copy the dependencies we need in a specific directory
RUN mkdir ~/deps && \
        find ~/root/usr/ -type f | \
        xargs -n 1 -I {} ldd {} 2>/dev/null | \
        awk '{print $3}' | \
        grep /lib | sort | uniq | \
        rsync -aL --files-from=- / ~/deps/


FROM ubuntu:20.04 AS final

COPY --from=builder /root/deps/lib /lib
COPY --from=builder /root/root/etc /etc
COPY --from=builder /root/root/sbin /sbin
COPY --from=builder /root/root/usr /usr

RUN mkdir -p /var/log /var/run/cvmfs /cvmfs /var/spool/cvmfs/

ADD docker/mount_cvmfs.sh /usr/bin
ADD docker/check_cvmfs.sh /usr/bin
ADD docker/terminate.sh /usr/bin

ADD packages.redbeardlab.com.tar /etc

# Needs to be set to the site squid
ENV CVMFS_HTTP_PROXY=DIRECT
# The cvmfs-config.cern.ch repository gets always mounted
ENV CVMFS_REPOSITORIES packages.redbeardlab.com
# Default: 10G cache
ENV CVMFS_QUOTA_LIMIT 10000
# Use the VERSION argument in the mount_cvmfs script

RUN apt update && apt-get install -y ca-certificates attr && adduser cvmfs

ENTRYPOINT [ "/usr/bin/mount_cvmfs.sh" ]

HEALTHCHECK --interval=5m --start-period=1m --timeout=1m \
  CMD [ "/usr/bin/check_cvmfs.sh", "liveness" ]

