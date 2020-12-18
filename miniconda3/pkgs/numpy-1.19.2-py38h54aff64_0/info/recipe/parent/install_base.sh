#!/bin/bash

set -e

# site.cfg is provided by blas devel packages (either mkl-devel or openblas-devel)
cp $PREFIX/site.cfg site.cfg

${PYTHON} -m pip install --no-deps --ignore-installed -v .
