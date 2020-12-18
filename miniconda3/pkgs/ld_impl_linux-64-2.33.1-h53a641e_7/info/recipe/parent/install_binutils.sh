#!/bin/bash

set -e

cd build

make install-strip

# Remove hardlinks and replace them by softlinks
for tool in addr2line ar as c++filt dwp elfedit gprof ld ld.bfd ld.gold nm objcopy objdump ranlib readelf size strings strip; do
  rm -rf $PREFIX/$HOST/bin/$tool
  ln -s $PREFIX/bin/$HOST-$tool $PREFIX/$HOST/bin/$tool || true;
done
