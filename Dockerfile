FROM ubuntu:20.04

# Prevent tzdata apt-get installation from asking for input.
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install clang-format cloc doxygen gcc g++ git graphviz \
        flex lcov mpich python3-pip qt5-default valgrind vim-common tzdata \
        autoconf automake libtool perl ninja-build curl libssl-dev libreadline-dev && \
    apt-get -y autoremove && \
    apt-get clean all

RUN curl -LO https://github.com/Kitware/CMake/releases/download/v3.17.3/cmake-3.17.3.tar.gz && \
    tar xf cmake-3.17.3.tar.gz && \
    cd cmake-3.17.3 && \
    ./bootstrap && make -j8 && make install

RUN pip3 install conan==1.47.0 coverage==4.4.2 flake8==3.5.0 gcovr==4.1 && \
    rm -rf /root/.cache/pip/*

ENV CONAN_USER_HOME=/conan

RUN mkdir $CONAN_USER_HOME && \
    conan

RUN git clone http://github.com/ess-dmsc/conan-configuration.git && \
    cd conan-configuration && \
    git checkout 126940cf54a8a0181d46f93f8aa733543cbac359 && \
    cd .. && \
    conan config install conan-configuration

COPY files/default_profile $CONAN_USER_HOME/.conan/profiles/default

RUN cd /tmp && \
    curl -o cppcheck.tar.gz -L https://github.com/danmar/cppcheck/archive/2.7.tar.gz && \
    tar xf cppcheck.tar.gz && \
    cd cppcheck-2.7 && \
    mkdir build && \
    cd build && \
    sed -i "s|LIST(GET VERSION_PARTS 2 VERSION_PATCH)|  |g" ../cmake/versions.cmake && \
    cmake .. && \
    make -j8 && make install && \
    cd ../.. && \
    rm -rf cppcheck-2.7 && \
    rm -rf cppcheck.tar.gz

# Workaround for Qt issue when running with an old kernel version
RUN strip --remove-section=.note.ABI-tag /lib/x86_64-linux-gnu/libQt5Core.so

RUN git clone https://github.com/ess-dmsc/build-utils.git && \
    cd build-utils && \
    git checkout c05ed046dd273a2b9090d41048d62b7d1ea6cdf3 && \
    make install

RUN adduser --disabled-password --gecos "" jenkins

RUN chown -R jenkins $CONAN_USER_HOME/.conan
RUN conan config set general.revisions_enabled=True

USER jenkins
WORKDIR /home/jenkins

RUN python3 -m pip install --user black codecov
