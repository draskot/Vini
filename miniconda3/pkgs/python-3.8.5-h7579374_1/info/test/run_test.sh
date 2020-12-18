

set -ex



python -V
python3 -V
2to3 -h
pydoc -h
python3-config --help
python -c "import sysconfig; print(sysconfig.get_config_var('CC'))"
_CONDA_PYTHON_SYSCONFIGDATA_NAME=_sysconfigdata_x86_64_conda_cos6_linux_gnu python -c "import sysconfig; print(sysconfig.get_config_var('CC'))"
for f in ${CONDA_PREFIX}/lib/python*/_sysconfig*.py; do echo "Checking $f:"; if [[ `rg @ $f` ]]; then echo "FAILED ON $f"; cat $f; exit 1; fi; done
pushd tests
pushd distutils
python setup.py install -v -v
python -c "import foobar"
popd
pushd distutils.cext
python setup.py install -v -v
python -v -v -v -c "import greet"
python -v -v -v -c "import greet; greet.greet('Python user')" | rg "Hello Python"
popd
pushd prefix-replacement
bash build-and-test.sh
popd
pushd processpoolexecutor-max_workers-61
python ppe.py
popd
pushd cmake
export CMAKE_DBG=
cmake -GNinja -DPY_VER=3.8.5 -DPython_ROOT_DIR=${PREFIX} ${CMAKE_DBG} .
popd
popd
exit 0
