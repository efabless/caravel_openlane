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

ARG SKY130_REPO
ARG SKY130_COMMIT

ENV PDK_ROOT /build/pdk

WORKDIR ${PDK_ROOT}
RUN git clone ${SKY130_REPO}    
WORKDIR ${PDK_ROOT}/skywater-pdk
RUN git checkout main &&\
    git submodule init &&\
    git pull --no-recurse-submodules &&\
    git checkout -qf ${SKY130_COMMIT}
RUN git submodule update --init libraries/sky130_fd_sc_hd/latest &&\
    git submodule update --init libraries/sky130_fd_sc_hs/latest &&\
    git submodule update --init libraries/sky130_fd_sc_hdll/latest &&\
    git submodule update --init libraries/sky130_fd_sc_ms/latest &&\
    git submodule update --init libraries/sky130_fd_sc_ls/latest &&\
    git submodule update --init libraries/sky130_fd_sc_hvl/latest &&\
    git submodule update --init libraries/sky130_fd_io/latest &&\
    git submodule update --init libraries/sky130_fd_pr/latest

RUN python3 -m pip install -e scripts/python-skywater-pdk
COPY ./corners.yml ./corners.yml
COPY ./make_timing.py ./make_timing.py
RUN python3 ./make_timing.py

ARG OPEN_PDKS_REPO
ARG OPEN_PDKS_COMMIT

WORKDIR ${PDK_ROOT}
RUN git clone ${OPEN_PDKS_REPO}
WORKDIR ${PDK_ROOT}/open_pdks
RUN curl -L ${OPEN_PDKS_REPO}/tarball/${OPEN_PDKS_COMMIT} | tar -xzC . --strip-components=1 && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install
RUN ./configure --enable-sky130-pdk=${PDK_ROOT}/skywater-pdk --enable-sram-sky130

WORKDIR ${PDK_ROOT}/open_pdks/sky130
RUN make alpha-repo xschem-repo sram-repo 2>&1 | tee /build/pdk_prereq.log
RUN make -j$(nproc) 2>&1 | tee /build/pdk.log
RUN make SHARED_PDKS_PATH=${PDK_ROOT} install

ARG MAGIC_REPO
ARG MAGIC_COMMIT
RUN printf "skywater-pdk ${SKY130_COMMIT}" > ${PDK_ROOT}/sky130A/SOURCES
RUN printf "magic ${MAGIC_COMMIT}" >> ${PDK_ROOT}/sky130A/SOURCES
RUN printf "open_pdks ${OPEN_PDKS_COMMIT}" >> ${PDK_ROOT}/sky130A/SOURCES

RUN rm -rf ${PDK_ROOT}/skywater-pdk
RUN rm -rf ${PDK_ROOT}/open_pdks

RUN tar -c /build | gzip -1 > /build.tar.gz
