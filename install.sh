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

#2. Minconda3 install
echo -n "Checking if miniconda3 is installed..."
grep miniconda3 $vini_dir/sourceme > tmp
if [ ! -s tmp ]; then
    echo "no. Performing cleanup. May take several minutes to finish, do not interrupt."
    rm -rf  $INSTALL/miniconda3
    module purge 2>/dev/null || true
    unset PYTHONPATH
    unset LD_LIBRARY_PATH
    echo "Please wait while downloading and installing miniconda3..."
    wget --no-check-certificate -P $INSTALL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    sh $INSTALL/Miniconda3-latest-Linux-x86_64.sh -b -p $INSTALL/miniconda3
    source $INSTALL/miniconda3/etc/profile.d/conda.sh
    echo "Creating Python 3.10 environment 'env310'..."
    conda create -n env310 --yes python=3.10
    conda activate env310
    conda install -c conda-forge --yes rdkit mdanalysis pdb2pqr openbabel numpy scipy pandas requests mpi4py pyqt tqdm
    conda deactivate
    echo "#***miniconda3 section***" >> $vini_dir/sourceme
    echo "Cleaning up installer..."
    rm -f $INSTALL/Miniconda3-latest-Linux-x86_64.sh
else
    echo "yes."
fi
rm -f tmp

#3. Chimera install
echo -n "checking if UCSF Chimera is installed..."
grep Chimera $vini_dir/sourceme > tmp    #install UCSF Chimera
if  [ ! -s tmp ]
then
    echo "no."
    read -e -p "Enter the name of the Chimera version you want to install. Press enter to install default:" -i "chimera-1.18-linux_x86_64" chimera 
    #chimera=chimera-1.17.3-linux_x86_64
    echo -n "Chimera installation directory must be empty. Performing cleanup..."
    rm -rf $INSTALL/${chimera}
    echo "done."
    echo "Download Chimera ${chimera}.bin from https://www.cgl.ucsf.edu/chimera/download.html into" $INSTALL
    read -p "Put ${chimera}.bin into $INSTALL directory and press enter." enter
    echo "Chimera installation started. When asked for the install location enter:" $INSTALL/${chimera}
    echo "enter <no> when asked <Install desktop menu and icon?>" ; echo
    echo "choose no link (0) when asked <Install symbolic link to chimera executable for command line use in which directory?>" ; echo
    read -p "press enter to continue." enter
    chmod u+x $INSTALL/${chimera}.bin
    cd $INSTALL
    ./${chimera}.bin
    rm ${chimera}.bin
    cd $vini_dir
    echo "#******UCSF Chimera section******" >> $vini_dir/sourceme
    echo "export PATH=$INSTALL/${chimera}/bin:\$PATH" >> $vini_dir/sourceme
    echo "Installation done. Register Chimera at https://www.cgl.ucsf.edu/cgi-bin/chimera_registration.py , otherwise it will not work as expected!" 
    read -p  "Press return when the registration is done." enter
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


#10. Rosetta install
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
            echo "Upon receiving a license, enter username and password here."
            read -p "Enter username:" Rosetta_username
            echo -n "Enter password:"; read -s Rosetta_password ; echo ""
            echo $Rosetta_username > $WORKDIR/Rosetta_username
            echo $Rosetta_password > $WORKDIR/Rosetta_password
            chmod g-r,o-r $WORKDIR/Rosetta_username
            chmod g-r,o-r $WORKDIR/Rosetta_password
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
        ./scons.py -j 24 bin mode=release extras=cxx11thread
	conda deactivate
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
grep OpenBabel $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    module spider Openbabel 2> tmp
    grep -w error tmp > openbabel
    if [ ! -s openbabel ]
    then
        echo "Found the following openbabel module(s):" ; cat tmp
        read -p "Please select one of Openbabel modules found:" openbabel
        echo "#*****OpenBabel section******" >> $vini_dir/sourceme
        echo "module load" $openbabel >> $vini_dir/sourceme
    else
        echo "No Openbabel module found on this system. Installing Openbabel 3.1.1..."
        wget -P $INSTALL https://codeload.github.com/openbabel/openbabel/tar.gz/refs/tags/openbabel-3-1-1
        
        mv $INSTALL/openbabel-3-1-1 $INSTALL/openbabel-3-1-1.tar.gz
        tar -xvzf $INSTALL/openbabel-3-1-1.tar.gz -C $INSTALL
        mkdir -p $INSTALL/openbabel-openbabel-3-1-1/build
        cd $INSTALL/openbabel-openbabel-3-1-1/build
        rm -rf $INSTALL/openbabel-3.1.1
        module purge
        module spider cmake
        read -p "Enter cmake module to load:" cmake_module
        module load ${cmake_module}
        module spider boost
        read -p "Enter Boost module to load:" boost_module
        module load ${boost_module}
        cmake ../ -DCMAKE_INSTALL_PREFIX=$INSTALL/openbabel-3.1.1
        make -j 4
        make install
        cp $INSTALL/openbabel-openbabel-3-1-1/build/lib/libcoordgen.so* $INSTALL/openbabel-3.1.1/lib
        echo "#*****OpenBabel section******" >> $vini_dir/sourceme
        echo "export PATH=$INSTALL/openbabel-3.1.1/bin:\$PATH" >> $vini_dir/sourceme
        echo "module load Boost/1.76.0-GCC-10.3.0" >> $vini_dir/sourceme
        cd $vini_dir
        echo -n "done."
    fi
fi
rm -f openbabel tmp $INSTALL/openbabel-3-1-1.tar.gz

#12. Java install
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

#13. BCL install
echo -n "Checking if BCL is installed..."
grep BCL $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    echo "no. BCL will be installed. Performing the cleanup, please wait."
    rm -f $INSTALL/master.zip
    rm -rf $INSTALL/bcl-master
    wget -P $INSTALL https://github.com/BCLCommons/bcl/archive/refs/heads/master.zip
    unzip -o $INSTALL/master.zip -d $INSTALL
    read -p "Enter the name of your HPC machine:" cluster
    module purge
    source $INSTALL/miniconda2/bin/activate
    if  [ $cluster == Vega ]
    then
        module load CMake/3.23.1-GCCcore-11.3.0
        module load libGLU/9.0.2-GCCcore-11.3.0
        cd $INSTALL/bcl-master
        ./scripts/build/build_cmdline.linux.sh
    else
        module load utils/cmake/3.26.0
        module load utils/spack/latest #This is a prerequisite for intel-oneapi-compilers module to load!
        module load intel-oneapi-compilers-2023.1.0-gcc-8.5.0-ff2gbr7
        cd $INSTALL/bcl-master
        ./scripts/build/build_cmdline.linux.sh
    fi
    conda deactivate
    echo "export PATH=$INSTALL/bcl-master/build/linux64_release/bin:\$PATH" >> $vini_dir/sourceme
    echo "#******* BCL section *******" >> $vini_dir/sourceme
    if  [ $cluster == Vega ]
    then
        echo "module load bzip2/1.0.8-GCCcore-11.3.0" >> $vini_dir/sourceme
        echo "module load oneapi/icc/2022.1.0" >> $vini_dir/sourceme
    else	
        echo "module load libs/bzip2/1.0.6" >> $vini_dir/sourceme
    fi
else
    echo "yes."
fi

#14. Hex install
sh $vini_dir/hex_install


#15. GD install
# Check if the data from Google Drive is installed
SOURCE_ME=$vini_dir/sourceme
if  grep -q "#\\*\\*\\*\\*\\* GD_data section \\*\\*\\*\\*\\*" "$SOURCE_ME"
then
    echo "Data from GD already downloaded."
else
    available_python=$(module --ignore-cache spider Python 2>&1 | grep -Eo 'Python/[0-9]+\.[0-9]+\.[0-9]+' | sort -u | tail -n 1)
    echo "module load $available_python" >> "$SOURCE_ME"
    echo "export VINI_PYTHON_MODULE=$available_python" >> "$SOURCE_ME"

    echo "Installing gdown..."
    module load "$available_python"
    python -m pip install --user --upgrade pip gdown
    DATABASE_DIR="$vini_dir/database"
    DEPMAP_DIR="$vini_dir/database/DepMap"
    mkdir -p $DEPMAP_DIR $DATABASE_DIR

    echo "Installing DepMap..."
    gdown "https://drive.google.com/uc?id=19qjZgt9WNPFrbBir0-Ux--Yvzsh1shc7" -O "${DEPMAP_DIR}/Depmap.tar.gz"
    tar -xvzf "${DEPMAP_DIR}/Depmap.tar.gz" -C ${DEPMAP_DIR}
    rm ${DEPMAP_DIR}/Depmap.tar.gz

    echo "Installing database..."
    gdown "https://drive.google.com/uc?id=12tUXGOdyQV_GLUmRzsGnB7vgKrvLjZcH" -O "${DATABASE_DIR}/database.tar.bz2"
    tar -xvf "${DATABASE_DIR}/database.tar.bz2" -C ${DATABASE_DIR}
    rm ${DATABASE_DIR}/database.tar.bz2

    {
    echo ""
    echo "#***** GD_data section *****"
    echo "export DEPMAP_DIR=$DEPMAP_DIR"
    echo "export DATABASE_DIR=$DATABASE_DIR"
    echo "export PATH=\$DEPMAP_DIR/bin:\$PATH"
    } >> "$SOURCE_ME"

fi

echo "Installing MOPAC..."
PROJECT_FOLDER=/ceph/hpc/data/r2022r03-224-users
INSTALL=$PROJECT_FOLDER/eudraskot
vini_dir=$HOME/Vini
SOURCEME="$vini_dir/sourceme"
CHECKPOINT_STRING="#*** MOPAC section ***"
MOPAC=$INSTALL/mopac
SCRATCH_BUILD=$INSTALL/SCRATCH_BUILD

if [ ! -f "$SOURCEME" ] || ! grep -qF "$CHECKPOINT_STRING" "$SOURCEME"; then
    # 1. Detect if a cluster module exists natively
    if module spider mopac 2>&1 | grep -qi "MOPAC"; then
        echo "MOPAC cluster module detected!"
        MOPAC_MODULE=$(module avail 2>&1 | grep -oiE "MOPAC/[A-Za-z0-9._\-]+" | head -n 1)
        
        # 2. Ask the user for their delivery choice
        echo "--------------------------------------------------------"
        echo "Found available cluster module: $MOPAC_MODULE"
        read -p "Would you like to use this cluster module? [Y/n]: " user_choice
        echo "--------------------------------------------------------"
        
        # Standardize choice string to lowercase
        user_choice=$(echo "$user_choice" | tr '[:upper:]' '[:lower:]')
    else
        # Force local compile if no module exists on the machine environment
        user_choice="n"
    fi

    # 3. Decision Loop Routing Layer
    if [ "$user_choice" = "y" ] || [ "$user_choice" = "" ] || [ "$user_choice" = "yes" ]; then
        echo "Loading cluster module layout..."
        module load "$MOPAC_MODULE"
        mkdir -p "$vini_dir" && touch "$SOURCEME"
        echo "" >> "$SOURCEME"
        echo "$CHECKPOINT_STRING" >> "$SOURCEME"
        echo "module load $MOPAC_MODULE" >> "$SOURCEME"
    else
        echo "Proceeding with local custom source installation..."
        module purge
        module load CMake/3.29.3-GCCcore-13.3.0 GCC/13.3.0 OpenBLAS/0.3.27-GCC-13.3.0
        mkdir -p "$MOPAC" "$SCRATCH_BUILD"
        cd "$SCRATCH_BUILD" && rm -rf ./*
        cd "$MOPAC" && rm -rf ./*
        wget https://github.com/openmopac/mopac/archive/refs/heads/main.zip
        unzip -qo main.zip
        cd mopac-main
        mkdir -p build
        cd build
        cmake .. -DCMAKE_INSTALL_PREFIX="$MOPAC" -DTESTS=OFF
        make -j 4 && make install
        mkdir -p "$vini_dir" && touch "$SOURCEME"
        echo "" >> "$SOURCEME"
        echo "$CHECKPOINT_STRING" >> "$SOURCEME"
        echo "export PATH=$MOPAC/bin:\$PATH" >> "$SOURCEME"
        echo "export LD_LIBRARY_PATH=$MOPAC/lib64:\$LD_LIBRARY_PATH" >> "$SOURCEME"
        echo "export MOPAC_THREADS=\$SLURM_CPUS_PER_TASK" >> "$SOURCEME"
    fi
    echo "MOPAC deployment section finished successfully."
else
    echo "Checkpoint verified: MOPAC environment is already active. Continuing installer sequence..."
fi

#sh $vini_dir/database_sync #create and push on GD VINI database snapshot

echo "You have to re-login in order to changes make effect!"
