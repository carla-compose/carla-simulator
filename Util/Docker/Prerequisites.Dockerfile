FROM nvidia/cuda:11.3.1-runtime-ubuntu20.04 
# TODO: Change to 22.04

USER root

ARG EPIC_USER=christiangeller
ARG EPIC_PASS=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
ENV DEBIAN_FRONTEND=noninteractive

# TODO: DELETE
RUN echo $EPIC_USER
RUN echo $EPIC_PASS

# Install dependencies
RUN apt-get update ; \
  apt-get install -y wget software-properties-common && \
  add-apt-repository ppa:ubuntu-toolchain-r/test && \
  add-apt-repository ppa:deadsnakes/ppa && \  # add newer Python version
  apt-get update ; \
  apt-get install -y build-essential \
    libglvnd-dev \
    clang-8 \
    lld-8 \
    g++-7 \
    cmake \
    ninja-build \
    libvulkan1 \
    libvulkan-dev \
    vulkan-tools \
    python3.10 \
    python3.10-dev \
    python3.10-pip \
    python3.10-distutils \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    tzdata \
    sed \
    curl \
    unzip \
    autoconf \
    libtool \
    rsync \
    libxml2-dev \
    git \
    nano \
    aria2

# Install Python Packages
RUN pip3.10 install -Iv setuptools==47.3.1 && \
  pip3.10 install distro && \
  pip3.10 install pygame && \
  pip3.10 install numpy

# Set Alternatives and Defaults
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
  update-alternatives --set python3 /usr/bin/python3.10 && \
update-alternatives --install /usr/bin/clang++ clang++ /usr/lib/llvm-8/bin/clang++ 180 && \
  update-alternatives --install /usr/bin/clang clang /usr/lib/llvm-8/bin/clang 180

# Enable Vulkan support for NVIDIA GPUs
RUN apt-get update && apt-get install -y --no-install-recommends libvulkan1 && \
      rm -rf /var/lib/apt/lists/* && \
      VULKAN_API_VERSION=`dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9|\.]+'` && \
      mkdir -p /etc/vulkan/icd.d/ && \
      echo \
      "{\
        \"file_format_version\" : \"1.0.0\",\
        \"ICD\": {\
          \"library_path\": \"libGLX_nvidia.so.0\",\
          \"api_version\" : \"${VULKAN_API_VERSION}\"\
        }\
      }" > /etc/vulkan/icd.d/nvidia_icd.json

# Setup carla and UnrealEngine
RUN useradd -m carla && echo "carla:carla" | chpasswd && adduser carla sudo
COPY --chown=carla:carla . /home/carla
USER carla
WORKDIR /home/carla
ENV UE4_ROOT /home/carla/UE4.26

RUN git clone --depth 1 -b carla "https://${EPIC_USER}:${EPIC_PASS}@github.com/CarlaUnreal/UnrealEngine.git" ${UE4_ROOT}

RUN cd $UE4_ROOT && \
  ./Setup.sh && \
  ./GenerateProjectFiles.sh && \
  make

WORKDIR /home/carla/
