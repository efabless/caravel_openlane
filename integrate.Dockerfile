# Copyright 2022 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG OPENLANE_BASE_IMAGE_NAME="efabless/openlane:latest"
FROM ${OPENLANE_BASE_IMAGE_NAME}

RUN yum groupinstall -y 'Development Tools'
RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-8 devtoolset-8-libatomic-devel

# 1. PDK
ENV PDK_ROOT /build/pdk

ADD ./pdk.tar.gz /

# 2. Icarus Verilog
RUN yum install -y readline-devel flex bison gperf autoconf
WORKDIR /iverilog
RUN curl -L https://github.com/steveicarus/iverilog/tarball/668f9850bc74c49842302891d63d7d42058e4a11\
    | tar -xzC . --strip-components=1 &&\
    sh autoconf.sh &&\
    ./configure &&\
    make -j$(nproc) &&\
    make install &&\
    rm -rf *

# 3. OpenSTA
ENV CC=/opt/rh/devtoolset-8/root/usr/bin/gcc \
    CPP=/opt/rh/devtoolset-8/root/usr/bin/cpp \
    CXX=/opt/rh/devtoolset-8/root/usr/bin/g++ \
    PATH=/opt/rh/devtoolset-8/root/usr/bin:$PATH \
    LD_LIBRARY_PATH=/opt/rh/devtoolset-8/root/usr/lib64:/opt/rh/devtoolset-8/root/usr/lib:/opt/rh/devtoolset-8/root/usr/lib64/dyninst:/opt/rh/devtoolset-8/root/usr/lib/dyninst:/opt/rh/devtoolset-8/root/usr/lib64:/opt/rh/devtoolset-8/root/usr/lib:$LD_LIBRARY_PATH
RUN python3 -m pip install cmake
RUN yum remove -y swig
RUN yum install -y swig3 bison flex tcl-devel tk-devel
WORKDIR /OpenSTA
RUN curl -L https://github.com/The-OpenROAD-Project/OpenSTA/tarball/104f90089a0e4427e1fa03d59a583e7414fbbb20\
    | tar -xzC . --strip-components=1 &&\
    mkdir ./build &&\
    cd ./build &&\
    cmake .. &&\
    make -j$(nproc) &&\
    make install &&\
    cd .. &&\
    rm -rf *

# 4. Tachyon CVC
WORKDIR /tachyon-cvc
RUN curl -L https://github.com/cambridgehackers/open-src-cvc/tarball/5ba57db51ccc70ce7ecae906e80f9037091a0f9c | tar -xzC . --strip-components=1 &&\
    cd src &&\
    make -f makefile.cvc64 -j$(nproc) &&\
    cp cvc64 /usr/bin/tachyon-cvc &&\
    cd .. &&\
    rm -rf *

# 5. RISC-V
WORKDIR /riscv
RUN curl -L https://static.dev.sifive.com/dev-tools/freedom-tools/v2020.12/riscv64-unknown-elf-toolchain-10.2.0-2020.12.8-x86_64-linux-centos6.tar.gz\
    | tar -xzC . --strip-components=1

ENV PATH "/riscv/bin:${PATH}"

# Done.

WORKDIR /

