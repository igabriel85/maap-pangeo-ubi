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

# set user as the owner of /opt
RUN chown -R 1234:0 /opt && \
    chmod -R g=u /opt

# Set CONDA environment variables
ENV CONDA_DIR /opt/conda
ENV CONDA_ENV pymaap


# Appending to PATH conda and conda env
ENV PATH "$PATH:$CONDA_DIR/envs/pymaap/bin"
ENV PATH "$PATH:$CONDA_DIR/bin"

# All env vars that reference other env vars need to be in their own ENV block
# Path to the python environment where the jupyter notebook packages are installed
ENV NB_PYTHON_PREFIX=${CONDA_DIR}/envs/${CONDA_ENV} \
    # Home directory of our non-root user
    HOME=/home/user

USER 1234
#ENV HOME=/home/user
WORKDIR ${HOME}

# Miniconda install
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    bash ~/miniconda.sh -b -p $CONDA_DIR && rm ~/miniconda.sh

#install conda lock
RUN conda install -y -c conda-forge conda-lock && \
    conda clean -afy

ONBUILD USER 0

ONBUILD COPY --chown=user:user . /home/user

# Install apt packages specified in a apt.txt file if it exists.
ONBUILD RUN echo "Checking for 'pkg.txt'..." \
        ; [ -d binder ] && cd binder \
        ; [ -d .binder ] && cd .binder \
        ; if test -f "pkg.txt" ; then \
        # Read pkg.txt line by line, and execute dnf install -y for each line in pkg.txt
        xargs -a pkg.txt dnf install -y \
        && dnf clean all \
        ; fi

# If a jupyter_notebook_config.py exists, copy it to /etc/jupyter so
# it will be read by jupyter processes when they start. This feature is
# not available in repo2docker.
ONBUILD RUN echo "Checking for 'jupyter_notebook_config.py'..." \
        ; [ -d binder ] && cd binder \
        ; [ -d .binder ] && cd .binder \
        ; if test -f "jupyter_notebook_config.py" ; then \
        mkdir -p /etc/jupyter \
        && cp jupyter_notebook_config.py /etc/jupyter \
        ; fi

ONBUILD USER 1234

# We want to keep our images as reproducible as possible. If a lock
# file with exact versions of all required packages is present, we use
# it to install packages. conda-lock (https://github.com/conda-incubator/conda-lock)
# is used to generate this conda-lock.yml file from a given environment.yml
# file - so we get the exact same versions each time the image is built. Note that
# different packages may be used for different CPU architectures, but still,
# the same dockerfile can be used to build different architecture images. This
# also lets us see what packages have changed between two images by diffing
# the contents of the lock file between those image versions.
# If a lock file is not present, we use the environment.yml file. And
# if that is also not present, we use the pangeo-notebook conda-forge
# package (https://anaconda.org/conda-forge/pangeo-notebook) to install
# a list of base packages.
# After installing the packages, we cleanup some unnecessary files
# to try reduce image size - see https://jcristharif.com/conda-docker-tips.html
ONBUILD RUN echo "Checking for 'conda-lock.yml' or 'environment.yml'..." \
        ; [ -d binder ] && cd binder \
        ; [ -d .binder ] && cd .binder \
        ; if test -f "conda-lock.yml" ; then echo "Using conda-lock.yml" & \
        conda-lock install --name ${CONDA_ENV} \
        ; elif test -f "environment.yml" ; then echo "Using environment.yml" & \
        mamba env create --name ${CONDA_ENV} -f environment.yml  \
        ; else echo "No conda-lock.yml or environment.yml! *creating default env*" ; \
        mamba create --name ${CONDA_ENV} pangeo-notebook \
        ; fi \
        && mamba clean -yaf \
        && find ${CONDA_DIR} -follow -type f -name '*.a' -delete \
        && find ${CONDA_DIR} -follow -type f -name '*.js.map' -delete \
        ; if ls ${NB_PYTHON_PREFIX}/lib/python*/site-packages/bokeh/server/static > /dev/null 2>&1; then \
        find ${NB_PYTHON_PREFIX}/lib/python*/site-packages/bokeh/server/static -follow -type f -name '*.js' ! -name '*.min.js' -delete \
        ; fi

# If a requirements.txt file exists, use pip to install packages
# listed there. We don't want to save cached wheels in the image
# to avoid wasting space.
ONBUILD RUN echo "Checking for pip 'requirements.txt'..." \
        ; [ -d binder ] && cd binder \
        ; [ -d .binder ] && cd .binder \
        ; if test -f "requirements.txt" ; then \
        ${NB_PYTHON_PREFIX}/bin/pip install --no-cache -r requirements.txt \
        ; fi

# If a postBuild file exists, run it!
# After it's done, we try to remove any possible cruft commands there
# leave behind under $HOME - particularly stuff that jupyterlab extensions
# leave behind.
ONBUILD RUN echo "Checking for 'postBuild'..." \
        ; [ -d binder ] && cd binder \
        ; [ -d .binder ] && cd .binder \
        ; if test -f "postBuild" ; then \
        chmod +x postBuild \
        && ./postBuild \
        && rm -rf /tmp/* \
        && rm -rf ${HOME}/.cache ${HOME}/.npm ${HOME}/.yarn \
        && rm -rf ${NB_PYTHON_PREFIX}/share/jupyter/lab/staging \
        && find ${CONDA_DIR} -follow -type f -name '*.a' -delete \
        && find ${CONDA_DIR} -follow -type f -name '*.js.map' -delete \
        ; fi

# If a start file exists, put that under /srv/start. Used in the
# same way as a start file in repo2docker.
ONBUILD RUN echo "Checking for 'start'..." \
        ; [ -d binder ] && cd binder \
        ; [ -d .binder ] && cd .binder \
        ; if test -f "start" ; then \
        chmod +x start \
        && cp start /srv/start \
        ; fi


CMD ["/bin/bash"]

# use conda env
RUN echo "source activate pymaap" > ~/.bashrc

ENTRYPOINT ["/entrypoint.sh" ]
