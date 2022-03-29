FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386
RUN apt-get update && apt-get -o APT::Immediate-Configure=0 install -y \
    virtualenvwrapper python3-dev python3-pip build-essential libxml2-dev \
    libxslt1-dev git libffi-dev cmake libreadline-dev libtool debootstrap \
    debian-archive-keyring libglib2.0-dev libpixman-1-dev qtdeclarative5-dev \
    binutils-multiarch nasm libc6:i386 libgcc1:i386 libstdc++6:i386 \
    libtinfo5:i386 zlib1g:i386 vim libssl-dev openjdk-8-jdk \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -s /bin/bash -m angr
USER angr

ADD . /home/angr/angr-dev
WORKDIR /home/angr/angr-dev

RUN ./setup.sh -w -e angr && ./setup.sh -w -p angr-pypy
RUN echo 'source /usr/share/virtualenvwrapper/virtualenvwrapper.sh' >> /home/angr/.bashrc && \
    echo 'workon angr' >> /home/angr/.bashrc

