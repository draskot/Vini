#!/usr/bin/env bash
if [ -e $vini_dir/globals ]
then
    source $vini_dir/globals
fi
module purge

if  [ ! -e sourceme ]
then
    vini_dir=$HOME/Vini
    echo "Vini main directory will be set to $vini_dir" ; echo
    #read -p "Please enter your SLURM account (e.g. r2022r03-224-users):" SLURMACCT
    read -p "Please enter path for your scratch data on the high-performance storage (e.g. /scratch/IRB/$USER):" WORKDIR
    mkdir -p $WORKDIR

    echo "High Performance Storage (scratch) will be set to $WORKDIR" ; echo
    read -p "Please enter path for Vini's 3rd party software installation (e.g. /scratch/IRB/$USER/INSTALL):" INSTALL
       mkdir -p $INSTALL
    echo "Third party software will be installed in $INSTALL directory" ; echo
    SHARED=`dirname $INSTALL`
    mkdir -p $INSTALL
    echo "#************General**********" >> $vini_dir/sourceme
    echo "export vini_dir=$vini_dir"   >> $vini_dir/sourceme
    echo "export WORKDIR=$WORKDIR"     >> $vini_dir/sourceme
    echo "export SHARED=$SHARED"       >> $vini_dir/sourceme
    echo "export INSTALL=$INSTALL"     >> $vini_dir/sourceme
else
    mkdir -p $WORKDIR
    mkdir -p $INSTALL
    echo "High-performace storage (scratch) is on $WORKDIR"
    echo "Installation directory is $INSTALL"
fi

source $vini_dir/sourceme

#1. Minconda2 install
echo -n "Checking if miniconda2 is installed..."
grep miniconda2 $vini_dir/sourceme > tmp  
if  [ ! -s tmp ]
then
    echo "no. Performing cleanup. May take several minutes to finish, do not interrupt."
    rm -rf  $INSTALL/miniconda2
    unset PYTHONPATH
    echo "Please wait while downloading and installing miniconda2..."
    wget --no-check-certificate  -P $INSTALL https://repo.anaconda.com/miniconda/Miniconda2-latest-Linux-x86_64.sh
    sh $INSTALL/Miniconda2-latest-Linux-x86_64.sh -b -p $INSTALL/miniconda2
    source $INSTALL/miniconda2/etc/profile.d/conda.sh
    conda create -n env27 --yes numpy pandas requests mpi4py pyqt python=2.7
    rm $INSTALL/Miniconda2-latest-Linux-x86_64.sh
    echo "#************miniconda2 section**********" >> $vini_dir/sourceme
else
    echo "yes."
fi

# 2. Miniconda3 install
echo -n "Checking if miniconda3 is installed..."
if ! grep -q "miniconda3" "$vini_dir/sourceme" 2>/dev/null; then
    echo "no. Performing cleanup. May take several minutes to finish, do not interrupt."
    rm -rf "$INSTALL/miniconda3"
    if command -v module >/dev/null 2>&1; then
        module purge 2>/dev/null || true
    fi
    unset PYTHONPATH
    unset LD_LIBRARY_PATH

    # Option 1: Use system-provided Python-CONDA module if available
    if command -v module >/dev/null 2>&1 && module avail Python-CONDA 2>&1 | grep -q "Python-CONDA"; then
        echo "Found system Python-CONDA module. Linking it to $INSTALL/miniconda3..."
        module load Python 2>/dev/null || true
        module load Python-CONDA
        CONDA_BASE=$(conda info --base)

        mkdir -p "$INSTALL/miniconda3/envs" "$INSTALL/miniconda3/pkgs"
        ln -s "$CONDA_BASE/bin" "$INSTALL/miniconda3/bin"
        ln -s "$CONDA_BASE/etc" "$INSTALL/miniconda3/etc"
        ln -s "$CONDA_BASE/condabin" "$INSTALL/miniconda3/condabin" 2>/dev/null || true

        export CONDA_PKGS_DIRS="$INSTALL/miniconda3/pkgs"
        export CONDA_ENVS_DIRS="$INSTALL/miniconda3/envs"
    else
        # Option 2: Fall back to standalone Miniforge3 (handles both glibc < 2.28 and >= 2.28)
        ARCH=$(uname -m)
        glibc_ver=$(ldd --version 2>&1 | awk 'NR==1{print $NF}')
        glibc_num=$(echo "$glibc_ver" | awk -F. '{printf "%d%02d", $1, $2}')

        if [ -n "$glibc_num" ] && [ "$glibc_num" -lt 228 ]; then
            echo "Detected older GLIBC ($glibc_ver < 2.28). Using GLIBC 2.17-compatible Miniforge3..."
            CONDA_URL="https://github.com{ARCH}.sh"
        else
            echo "Detected modern GLIBC ($glibc_ver >= 2.28). Using latest Miniforge3..."
            CONDA_URL="https://github.com{ARCH}.sh"
        fi

        wget --no-check-certificate -O "$INSTALL/miniforge3.sh" "$CONDA_URL" || {
            echo "ERROR: Failed to download Miniforge3."
            exit 1
        }
        if ! head -n 1 "$INSTALL/miniforge3.sh" 2>/dev/null | grep -q "^#!"; then
            echo "ERROR: Downloaded file is not a valid shell script."
            rm -f "$INSTALL/miniforge3.sh"
            exit 1
        fi
        bash "$INSTALL/miniforge3.sh" -b -p "$INSTALL/miniconda3" || {
            echo "ERROR: Miniforge3 installation failed."
            rm -f "$INSTALL/miniforge3.sh"
            exit 1
        }
        rm -f "$INSTALL/miniforge3.sh"
    fi

    # Load conda via the unified $INSTALL/miniconda3 path
    . "$INSTALL/miniconda3/etc/profile.d/conda.sh"

    echo "Creating Python 3.10 environment 'env310'..."
    conda create -p "$INSTALL/miniconda3/envs/env310" --yes python=3.10 && \
    conda activate "$INSTALL/miniconda3/envs/env310" && \
    conda install -c conda-forge --yes rdkit mdanalysis pdb2pqr openbabel numpy scipy pandas requests mpi4py pyqt tqdm && \
    conda deactivate || {
        echo "ERROR: Failed to create or populate conda environment 'env310'."
        exit 1
    }

    echo "#***miniconda3 section***" >> "$vini_dir/sourceme"
else
    echo "yes."
fi

# 3. Chimera install
echo -n "Checking if UCSF Chimera is installed..."
if ! grep -q "Chimera" "$vini_dir/sourceme" 2>/dev/null; then
    echo "no."
    DEFAULT_CHIMERA="chimera-1.20-linux_x86_64"
    printf "Enter the Chimera installer name without .bin [default: %s]: " "$DEFAULT_CHIMERA"
    read chimera
    chimera=${chimera:-$DEFAULT_CHIMERA}
    # Strip trailing .bin if the user accidentally included it
    chimera=${chimera%.bin}

    echo -n "Chimera installation directory must be empty. Performing cleanup..."
    rm -rf "$INSTALL/${chimera}"
    echo "done."

    # Only prompt the user if the .bin file isn't already in $INSTALL
    while [ ! -f "$INSTALL/${chimera}.bin" ]; do
        echo ""
        echo "Please download ${chimera}.bin from https://www.cgl.ucsf.edu/chimera/download.html"
        echo "and place it into: $INSTALL"
        printf "Press Enter once ${chimera}.bin is in $INSTALL..."
        read enter
    done

    echo "Installing UCSF Chimera automatically into $INSTALL/${chimera}..."
    chmod u+x "$INSTALL/${chimera}.bin"
    (
        cd "$INSTALL" || exit 1
        # Automatically answer the 3 installer prompts:
        # 1) Install location: $INSTALL/$chimera
        # 2) Install desktop menu and icon?: no
        # 3) Symbolic link directory choice: 0 (no link)
        printf "%s\nno\n0\n" "$INSTALL/${chimera}" | "./${chimera}.bin"
    ) || {
        echo "ERROR: UCSF Chimera installation failed."
        exit 1
    }

    rm -f "$INSTALL/${chimera}.bin"

    echo "#******UCSF Chimera section******" >> "$vini_dir/sourceme"
    echo "export PATH=$INSTALL/${chimera}/bin:\$PATH" >> "$vini_dir/sourceme"

    echo ""
    echo "Chimera installation done!"
    echo "NOTE: Register Chimera at https://www.cgl.ucsf.edu/cgi-bin/chimera_registration.py so it runs without nag prompts."
    printf "Press Enter once registration is complete (or to continue)..."
    read enter
else
    echo "yes."
fi

#4. MGLTools install
echo -n "checking if MGLTools are installed..."
grep mgltools_x86_64Linux2_1.5.7 $vini_dir/sourceme > tmp #install mgltools 1.5.7
if  [ ! -s tmp ]
then
    echo "no."
    rm -rf $INSTALL/index*
    wget -P $INSTALL -q --no-check-certificate https://ccsb.scripps.edu/download/532/
    mv $INSTALL/index.html $INSTALL/mgltools_x86_64Linux2_1.5.7.tar.gz
    tar -xvzf $INSTALL/mgltools_x86_64Linux2_1.5.7.tar.gz -C $INSTALL
    cd $INSTALL/mgltools_x86_64Linux2_1.5.7
    sh $INSTALL/mgltools_x86_64Linux2_1.5.7/install.sh
    echo "#***mgltools_x86_64Linux2_1.5.7 section***" >> $vini_dir/sourceme
    echo "export MGLTOOLS=$INSTALL/mgltools_x86_64Linux2_1.5.7/MGLToolsPckgs/AutoDockTools" >> $vini_dir/sourceme
    echo "export MGLUTILS=$INSTALL/mgltools_x86_64Linux2_1.5.7/MGLToolsPckgs/AutoDockTools/Utilities24" >> $vini_dir/sourceme
    echo "export MGLBIN=$INSTALL/mgltools_x86_64Linux2_1.5.7/bin" >> $vini_dir/sourceme
    echo "export MGL=$INSTALL/mgltools_x86_64Linux2_1.5.7" >> $vini_dir/sourceme #next entries for DeltaVina
    echo "export PATH=$INSTALL/mgltools_x86_64Linux2_1.5.7/bin:\$PATH" >> $vini_dir/sourceme
    rm $INSTALL/mgltools_x86_64Linux2_1.5.7.tar.gz
else
    echo "yes."
fi

#5. Vina install
echo -n "checking if Vina is installed..."
grep Vina $vini_dir/sourceme > tmp
nolines=`wc -l < tmp`
if [ $nolines -eq $NULL ]
then
    echo "no. Installing Vina..."
    wget -O $INSTALL/vina_1.2.5_linux_x86_64 https://github.com/ccsb-scripps/AutoDock-Vina/releases/download/v1.2.5/vina_1.2.5_linux_x86_64
    mv $INSTALL/vina_1.2.5_linux_x86_64 $INSTALL/vina
    chmod u+x $INSTALL/vina
    echo "#***** Vina section******" >> $vini_dir/sourceme
    echo "export PATH=$INSTALL:\$PATH" >> $vini_dir/sourceme
else
    echo "yes."
fi

#6. Autodock4 install
echo -n "checking if Autodock4  is installed..."
grep Autodock4 $vini_dir/sourceme > tmp
nolines=`wc -l < tmp`
if [ $nolines -eq $NULL ]
then
    echo "no. Installing Autodock4..."
    mkdir -p $INSTALL/autodock4
    wget -O $INSTALL/autodocksuite-4.2.6-x86_64Linux2.tar https://autodock.scripps.edu/wp-content/uploads/sites/56/2021/10/autodocksuite-4.2.6-x86_64Linux2.tar
    tar -xvf $INSTALL/autodocksuite-4.2.6-x86_64Linux2.tar -C $INSTALL/autodock4
    echo "#***** Autodock4 section******" >> $vini_dir/sourceme
    echo "export PATH=$INSTALL/autodock4/x86_64Linux2:\$PATH" >> $vini_dir/sourceme
else
    echo "yes."
fi

#7. ADFR install
echo -n "Checking if ADFR suite is installed..."
grep ADFRsuite $vini_dir/sourceme > tmp    #install ADFRsuite1.0
if  [ ! -s tmp ]
then
    echo -n "no. Please wait while ADFR suite 1.0 is installed..."
    rm -f $INSTALL/ADFRsuite_x86_64Linux_1.0.tar.gz
    rm -rf $INSTALL/ADFRsuite_x86_64Linux_1.0
    wget -O $INSTALL/ADFRsuite_x86_64Linux_1.0.tar.gz https://ccsb.scripps.edu/adfr/download/1038/
    tar -xzf $INSTALL/ADFRsuite_x86_64Linux_1.0.tar.gz -C $INSTALL
    cd $INSTALL/ADFRsuite_x86_64Linux_1.0
    sh install.sh
    echo "#***ADFRsuite 1.0 section***" >> $vini_dir/sourceme
    echo "export PATH=$INSTALL/ADFRsuite_x86_64Linux_1.0/bin:\$PATH"  >> $vini_dir/sourceme
    rm $INSTALL/ADFRsuite_x86_64Linux_1.0.tar.gz
else
    echo "yes."
fi

#8. AlphaFold install
echo -n "Checking if AlphaFold is installed..."
grep AlphaFold $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    $vini_dir/AlphaFold_install
fi

#9 BLAST install
echo -n "Checking if Blast is installed..."
grep Blast $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    echo "no." echo -n "Checking if Blast module(s) exist on this system..."
    module spider blast &> tmp
    grep -w error tmp > blast
    if   [ ! -s blast ] #no error means module found
    then
        echo "yes"
        cat tmp
        echo "#******* Blast *******" >> $vini_dir/sourceme
        read -p "Select the Blast module:" blast
        echo "module load" $blast >> $vini_dir/sourceme
        source $vini_dir/sourceme
    else
        echo "no. Installing local Blast, please wait."
        module purge
        wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/   #get the latest blast+ version
        blast=`sed -e 's/<[^>]*>//g' index.html | grep src.tar.gz | grep -v md5 | awk '{print $1}' | rev | cut -c8- | rev`
        rm -f $INSTALL/${blast}.tar.gz
        rm -rf $INSTALL/${blast}
        link=https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/${blast}.tar.gz
        wget -P $INSTALL $link
        tar -xzf $INSTALL/${blast}.tar.gz -C $INSTALL
        cd $INSTALL/${blast}/c++
        ./configure
        cd ReleaseMT/build
        make -j 24 all_r
        echo "#***Blast section***" >> $vini_dir/sourceme
        echo "export PATH=$INSTALL/${blast}/c++/ReleaseMT/bin:\$PATH" >> $vini_dir/sourceme
        source $vini_dir/sourceme
        rm $INSTALL/${blast}.tar.gz index.html
    fi
else
    echo "yes."
fi


# 10. Rosetta install
source $vini_dir/sourceme
echo -n "Checking if Rosetta is installed..."
grep Rosetta $vini_dir/sourceme > tmp
if  [ ! -s tmp ]  #install Rosetta
then
    module spider Rosetta 2&> tmp
    grep error tmp 2&> tmp2
    if  [ -s tmp2 ]
    then
        echo "Rosetta module not exists! Will try to install local copy of Rosetta."

        if  [ ! -e $WORKDIR/Rosetta_username ] || [ ! -e $WORKDIR/Rosetta_password ]
        then
            echo "In order to run Rosetta you need to obtain license from https://els2.comotion.uw.edu/product/rosetta"
            echo "This license is free for academic users."
            #echo "Upon receiving a license, enter username and password here."
            #read -p "Enter username:" Rosetta_username
            #echo -n "Enter password:"; read -s Rosetta_password ; echo ""
            #echo $Rosetta_username > $WORKDIR/Rosetta_username
            #echo $Rosetta_password > $WORKDIR/Rosetta_password
            #chmod g-r,o-r $WORKDIR/Rosetta_username
            #chmod g-r,o-r $WORKDIR/Rosetta_password
        fi
        release=3.15
        version=408
        if  [ ! -e $INSTALL/rosetta_source_${release}_bundle.tar.bz2 ]
        then
            wget -P $INSTALL https://downloads.rosettacommons.org/downloads/academic/${release}/rosetta_source_3.15_bundle.tar.bz2
        fi
      echo "Unpacking and compiling Rosetta source, do not interrupt."
        tar -xjf "$INSTALL/rosetta_source_${release}_bundle.tar.bz2" --checkpoint=.4000 -C "$INSTALL"
        module purge
        source $INSTALL/miniconda3/bin/activate
        conda activate env310
        cd $INSTALL/rosetta.source.release-${version}/main/source
        if command -v module >/dev/null 2>&1; then
           module load gcc/13.4.0 2>/dev/null || module load gcc 2>/dev/null || true
        fi
        ./scons.py -j 4 bin mode=release extras=cxx11thread || {
            echo "ERROR: Rosetta compilation failed."
            conda deactivate
            exit 1
        }
        conda deactivate
        rm -f "$INSTALL/rosetta_source_${release}_bundle.tar.bz2"
        cd $vini_dir
        echo "module load gcc/13.4.0 2>/dev/null || module load gcc 2>/dev/null || true" >> "$vini_dir/sourceme"
        ROSETTA=$INSTALL/rosetta.source.release-${version}/main
        ROSETTA_BIN=$ROSETTA/source/bin
        ROSETTA_DB=$ROSETTA/database
        ROSETTA_TOOLS=$ROSETTA/tools/protein_tools/scripts
        ROSETTA_PUB=$ROSETTA/source/src/apps/public/relax_w_allatom_cst
    else
        echo "Found following Rosetta module(s) : "
        module spider Rosetta
        read -p "Enter  one from the list: " rosetta
        module load $rosetta
        binary_path=$(which relax.mpi.linuxgccrelease)
        ROSETTA=$(dirname "$(dirname "$(dirname "$binary_path")")")
        ROSETTA_BIN=$ROSETTA/source/bin
        ROSETTA_DB=$ROSETTA/database
        ROSETTA_TOOLS=$ROSETTA/tools/protein_tools/scripts
        ROSETTA_PUB=$ROSETTA/source/src/apps/public/relax_w_allatom_cst
        echo "module load $rosetta"  >> $vini_dir/sourceme
    fi
    echo "#********** Rosetta section ***************"                            >> $vini_dir/sourceme
    echo "export ROSETTA=$ROSETTA"                                                >> $vini_dir/sourceme
    echo "export ROSETTA_TOOLS=$ROSETTA/tools/protein_tools/scripts"              >> $vini_dir/sourceme
    echo "export ROSETTA_PUB=$ROSETTA/source/src/apps/public/relax_w_allatom_cst" >> $vini_dir/sourceme
    echo "export PATH=${ROSETTA_BIN}:\$PATH"                                      >> $vini_dir/sourceme
    echo "export PATH=${ROSETTA_DB}:\$PATH"                                       >> $vini_dir/sourceme
fi



#11. Openbabel install
#grep OpenBabel $vini_dir/sourceme > tmp
#if  [ ! -s tmp ]
#then
#    module spider Openbabel 2> tmp
#    grep -w error tmp > openbabel
#    if [ ! -s openbabel ]
#    then
#        echo "Found the following openbabel module(s):" ; cat tmp
#        read -p "Please select one of Openbabel modules found:" openbabel
#        echo "#*****OpenBabel section******" >> $vini_dir/sourceme
#        echo "module load" $openbabel >> $vini_dir/sourceme
#    else
#        echo "No Openbabel module found on this system. Installing Openbabel 3.1.1..."
#        wget -P $INSTALL https://codeload.github.com/openbabel/openbabel/tar.gz/refs/tags/openbabel-3-1-1
        
#        mv $INSTALL/openbabel-3-1-1 $INSTALL/openbabel-3-1-1.tar.gz
#        tar -xvzf $INSTALL/openbabel-3-1-1.tar.gz -C $INSTALL
#        mkdir -p $INSTALL/openbabel-openbabel-3-1-1/build
#        cd $INSTALL/openbabel-openbabel-3-1-1/build
#        rm -rf $INSTALL/openbabel-3.1.1
#        module purge
#        module spider cmake
#        read -p "Enter cmake module to load:" cmake_module
#        module load ${cmake_module}
#        module spider boost
#        read -p "Enter Boost module to load:" boost_module
#        module load ${boost_module}
#        cmake ../ -DCMAKE_INSTALL_PREFIX=$INSTALL/openbabel-3.1.1
#        make -j 4
#        make install
#        cp $INSTALL/openbabel-openbabel-3-1-1/build/lib/libcoordgen.so* $INSTALL/openbabel-3.1.1/lib
#        echo "#*****OpenBabel section******" >> $vini_dir/sourceme
#        echo "export PATH=$INSTALL/openbabel-3.1.1/bin:\$PATH" >> $vini_dir/sourceme
#        echo "module load Boost/1.76.0-GCC-10.3.0" >> $vini_dir/sourceme
#        cd $vini_dir
#        echo -n "done."
#    fi
#fi
#rm -f openbabel tmp $INSTALL/openbabel-3-1-1.tar.gz

#11. Java install
echo -n "Checking if Java is installed..."
grep Java $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    echo "no." ; echo -n "Checking if Java module(s) exist..."
    module spider Java &> tmp
    grep -w error tmp > Java
    if   [ ! -s Java ] #no error means module found
    then
        echo "yes"
        cat tmp
        echo "#******* Java section *******" >> $vini_dir/sourceme
        read -p "Select the Java module:" Java
        echo "module load $Java ">> $vini_dir/sourceme
        source $vini_dir/sourceme
    else
        echo "no."
        rm -f $INSTALL/openjdk-11.0.2_linux-x64_bin.tar.gz
        wget -P $INSTALL https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz
        gzip -df $INSTALL/openjdk-11.0.2_linux-x64_bin.tar.gz
        tar -xf $INSTALL/openjdk-11.0.2_linux-x64_bin.tar -C $INSTALL
        rm $INSTALL/openjdk-11.0.2_linux-x64_bin.tar
        echo "#******* Java section *******" >> $vini_dir/sourceme
        echo "export PATH=$INSTALL/jdk-11.0.2/bin:\$PATH" >> $vini_dir/sourceme
    fi
else
    echo "yes."
fi

#12. BCL install
echo -n "Checking if BCL is installed..."
if ! grep -q "BCL" "$vini_dir/sourceme" 2>/dev/null; then
    echo "no. BCL will be installed. Performing the cleanup, please wait."
    rm -f "$INSTALL/master.zip"
    rm -rf "$INSTALL/bcl-master"

    wget -P $INSTALL https://github.com/BCLCommons/bcl/archive/refs/heads/master.zip || {
        echo "ERROR: Failed to download BCL."
        exit 1
    }
    unzip -o -q "$INSTALL/master.zip" -d "$INSTALL" || {
        echo "ERROR: Failed to unzip BCL."
        exit 1
    }

    if command -v module >/dev/null 2>&1; then
        module purge 2>/dev/null || true
        module load cmake 2>/dev/null || module load CMake 2>/dev/null || true
        #module load gcc/13.4.0 2>/dev/null || module load gcc 2>/dev/null || module load GCC 2>/dev/null || true
        module load libGLU 2>/dev/null || true
    fi

    . "$INSTALL/miniconda2/etc/profile.d/conda.sh" 2>/dev/null || . "$INSTALL/miniconda2/bin/activate"
    (
        cd "$INSTALL/bcl-master" || exit 1
        ./scripts/build/build_cmdline.linux.sh
    ) || {
        echo "ERROR: BCL compilation failed."
        conda deactivate 2>/dev/null || true
        exit 1
    }
    conda deactivate 2>/dev/null || true

    # Bundle libbz2 and libOpenCL into an isolated BCL lib folder for runtime portability
    mkdir -p "$INSTALL/bcl-master/lib"
    if [ ! -e "$INSTALL/miniconda3/envs/env310/lib/libOpenCL.so.1" ]; then
        CONDA_PKGS_DIRS="$INSTALL/miniconda3/pkgs" "$INSTALL/miniconda3/bin/conda" install -p "$INSTALL/miniconda3/envs/env310" -c conda-forge --yes ocl-icd 2>/dev/null || true
    fi
    ln -sf "$INSTALL/miniconda3/envs/env310/lib/libbz2.so"* "$INSTALL/bcl-master/lib/" 2>/dev/null || true
    ln -sf "$INSTALL/miniconda3/envs/env310/lib/libOpenCL.so"* "$INSTALL/bcl-master/lib/" 2>/dev/null || true
    ln -sf "$INSTALL/miniconda3/pkgs/ocl-icd-"*/lib/libOpenCL.so* "$INSTALL/bcl-master/lib/" 2>/dev/null || true
    rm -f "$INSTALL/master.zip"

    echo "#******* BCL section *******" >> "$vini_dir/sourceme"
    echo "export PATH=$INSTALL/bcl-master/build/linux64_release/bin:\$PATH" >> "$vini_dir/sourceme"
    echo "export LD_LIBRARY_PATH=$INSTALL/bcl-master/lib:\$LD_LIBRARY_PATH" >> "$vini_dir/sourceme"
else
    echo "yes."
fi


#13. GD install
SOURCE_ME="$vini_dir/sourceme"
echo -n "Checking if Google Drive data (DepMap & database) is installed..."
if grep -q "#\*\*\*\*\* GD_data section \*\*\*\*\*" "$SOURCE_ME" 2>/dev/null; then
    echo "yes."
else

    # Install gdown cleanly inside VINI's env310 (avoids loading conflicting system Python/GCC modules)
    "$INSTALL/miniconda3/envs/env310/bin/pip" install --quiet --upgrade gdown || {
        echo "ERROR: Failed to install gdown in env310."
        exit 1
    }
    GDOWN_BIN="$INSTALL/miniconda3/envs/env310/bin"
    GDOWN="$GDOWN_BIN/gdown"

    echo "no. Downloading DepMap and VINI databases..."
    DATABASE_DIR="$vini_dir/database"
    DEPMAP_DIR="$vini_dir/database/DepMap"
    mkdir -p "$DEPMAP_DIR" "$DATABASE_DIR"

    echo "Downloading and extracting DepMap (319 MB)..."
    "$GDOWN" "19qjZgt9WNPFrbBir0-Ux--Yvzsh1shc7" -O "${DEPMAP_DIR}/Depmap.tar.gz" || {
        echo "ERROR: Failed to download Depmap.tar.gz from Google Drive."
        rm -f "${DEPMAP_DIR}/Depmap.tar.gz"
        exit 1
    }
    tar -xzf "${DEPMAP_DIR}/Depmap.tar.gz" -C "$DEPMAP_DIR" || {
        echo "ERROR: Failed to extract Depmap.tar.gz."
        exit 1
    }
    rm -f "${DEPMAP_DIR}/Depmap.tar.gz"

    echo "Downloading and extracting VINI database. May take several minutes, do not interrupt."
    "$GDOWN" "12tUXGOdyQV_GLUmRzsGnB7vgKrvLjZcH" -O "${DATABASE_DIR}/database.tar.bz2" || {
        echo "ERROR: Failed to download database.tar.bz2 from Google Drive."
        rm -f "${DATABASE_DIR}/database.tar.bz2"
        exit 1
    }
    tar -xjf "${DATABASE_DIR}/database.tar.bz2" -C "$DATABASE_DIR" || {
        echo "ERROR: Failed to extract database.tar.bz2."
        exit 1
    }
    rm -f "${DATABASE_DIR}/database.tar.bz2"
    echo "Done!"

    {
        echo "#***** GD_data section *****"
        echo "export DEPMAP_DIR=$DEPMAP_DIR"
        echo "export DATABASE_DIR=$DATABASE_DIR"
        echo "export PATH=\$DEPMAP_DIR/bin:\$PATH"
        echo "export PATH=$GDOWN_BIN:\$PATH"
    } >> "$SOURCE_ME"

    echo "Google Drive data installation finished."
fi

#14. MOPAC install
echo -n "Checking if MOPAC is installed..."
SOURCEME="$vini_dir/sourceme"
CHECKPOINT_STRING="#*** MOPAC section ***"
MOPAC="$INSTALL/mopac"
SCRATCH_BUILD="$INSTALL/SCRATCH_BUILD"

if [ ! -f "$SOURCEME" ] || ! grep -qF "$CHECKPOINT_STRING" "$SOURCEME"; then
    echo "no."

    # 1. Detect if a cluster module exists natively (extract module name first, verify non-empty)
    MOPAC_MODULE=""
    if command -v module >/dev/null 2>&1; then
        MOPAC_MODULE=$(module avail 2>&1 | grep -oiE "MOPAC/[A-Za-z0-9._\-]+" | head -n 1)
    fi

    if [ -n "$MOPAC_MODULE" ]; then
        echo "MOPAC cluster module detected!"
        echo "--------------------------------------------------------"
        echo "Found available cluster module: $MOPAC_MODULE"
        printf "Would you like to use this cluster module? [Y/n]: "
        read user_choice
        echo "--------------------------------------------------------"
        user_choice=$(echo "$user_choice" | tr '[:upper:]' '[:lower:]')
    else
        user_choice="n"
    fi

    # 2. Decision Loop Routing Layer
    if [ "$user_choice" = "y" ] || [ "$user_choice" = "" ] || [ "$user_choice" = "yes" ]; then
        echo "Loading cluster module layout..."
        module load "$MOPAC_MODULE" || {
            echo "ERROR: Failed to load $MOPAC_MODULE."
            exit 1
        }
        mkdir -p "$vini_dir" && touch "$SOURCEME"
        {
            echo ""
            echo "$CHECKPOINT_STRING"
            echo "module load $MOPAC_MODULE"
        } >> "$SOURCEME"
    else
        echo "Proceeding with local custom source installation..."
        if command -v module >/dev/null 2>&1; then
            module purge 2>/dev/null || true
            module load cmake/v3.31.10 2>/dev/null || module load cmake 2>/dev/null || module load CMake 2>/dev/null || true
            module load gcc/13.4.0 2>/dev/null || module load gcc 2>/dev/null || module load GCC 2>/dev/null || true
            module load LIBS/OpenBLAS 2>/dev/null || module load OpenBLAS 2>/dev/null || module load openblas 2>/dev/null || true
        fi

        mkdir -p "$MOPAC" "$SCRATCH_BUILD"
        rm -rf "$SCRATCH_BUILD"/* "$MOPAC"/*

        wget -P "$SCRATCH_BUILD" https://github.com/openmopac/mopac/archive/refs/heads/main.zip || {
            echo "ERROR: Failed to download OpenMOPAC."
            exit 1
        }
        unzip -qo "$SCRATCH_BUILD/main.zip" -d "$SCRATCH_BUILD" || {
            echo "ERROR: Failed to unzip OpenMOPAC."
            exit 1
        }

        (
            cd "$SCRATCH_BUILD/mopac-main" || exit 1
            rm -rf build && mkdir -p build && cd build || exit 1

            # Locate libopenblas.so from loaded module (LIBRARY_PATH / LD_LIBRARY_PATH) or fallback to env310
            BLAS_LIB_DIR=$(echo "$LIBRARY_PATH:$LD_LIBRARY_PATH" | tr ':' '\n' | grep -i openblas | head -n 1)
            if [ -z "$BLAS_LIB_DIR" ]; then
                BLAS_LIB_DIR="$INSTALL/miniconda3/envs/env310/lib"
            fi

            cmake .. -DCMAKE_INSTALL_PREFIX="$MOPAC" -DTESTS=OFF -DAUTO_BLAS=OFF -DMOPAC_LINK="-L${BLAS_LIB_DIR} -lopenblas" || exit 1
            make -j 4 && make install
        ) || {
            echo "ERROR: MOPAC compilation failed."
            exit 1
        }

        # Bundle runtime Fortran/OpenBLAS shared libraries into $MOPAC/lib64 so no compiler module is needed at runtime
        mkdir -p "$MOPAC/lib64"
        for lib in libgfortran.so libquadmath.so libopenblas.so; do
            found_lib=$(ldd "$MOPAC/bin/mopac" 2>/dev/null | awk -v l="$lib" '$1 ~ l {print $3}')
            if [ -n "$found_lib" ] && [ -f "$found_lib" ]; then
                cp -L "$found_lib"* "$MOPAC/lib64/" 2>/dev/null || true
            fi
        done

        # Clean up build directory and return to $vini_dir
        rm -rf "$SCRATCH_BUILD"
        cd "$vini_dir"

        mkdir -p "$vini_dir" && touch "$SOURCEME"
        {
            echo ""
            echo "$CHECKPOINT_STRING"
            echo "export PATH=$MOPAC/bin:\$PATH"
            echo "export LD_LIBRARY_PATH=$MOPAC/lib64:$MOPAC/lib:\$LD_LIBRARY_PATH"
            echo "export MOPAC_THREADS=\${SLURM_CPUS_PER_TASK:-4}"
        } >> "$SOURCEME"
    fi
    echo "MOPAC deployment section finished successfully."
else
    echo "yes."
fi

#15. Hex install
sh $vini_dir/hex_install

#sh $vini_dir/database_sync #create and push on GD VINI database snapshot

echo "You have to re-login in order to changes make effect!"
