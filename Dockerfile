FROM condaforge/miniforge3:4.9.2-5

EXPOSE 8080 8081 8082 8083 8084 8085

ARG USERNAME=default
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Conda
ARG CONDA_ENV_NAME=default

RUN apt-get update \
  && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
  #
  # More apt deps
  && apt-get install -y --no-install-recommends \
  sudo \
  curl \
  vim \
  fuse \
  build-essential \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/* \
  #
  # Azure CLI
  && curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Create a non-root user to use if preferred
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && echo "chmod" \
  && chmod 0440 /etc/sudoers.d/$USERNAME
  
COPY environment.yaml /tmp/environment.yaml

RUN conda env create -f /tmp/environment.yaml

RUN rm /tmp/environment.yaml \
  && conda run -n $CONDA_ENV_NAME python -m ipykernel install --name $CONDA_ENV_NAME
  # && chown default /opt/miniconda/envs/$CONDA_ENV_NAME

# Add flake8 path to environment
# RUN export $PATH="/home/$USERNAME/.local/bin:$PATH"

ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/London"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  fzf \
  ripgrep \
  tree \
  git-all \
  xclip \
  tzdata

# Setup bash
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Setup neovim
WORKDIR /root/TMP
RUN curl -LJO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.deb
RUN apt-get install ./nvim-linux64.deb

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs
RUN npm install tree-sitter-cli 
RUN npm install -g neovim
RUN pip install pynvim pyright prettier black flake8
RUN apt-get install yadm
RUN export PATH=$PATH:/home/$USERNAME/.local/bin
RUN apt-get install unzip
# RUN apt-get install lua-language-server

RUN mkdir -p /home/$USERNAME/.config/nvim
RUN git clone https://github.com/a-noakes/nvim-lua.git /home/$USERNAME/.config/nvim
RUN git clone --depth 1 https://github.com/wbthomason/packer.nvim \
 /home/$USERNAME/.local/share/nvim/site/pack/packer/start/packer.nvim

ENV DEBIAN_FRONTEND="interactive"

RUN chown -R $USERNAME /home/$USERNAME
# RUN chmod 2775 /home/$USERNAME

RUN rm -rf /root/TMP



WORKDIR /root
RUN conda init bash \
  && conda config --set auto_activate_base false \
  && echo "conda activate $CONDA_ENV_NAME" >> ~/.bashrc

# install neovim packages

# Install Tree-Sitter languages


USER $USERNAME

RUN yes '' | nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
# RUN yes '' | nvim --headless -c 'autocmd User PackerComplete quitall' -c 'TSinstall'

# RUN chown -R $USERNAME /home/$USERNAME/.local/share/nvim
# WORKDIR /home/$USERNAME/.local/share/nvim
# RUN git clone https://github.com/tree-sitter/tree-sitter-python.git \
#   && git clone https://github.com/DerekStride/tree-sitter-sql.git
  # && git clone https://github.com/camdencheek/tree-sitter-dockerfile.git



WORKDIR /home/workspace

ENV DEBIAN_FRONTEND=dialog

