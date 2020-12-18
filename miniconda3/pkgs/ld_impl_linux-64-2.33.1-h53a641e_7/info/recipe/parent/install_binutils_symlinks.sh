#!/bin/bash

CHOST="${ctng_cpu_arch}-${ctng_vendor}-linux-gnu"

for tool in addr2line ar as c++filt dwp elfedit gprof ld ld.bfd ld.gold nm objcopy objdump ranlib readelf size strings strip; do
  rm $PREFIX/bin/$CHOST-$tool
  touch $PREFIX/bin/$CHOST-$tool
  ln -s $PREFIX/bin/$CHOST-$tool $PREFIX/bin/$tool
done

ln -s "$PREFIX/bin/ld.gold" "$PREFIX/bin/gold"
