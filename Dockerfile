# Use an ubuntu base image
# This stage is for building the various slurm binaries as debian packages
# We download slurm and install all of its buildtime dependencies
FROM ubuntu:22.04 AS slurm-base
ENV DEBIAN_FRONTEND=noninteractive
ARG SLURM_VERSION
WORKDIR /opt

# hadolint ignore=DL3003,DL3009,DL4006
RUN <<EOF
rm -f /etc/apt/apt.conf.d/docker-clean
echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache
apt-get update
apt-get install --no-install-recommends -y build-essential=12.9ubuntu3 fakeroot=1.28-1ubuntu1 devscripts=2.22.1ubuntu1 curl=7.81.0-1ubuntu1.16 equivs=2.3.1 ca-certificates=20230311ubuntu0.22.04.1
curl -LO https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2
tar -xaf slurm-${SLURM_VERSION}.tar.bz2
cd slurm-${SLURM_VERSION} || exit 1
echo "y" | mk-build-deps -i debian/control
EOF

# In slurm-builder we build the debian packages
FROM slurm-base AS slurm-builder
ARG SLURM_VERSION
WORKDIR /opt/slurm-${SLURM_VERSION}
RUN debuild -b -uc -us

# In slurm-runtime, we use the base which has the buildtime dependencies and
# then add runtime dependencies like munge.
# We remove things like the slurm source code since we don't need it at runtime.
# All slurm subsystems also require the slurm-smd package so we install that
# here.
FROM slurm-base AS slurm-runtime
ARG SLURM_VERSION
WORKDIR /root

RUN <<EOF
useradd -ms /bin/bash slurm
apt-get install --no-install-recommends -y munge=0.5.14-6 libmunge-dev=0.5.14-6
rm -rf /var/lib/apt/lists/*
rm -rf /opt/slurm-${SLURM_VERSION}*
EOF

COPY --chmod=700 --chown=munge:munge <<EOF /etc/munge/munge.key
asdfasdfasdfasdfasdfasdfasdfasdf
EOF

COPY --from=slurm-builder \
  /opt/slurm-smd_${SLURM_VERSION}-1_amd64.deb \
  /opt/
RUN <<EOF
dpkg -i "/opt/slurm-smd_${SLURM_VERSION}-1_amd64.deb"
rm "/opt/slurm-smd_${SLURM_VERSION}-1_amd64.deb"
EOF

FROM slurm-runtime AS slurmdbd
COPY --from=slurm-builder \
  /opt/slurm-smd-slurmdbd_${SLURM_VERSION}-1_amd64.deb \
  /opt/
RUN <<EOF
dpkg -i "/opt/slurm-smd-slurmdbd_${SLURM_VERSION}-1_amd64.deb"
rm "/opt/slurm-smd-slurmdbd_${SLURM_VERSION}-1_amd64.deb"
EOF

FROM slurm-runtime AS slurmctld
COPY --from=slurm-builder \
  /opt/slurm-smd-slurmctld_${SLURM_VERSION}-1_amd64.deb \
  /opt/slurm-smd-client_${SLURM_VERSION}-1_amd64.deb \
  /opt/
RUN <<EOF
dpkg -i "/opt/slurm-smd-slurmctld_${SLURM_VERSION}-1_amd64.deb"
dpkg -i "/opt/slurm-smd-client_${SLURM_VERSION}-1_amd64.deb"
rm "/opt/slurm-smd-slurmctld_${SLURM_VERSION}-1_amd64.deb" "/opt/slurm-smd-client_${SLURM_VERSION}-1_amd64.deb"
EOF

USER slurm

ENTRYPOINT ["/usr/sbin/slurmctld", "-D", "-v"]

FROM slurm-runtime AS slurmd
COPY --from=slurm-builder \
  /opt/slurm-smd-slurmd_${SLURM_VERSION}-1_amd64.deb \
  /opt/slurm-smd-client_${SLURM_VERSION}-1_amd64.deb \
  /opt/
RUN <<EOF
dpkg -i "/opt/slurm-smd-slurmd_${SLURM_VERSION}-1_amd64.deb"
dpkg -i "/opt/slurm-smd-client_${SLURM_VERSION}-1_amd64.deb"
rm "/opt/slurm-smd-slurmd_${SLURM_VERSION}-1_amd64.deb" "/opt/slurm-smd-client_${SLURM_VERSION}-1_amd64.deb"
EOF

FROM slurm-runtime AS login
COPY --from=slurm-builder \
  /opt/slurm-smd-client_${SLURM_VERSION}-1_amd64.deb \
  /opt/
RUN <<EOF
dpkg -i "/opt/slurm-smd-client_${SLURM_VERSION}-1_amd64.deb"
rm "/opt/slurm-smd-client_${SLURM_VERSION}-1_amd64.deb"
EOF
