

set -ex



sqlite3 --version
test -f $PREFIX/lib/libsqlite3${SHLIB_EXT}
test -f $PREFIX/include/sqlite3.h
exit 0
