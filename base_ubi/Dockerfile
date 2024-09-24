#FROM redhat/ubi9-minimal
FROM registry.access.redhat.com/ubi9/ubi-init

LABEL maintainer="Red Hat, Inc."

LABEL com.redhat.component="ubi9-init"
LABEL name="ubi9/ubi9-init"
LABEL version="9.4"
LABEL modifide="2021-09-24"
LABEL modified_by="Gabriel Iuhasz"

#label for EULA
LABEL com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI"

#labels for container catalog
LABEL summary="Provides the latest release of the Red Hat Universal Base Image 9 Init for multi-service containers."
LABEL description="The Universal Base Image Init is designed is designed to run an init system as PID 1 for running multi-services inside a container. This base image is freely redistributable, but Red Hat only supports Red Hat technologies through subscriptions for Red Hat products. This image is maintained by Red Hat and updated regularly."
LABEL io.k8s.display-name="Red Hat Universal Base Image 9 Init"
LABEL io.openshift.expose-services=""


ENV container oci
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


# ===============================Custom Start=========================================================================
USER 0

RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    dnf update -y && \
    dnf install -y bash diffutils git git-lfs iproute jq less lsof man nano procps p7zip p7zip-plugins \
                   perl-Digest-SHA net-tools openssh-clients rsync socat sudo time vim wget zip stow && \
                   dnf clean all

COPY --chown=0:0 entrypoint.sh /
# add user and configure it
RUN useradd -u 1234 -G wheel,root -d /home/user --shell /bin/bash -m user && \
    # Set permissions on /etc/passwd and /home to allow arbitrary users to write
    chgrp -R 0 /home && \
    chmod -R g=u /etc/passwd /etc/group /home && \
    chmod +x /entrypoint.sh

# Set CONDA environment variables
ENV CONDA_DIR /home/user/conda

# Appending to PATH conda and conda env
ENV PATH "$PATH:$CONDA_DIR/envs/pymaap/bin"
ENV PATH "$PATH:$CONDA_DIR/bin"

USER 1234
ENV HOME=/home/user

# Miniconda install
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    bash ~/miniconda.sh -b -p $CONDA_DIR && rm ~/miniconda.sh





CMD ["/bin/bash"]

ENTRYPOINT ["/entrypoint.sh" ]
