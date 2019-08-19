ARG CUDA_TAG=9.2
ARG OS_TAG=18.04
ARG NPROC=1
FROM nvidia/cuda:${CUDA_TAG}-devel-ubuntu${OS_TAG}
LABEL maintainer="simone.gasparini@gmail.com"

# use CUDA_TAG to select the image version to use
# see https://hub.docker.com/r/nvidia/cuda/
#
# CUDA_TAG=8.0-devel
# docker build --build-arg CUDA_TAG=$CUDA_TAG --tag svd3:$CUDA_TAG .
#
# then execute with nvidia docker (https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0))
# docker run -it --runtime=nvidia svd3


# OS/Version (FILE): cat /etc/issue.net
# Cuda version (ENV): $CUDA_VERSION

# Install all compilation tools
RUN apt-get clean && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        wget \
        unzip \
        yasm \
        pkg-config \
        libtool \
        nasm \
        automake \
        libgmp-dev \
        libmpfr-dev \
        libbz2-dev  \
        libgl1-mesa-dev \mesa-common-dev \
        libxv-dev  \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-good1.0-dev \
        libgtk2.0-dev \
        gfortran

RUN rm -rf /var/lib/apt/lists/*

# Manually install cmake 3.14
WORKDIR /tmp/cmake
RUN wget https://cmake.org/files/v3.14/cmake-3.14.5.tar.gz && \
    tar zxvf cmake-3.14.5.tar.gz && \
    cd cmake-3.14.5 && \
    ./bootstrap --prefix=/usr/local  -- -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_USE_OPENSSL:BOOL=ON && \
    make -j2 install && \
    cd tmp && \
    rm -rf cmake


WORKDIR /tmp/qt
ENV QT_VERSION_A=5.12
ENV QT_VERSION_B=5.12.4
ENV QT_VERSION_SCRIPT=5124
COPY qt-noninteractive.qs /tmp/qt/
RUN wget https://download.qt.io/archive/qt/${QT_VERSION_A}/${QT_VERSION_B}/qt-opensource-linux-x64-${QT_VERSION_B}.run && \
    chmod +x qt-opensource-linux-x64-${QT_VERSION_B}.run && \
    ./qt-opensource-linux-x64-${QT_VERSION_B}.run --script qt-noninteractive.qs  --platform minimal && \
    rm ./qt-opensource-linux-x64-${QT_VERSION_B}.run


ENV DEP_DEV=/opt/eesepDependencies \
    DEP_BUILD=/tmp/eesepDependencies_build \
    DEP_INSTALL=/opt/

COPY CMakeLists.txt "${DEP_DEV}"/CMakeLists.txt

WORKDIR "${DEP_BUILD}"
RUN cmake "${DEP_DEV}" -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX:PATH="${DEP_INSTALL}" \
        -DEESEP_BUILD_ZLIB:BOOL=ON \
        -DEESEP_BUILD_OPENCV:BOOL=ON \
        -DEESEP_BUILD_ALICEVISION:BOOL=OFF

RUN make VERBOSE=1

RUN rm -rf "${DEP_BUILD}"


#
#ENV SVD3_DEV=/opt/svd3_git \
#    SVD3_BUILD=/tmp/svd3_build \
#    SVD3_INSTALL=/opt/svd3
#
#COPY . "${SVD3_DEV}"
#
#WORKDIR "${SVD3_BUILD}"
#RUN cmake "${SVD3_DEV}" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS:BOOL=ON -DCMAKE_INSTALL_PREFIX="${SVD3_INSTALL}"
#
#WORKDIR "${SVD3_BUILD}"
#RUN make -j${NPROC} install
# && cd /opt && rm -rf "${SVD3_BUILD}"
