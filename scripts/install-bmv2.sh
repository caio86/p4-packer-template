#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

BMV2_REPO="https://github.com/p4lang/behavioral-model.git"
BMV2_COMMIT="0bf80968bbd533e5bb58f849743001ae8221b715"

PI_REPO="https://github.com/p4lang/PI.git"
PI_COMMIT="04bf8ac8a0c00cd8a663f1f936fdaadc8b7a658c"

apt-get update

apt-get install -y \
  autoconf \
  automake \
  bison \
  build-essential \
  ca-certificates \
  cmake \
  flex \
  git \
  libboost-dev \
  libboost-filesystem-dev \
  libboost-program-options-dev \
  libboost-system-dev \
  libboost-thread-dev \
  libevent-dev \
  libgmp-dev \
  libgrpc++-dev \
  libgrpc-dev \
  libpcap-dev \
  libprotobuf-dev \
  libreadline-dev \
  libssl-dev \
  libtool \
  libtool-bin \
  pkg-config \
  libxxhash-dev \
  libjsoncpp-dev \
  protobuf-compiler \
  protobuf-compiler-grpc

rm -rf /usr/local/src/PI /usr/local/src/behavioral-model
mkdir -p /usr/local/src

# ---------------------------------------------------------------------------
# PI: P4Runtime support
# ---------------------------------------------------------------------------
git clone --recursive "$PI_REPO" /usr/local/src/PI
git -C /usr/local/src/PI checkout "$PI_COMMIT"
git -C /usr/local/src/PI submodule update --init --recursive

cd /usr/local/src/PI
./autogen.sh
./configure \
  --with-proto \
  --without-internal-rpc \
  --without-cli \
  --without-bmv2

make -j"$(nproc)"
make install

# ---------------------------------------------------------------------------
# BMv2 simple_switch_grpc
# ---------------------------------------------------------------------------
git clone --recursive "$BMV2_REPO" /usr/local/src/behavioral-model
git -C /usr/local/src/behavioral-model checkout "$BMV2_COMMIT"
git -C /usr/local/src/behavioral-model submodule update --init --recursive

cd /usr/local/src/behavioral-model
./autogen.sh

./configure \
  --with-pi \
  --without-thrift \
  --without-nanomsg \
  CXXFLAGS="-O2"

make -j"$(nproc)"
make install-strip

ldconfig

/usr/local/bin/simple_switch_grpc --help >/dev/null
