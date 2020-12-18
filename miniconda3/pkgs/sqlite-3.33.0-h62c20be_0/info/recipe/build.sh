#!/bin/bash

# Prevent running ldconfig when cross-compiling.
if [[ "${BUILD}" != "${HOST}" ]]; then
  echo "#!/usr/bin/env bash" > ldconfig
  chmod +x ldconfig
  export PATH=${PWD}:$PATH
fi

function configure_it() {
  export CPPFLAGS="${CPPFLAGS} -DSQLITE_ENABLE_COLUMN_METADATA=1  \
                               -DSQLITE_ENABLE_UNLOCK_NOTIFY  \
                               -DSQLITE_ENABLE_DBSTAT_VTAB=1  \
                               -DSQLITE_ENABLE_FTS3_TOKENIZER=1  \
                               -DSQLITE_SECURE_DELETE  \
                               -DSQLITE_MAX_VARIABLE_NUMBER=250000  \
                               -DSQLITE_MAX_EXPR_DEPTH=10000  \
                               -DSQLITE_MAX_DEFAULT_PAGE_SIZE=32768  \
                               -DSQLITE_ENABLE_GEOPOLY  \
                               -DSQLITE_ENABLE_JSON1  \
                               -DSQLITE_ENABLE_FTS3  \
                               -DSQLITE_ENABLE_FTS4  \
                               -DSQLITE_ENABLE_FTS5  \
                               -DSQLITE_ENABLE_RTREE=1"
  ./configure --prefix=${PREFIX} \
              --build=${BUILD} \
              --host=${HOST} \
              --enable-threadsafe \
              --enable-shared=yes \
              --disable-readline \
              --enable-editline \
              --enable-fts3 \
              --enable-fts4 \
              --enable-fts5 \
              --enable-rtree \
              --enable-json1 \
              CFLAGS="${CFLAGS} -I${PREFIX}/include" \
              LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"
}

BUILD_SHOUD_FAIL=no
# Allow for non-from-real-source builds on Unix
if [[ -d src ]]; then
  pushd src
    configure_it
    make -j${CPU_COUNT} sqlite3.c 2>&1 | tee sqlite3.c.log
    if [[ $? != 0 ]]; then
      echo "Failed to build sqlite3.c, see ${PWD}/sqlite3.c.log"
      exit 1
    fi
    echo "Built sqlite3.c"
    # We would like to use this, but it's proprietary and in a private repo.
    # ./multitest.tcl -q --jobs ${CPU_COUNT}
  popd

  # Make the patch, writing it *back to the recipe* but with a .tmp extension. It is expected the maintainer checks
  # this and if it looks good, overwrites the amalgamated patch before submitting a PR. In-fact, if the amalgamated
  # patch differs in anything but timestamps then this build exits with an error (at the very end so we still get
  # build feedback for the full build).
  set -x
  echo "MAINTAINER INFO :: The from-real-sources patchset created the following amalgamated patch to sqlite3.c:"
  # Having trouble with --label DIFFS, we end up with timestamp diffs between the final patches so copy attribs of
  # one to the other.
  touch -r amalgamated/sqlite3.c src/sqlite3.c
  diff -burN amalgamated/sqlite3.c src/sqlite3.c 2>&1 | tee ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch.tmp
  echo "MAINTAINER INFO :: EOF"
  touch -r ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch.tmp
  if ! diff -burN ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch.tmp; then
     BUILD_SHOULD_FAIL=yes
  fi
fi

pushd amalgamated
  # Did we also have the full source and did we make a new patch from it? If so apply that now.
  if [[ -f ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch.tmp ]]; then
    patch -p1 --binary -i ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch.tmp
  fi
  configure_it
  make -j${CPU_COUNT} ${VERBOSE_AT}
  make check
  make install
popd

if [[ ${BUILD_SHOULD_FAIL} == yes ]]; then
  echo "MAINTAINER ERROR :: The patchset applied to the from-real-sources build caused a final,"
  echo "MAINTAINER ERROR :: different difference to the amalgamated sqlite3.c source file, when"
  echo "MAINTAINER ERROR :: compared to the one currently contained in this recipe."
  echo "MAINTAINER ERROR ::"
  echo "MAINTAINER ERROR :: Please review carefully review the contents of the old file:"
  cat ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch
  echo "MAINTAINER ERROR :: .. against those of the new file:"
  cat ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch.tmp
  echo "MAINTAINER ERROR :: .. and resolve if everything looks good. In particular a sudden"
  echo "MAINTAINER ERROR :: loss of a patched block with a corresponding removal of a patch"
  echo "MAINTAINER ERROR :: from patches/rebased would likely indicate a serious problem."
  echo "MAINTAINER ERROR ::"
  echo "MAINTAINER ERROR :: Here is a diff between the two patch files:"
  diff -burN ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch.tmp
  echo "MAINTAINER ERROR :: EOF"
  exit 1
else
  if [[ -f ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch.tmp ]]; then
    rm ${RECIPE_DIR}/patches/applicable-to-amalgamated/0000-sqlite3-c-amalgamated.patch.tmp
  fi
fi

# We can remove this when we start using the new conda-build.
find $PREFIX -name '*.la' -delete
