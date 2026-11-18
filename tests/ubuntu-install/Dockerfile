# Ubuntu with systemd as PID 1, so the installer can create and start a real unit.
ARG UBUNTU=24.04
FROM ubuntu:${UBUNTU}
ENV DEBIAN_FRONTEND=noninteractive container=docker
RUN apt-get update && apt-get install -y --no-install-recommends systemd systemd-sysv sudo ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /lib/systemd/system/multi-user.target.wants/* /etc/systemd/system/*.wants/* \
       /lib/systemd/system/local-fs.target.wants/* /lib/systemd/system/sockets.target.wants/*udev* \
       /lib/systemd/system/sockets.target.wants/*initctl* /lib/systemd/system/basic.target.wants/* \
       /lib/systemd/system/anaconda.target.wants/*
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
