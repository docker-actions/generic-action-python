ARG ROOTFS=/build/rootfs

FROM ubuntu:bionic as build

ARG REQUIRED_PACKAGES=""
ARG IMAGE_NAME=""
ARG ROOTFS

ENV BUILD_DEBS /build/debs
ENV DEBIAN_FRONTEND noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE true

RUN : "${IMAGE_NAME:?Build argument needs to be set and non-empty.}"
RUN : "${ROOTFS:?Build argument needs to be set and non-empty.}"

SHELL ["bash", "-Eeuc"]

# Build pre-requisites
RUN mkdir -p ${BUILD_DEBS} ${ROOTFS}/{sbin,usr/local/bin}

RUN apt-get update; \
    apt-get install -yq python3-pip; \
    pip3 install -vvv --upgrade --root ${ROOTFS} --force-reinstall ${REQUIRED_PACKAGES}

# Move /sbin out of the way
RUN set -Eeuo pipefail; \
    mv ${ROOTFS}/sbin ${ROOTFS}/sbin.orig; \
    mkdir -p ${ROOTFS}/sbin; \
    for b in ${ROOTFS}/sbin.orig/*; do \
      echo 'cmd=$(basename ${BASH_SOURCE[0]}); exec /sbin.orig/$cmd "$@"' > ${ROOTFS}/sbin/$(basename $b); \
      chmod +x ${ROOTFS}/sbin/$(basename $b); \
    done

COPY ${IMAGE_NAME}.entrypoint.sh ${ROOTFS}/usr/local/bin/entrypoint.sh
RUN chmod +x ${ROOTFS}/usr/local/bin/entrypoint.sh

FROM actions/python3:3.6.5-7
LABEL maintainer = "ilja+docker@bobkevic.com"

ARG ROOTFS
RUN : "${ROOTFS:?Build argument needs to be set and non-empty.}"

ENV PYTHONPATH=:/usr/lib/python36.zip:/usr/lib/python3.6:/usr/lib/python3.6/lib-dynload:/usr/lib/python3/dist-packages:/usr/local/lib/python3.6/dist-packages
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

COPY --from=build ${ROOTFS} /

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
