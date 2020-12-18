#!/bin/bash

set -e


#pushd ${BUILD_PREFIX}/bin
#  for fn in "${BUILD}-"*; do
#    new_fn=${fn//${BUILD}-/}
#    echo "Creating symlink from ${fn} to ${new_fn}"
#    ln -sf "${fn}" "${new_fn}"
#    varname=$(basename "${new_fn}" | tr a-z A-Z | sed "s/+/X/g" | sed "s/\./_/g" | sed "s/-/_/g")
#    echo "$varname $CC"
#    printf -v "$varname" "$BUILD_PREFIX/bin/${new_fn}"       
#  done
#popd

for file in ./crosstool_ng/packages/binutils/$PKG_VERSION/*.patch; do
  patch -p1 < $file;
done

mkdir build
cd build

export HOST="${ctng_cpu_arch}-${ctng_vendor}-linux-gnu"

../configure \
  --prefix="$PREFIX" \
  --target=$HOST \
  --enable-ld=default \
  --enable-gold=yes \
  --enable-plugins \
  --disable-multilib \
  --disable-sim \
  --disable-gdb \
  --disable-nls \
  --enable-default-pie \
  --with-sysroot=$PREFIX/$HOST/sysroot \

make -j${CPU_COUNT}

#exit 1
