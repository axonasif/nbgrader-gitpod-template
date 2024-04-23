# Image source code: https://github.com/axonasif/workspace-images/tree/tmp
# Also see https://github.com/gitpod-io/workspace-images/issues/1071
FROM axonasif/workspace-python@sha256:f5ba627a31505ea6cf100abe8e552d7ff9e0abd6ba46745b6d6dab349c001430

# Set user
USER gitpod

# Install Miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py311_24.1.2-0-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p $HOME/miniconda && \
    rm ~/miniconda.sh

# Add Miniconda to PATH
ENV PATH="$HOME/miniconda/bin:$PATH"

# Initialize conda in bash config files:
RUN conda init bash

# Set up Conda channels
RUN conda config --add channels conda-forge && \
    conda config --add channels bioconda && \
    conda config --set channel_priority strict

# Set libmamba as solver
RUN conda config --set solver libmamba

# Persist ~/miniconda
RUN echo 'create-overlay $HOME/miniconda' > "$HOME/.runonce/1-miniconda"

# Persist ~/.condarc
RUN echo 'create-overlay $HOME/.condarc' > "$HOME/.runonce/2-condarc"

# Persist /lib
RUN echo 'create-overlay /lib' > "$HOME/.runonce/3-lib"

# Persist .bashrc
RUN echo 'create-overlay $HOME/.bashrc' > "$HOME/.runonce/4-bashrc"


# Remove the undesired default Python location from PATH
RUN export PATH=$(echo $PATH | tr ':' '\n' | grep -v '/home/gitpod/.pyenv/shims' | tr '\n' ':')
