FROM ubuntu:18.04

# Prevent tzdata apt-get installation from asking for input.
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install clang-format cloc cmake cppcheck doxygen g++ git graphviz \
        libpcap-dev lcov mpich python3-pip qt5-default valgrind vim-common tzdata \
        autoconf automake libtool perl && \
    apt-get -y autoremove && \
    apt-get clean all

RUN pip3 install --force-reinstall pip==9.0.3 && \
    pip3 install conan==1.12.0 coverage==4.4.2 flake8==3.5.0 gcovr==3.4 && \
    rm -rf /root/.cache/pip/*

ENV CONAN_USER_HOME=/conan

RUN mkdir $CONAN_USER_HOME && \
    conan

COPY files/registry.json $CONAN_USER_HOME/.conan/

COPY files/default_profile $CONAN_USER_HOME/.conan/profiles/default

RUN conan install cmake_installer/3.10.0@conan/stable

RUN git clone https://github.com/ess-dmsc/build-utils.git && \
    cd build-utils && \
    git checkout c05ed046dd273a2b9090d41048d62b7d1ea6cdf3 && \
    make install

RUN adduser --disabled-password --gecos "" jenkins

RUN chown -R jenkins $CONAN_USER_HOME/.conan

USER jenkins

WORKDIR /home/jenkins
