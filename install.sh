
if [ -e $vini_dir/globals ]
then
    source $vini_dir/globals
fi
module purge

if  [ ! -e sourceme ]
then
    vini_dir=$HOME/Vini
    echo "Vini main directory will be set to $vini_dir" ; echo
    read -p "Please enter your SLURM account (e.g. r2022r03-224-users):" SLURMACCT
    read -p "Please enter path for your scratch data on the high-performance storage (e.g. /scratch/IRB/$USER):" WORKDIR
    echo "High Performance Storage (scratch) will be on Lustre, mounted as $WORKDIR" ; echo
    read -p "Please enter path for Vini's 3rd party software installation (e.g. /scratch/IRB/$USER/INSTALL):" INSTALL
    echo "Third party software will be installed in $INSTALL directory" ; echo
    SHARED=`dirname $INSTALL`
    mkdir -p $INSTALL
    echo "#************General**********" >> $vini_dir/sourceme
    echo "export vini_dir=$vini_dir"   >> $vini_dir/sourceme
    echo "export SLURMACCT=$SLURMACCT" >> $vini_dir/sourceme
    echo "export WORKDIR=$WORKDIR"     >> $vini_dir/sourceme
    echo "export SHARED=$SHARED"       >> $vini_dir/sourceme
    echo "export INSTALL=$INSTALL"     >> $vini_dir/sourceme
else
    echo "High-performace storage (scratch) is set to $WORKDIR"
    read -e -p "Do you want to modify it's location (y/n)?. Enter to accept the default: " -i "n" yesno
    if [ $yesno == y ]
    then
        read -p "Enter the path to your new scratch (e.g. /exa5/scratch/user/$USER):" WORKDIR
        echo "High Performance Storage (scratch) will be on $WORKDIR" ; echo
        lineno=`grep -n WORKDIR sourceme | head -1 | cut -d: -f1` #Get number of line to be replaced
        newline=`echo "export WORKDIR=$WORKDIR"`
        sed -i "$lineno i ${newline}" sourceme
        let lineno++
        sed -i "$lineno d" sourceme
    fi
fi

source $vini_dir/sourceme

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

echo -n "Checking if miniconda3 is installed..."
grep miniconda3 $vini_dir/sourceme > tmp 
if  [ ! -s tmp ]
then
    echo "no. Performing cleanup. May take several minutes to finish, do not interrupt."
    rm -rf $INSTALL/miniconda3
    unset PYTHONPATH
    echo "done."
    echo "Please wait while downloading and installing miniconda3..."
    wget --no-check-certificate  -P $INSTALL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    sh $INSTALL/Miniconda3-latest-Linux-x86_64.sh -b -p $INSTALL/miniconda3
    source $INSTALL/miniconda3/etc/profile.d/conda.sh
    conda create -n env310 --yes numpy scipy pandas requests mpi4py pyqt python=3.9
    conda activate env310
    #conda install -c conda-forge rdkit
    conda deactivate
    echo "#***miniconda3 section***" >> $vini_dir/sourceme
    rm $INSTALL/Miniconda3-latest-Linux-x86_64.sh
else
    echo "yes."
fi

#echo -n "Checking if meeko is installed..."
#grep meeko $vini_dir/sourceme > tmp
#if  [ ! -s tmp ]
#then
#    source $INSTALL/miniconda3/bin/activate
#    conda activate env310
#    pip install meeko
#    conda deactivate
#    echo "#***meeko section***" >> $vini_dir/sourceme
#else  
#    echo "yes."
#fi

#echo -n "Checking if rdkit is installed..."
#grep rdkit $vini_dir/sourceme > tmp
#if  [ ! -s tmp ]
#then
#    source $INSTALL/miniconda3/bin/activate
#    conda activate env310
#    conda install -c conda-forge rdkit
#    conda deactivate
#    echo "#***rdkit section***" >> $vini_dir/sourceme
#else
#    echo "yes."
#fi

#echo -n "Checking if coreapi-cli is installed..."
#grep coreapi $vini_dir/sourceme > tmp #install coreapi
#if  [ ! -s tmp ]
#then
#    echo -n "no. Please wait while coreapi-cli is installed..."
#    source $INSTALL/miniconda3/bin/activate
#    conda activate env310
#    conda install -c conda-forge coreapi-cli
#    conda deactivate
#    echo "#***coreapi section***" >> $vini_dir/sourceme
#else
#    echo "yes."
#fi

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

echo -n "Checking if database is in place..."
grep database $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    echo -n "no. Please wait while Vini database is downloaded..."
    mkdir -p $vini_dir/database
    wget -O $vini_dir/database/database.tar.bz2 --no-check-certificate -q https://mojoblak.irb.hr/s/4C3MbQ3SirGTKJm/download/database.tar.bz2
    echo "done."
    echo -n "Uncompressing database, please wait..."
    cd $vini_dir/database
    tar -xvf database.tar.bz2
    echo "done."
    echo "#***database section***" >> $vini_dir/sourceme
    rm database.tar.bz2
else
    echo "yes."
fi

source $vini_dir/sourceme

echo -n "Checking if Alphafold is installed..."
grep AlphaFold $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    echo "no." ; echo -n "Checking if AlphaFold module(s) exists..."
    module spider Alphafold 2> tmp
    grep -w error tmp > alphafold
    if [ ! -s alphafold ]
    then
        echo "module(s) found" ; cat tmp
        echo "#*****AlphaFold section******" >> $vini_dir/sourceme
        read -p "Do you want to use module [m] or your local [l] Alphafold installation? (m/l)" ml
        if  [ $ml == m ]
        then
            read -p "Select module:" alphafold
            echo "module --ignore-cache load" $alphafold >> $vini_dir/sourceme
            echo "ALPHAFOLD_DATA_DIR=/ceph/hpc/software/alphafold/ ; export ALPHAFOLD_DATA_DIR" >> $vini_dir/sourceme
        else
            sleep 1
            read -p "no. Enter path where AlphaFold is installed (e.g. /ceph/hpc/data/r2022r03-224-users):" AlphaFold
	    echo "module load Python/3.9.6-GCCcore-11.2.0" >> $vini_dir/sourceme
	    echo "export PATH=$AlphaFold:\$PATH"  >> $vini_dir/sourceme
	    echo "export AlphaFoldBASE=$AlphaFold/alphafold-data" >> $vini_dir/sourceme
            echo "export AlphaFoldIMAGE=$AlphaFold/alphafold2.sif" >> $vini_dir/sourceme
	    echo "export AlphaFoldSTART=$AlphaFold/run_singularity_all.py" >> $vini_dir/sourceme
	    echo "export AlphaFoldSTART=$AlphaFold/run_singularity_vega.py" >> $vini_dir/sourceme
        fi
    fi
else
    echo "yes."
fi
rm -f alphafold tmp

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

echo -n "Checking if Rosetta is installed..."
grep Rosetta $vini_dir/sourceme > tmp
if  [ ! -s tmp ]  #install Rosetta
then
    module spider Rosetta > tmp
    grep error tmp 2&> tmp2
    if  [ ! -s tmp2 ]
    then
        echo "Rosetta module not exists! Installing local copy of Rosetta."

        if  [ -e $WORKDIR/Rosetta_username ] && [ -e $WORKDIR/Rosetta_password ]
        then
            echo "no, installing."
            Rosetta_username=`cat $WORKDIR/Rosetta_username`
            Rosetta_password=`cat $WORKDIR/Rosetta_password`
        else
            echo "In order to run Rosetta you must obtain license from https://els2.comotion.uw.edu/product/rosetta"
            echo "This license is free for academic users."
            echo "Upon receiving a license, enter username and password here."
            read -p "Enter username:" Rosetta_username
            echo -n "Enter password:"; read -s Rosetta_password ; echo ""
            echo $Rosetta_username > $WORKDIR/Rosetta_username
            echo $Rosetta_password > $WORKDIR/Rosetta_password
            chmod g-r,o-r $WORKDIR/Rosetta_username
            chmod g-r,o-r $WORKDIR/Rosetta_password
        fi    
        Rosetta_version=3.14
        Rosetta_release=371
        if  [ ! -e $INSTALL/rosetta_src_${Rosetta_version}_bundle.tar.bz2 ] ; then
            echo "Downloading Rosetta"
            wget -O $INSTALL/rosetta_src_${Rosetta_version}_bundle.tar.bz2  https://downloads.rosettacommons.org/downloads/academic/3.14/rosetta_src_3.14_bundle.tar.bz2
        fi

        if  [ ! -d $INSTALL/rosetta.source.release-${Rosetta_release} ] ; then
            echo "Unpacking Rosetta source, do not interrupt."
            tar -xf $INSTALL/rosetta_src_${Rosetta_version}_bundle.tar.bz2 --checkpoint=.4000 -C $INSTALL
        fi

        cd $INSTALL

        module purge
        echo "Compiling Rosetta requires GCC and OpenMPI. The list of available GCC modules will be shown next." ; sleep 2

        module spider gcc 
        sh $vini_dir/wait_for_key.sh "cont"
        read -p "Select GCC module to load and press enter to continue: " gcc
        module load ${gcc}

        echo "The list of available OpenMPI modules is shown next." ; sleep 3
        module spider OpenMPI 
        sh $vini_dir/wait_for_key.sh "cont"
        read -p "Select OpenMPI module to load and press enter to start compiling: " openmpi
        module load ${openmpi}
    
        cd $INSTALL/rosetta.source.release-${Rosetta_release}/main/source
        ./scons.py -j 8 bin mode=release extras=mpi
        rosetta_src=$INSTALL/rosetta.source.release-${Rosetta_release}
        ROSETTA=$INSTALL/rosetta.source.release-${Rosetta_release}/main
        ROSETTA_BIN=$ROSETTA/source/bin
        ROSETTA_DB=$ROSETTA/database
        ROSETTA_TOOLS=$ROSETTA/tools/protein_tools/scripts
        ROSETTA_PUB=$ROSETTA/source/src/apps/public/relax_w_allatom_cst
        echo "#******* Rosetta section *******"                                       >> $vini_dir/sourceme
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
        echo "#******* Rosetta section *******"                                       >> $vini_dir/sourceme
        echo "module load $rosetta"                                                   >> $vini_dir/sourceme
    fi
    echo "export ROSETTA=$ROSETTA"                                                >> $vini_dir/sourceme
    echo "export ROSETTA_TOOLS=$ROSETTA/tools/protein_tools/scripts"              >> $vini_dir/sourceme 
    echo "export ROSETTA_PUB=$ROSETTA/source/src/apps/public/relax_w_allatom_cst" >> $vini_dir/sourceme 
    echo "export PATH=${ROSETTA_BIN}:\$PATH"                                      >> $vini_dir/sourceme
    echo "export PATH=${ROSETTA_DB}:\$PATH"                                       >> $vini_dir/sourceme
fi

#echo -n "Checking if NAMD is installed..."
#grep NAMD $vini_dir/sourceme > tmp
#if  [ ! -s tmp ]
#then
#    echo "no." ; echo -n "Checking if NAMD module(s) exists..."
#    module spider NAMD 2> tmp
#    grep -w error tmp > NAMD
#    if [ ! -s NAMD ]
#    then
#        echo "module(s) found" ; cat tmp
#        read -p "Do you want to use an existing NAMD module [m] or your local NAMD installation [l]?" use
#        if  [ $use == m ]
#        then
#            read -p "Select the module from the list above:" NAMD
#            echo "#*****NAMD section******" >> $vini_dir/sourceme
#            echo "module load" $NAMD >> $vini_dir/sourceme
#        else
#            read -p "Enter path where your NAMD distribution is located (e.g. /ceph/hpc/data/d2203-0100-users/eudraskot/NAMD_Git-2022-07-21_Linux-x86_64-verbs)" NAMD_PATH
#            echo "#*****NAMD section******" >> $vini_dir/sourceme
#            echo "export PATH=${NAMD_PATH}:\$PATH" >> $vini_dir/sourceme
#        fi
#    else
#         echo "Download NAMD binary from https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=NAMD to $INSTALL directory. (e.g. /ceph/hpc/data/r2022r03-224-users/eudraskot/NAMD_Git-2022-07-21_Linux-x86_64-verbs)"
#         read -p "Enter path where your NAMD distribution is located:" enter
#         echo "#*****NAMD section******" >> $vini_dir/sourceme
#         echo "export PATH=${NAMD_PATH}:\$PATH" >> $vini_dir/sourceme
#    fi
#else
#    echo "yes."
#fi
#rm -f NAMD tmp

#echo -n "Checking if VMD is installed..."
#grep VMD $vini_dir/sourceme > tmp
#if  [ ! -s tmp ]
#then
#    echo "no." ; echo -n "Checking if VMD module(s) exists..."
#    module spider VMD 2> tmp
#    grep -w error tmp > VMD
#    if [ ! -s VMD ]
#    then
#        echo "module(s) found" ; cat tmp
#        read -p "Do you want to use one of the existing VMD modules [m] or install your own copy [i]?" use
#        if  [ $use == m ]
#        then
#            read -p "Select the module from the list above:" VMD
#            echo "#*****VMD section******" >> $vini_dir/sourceme
#            echo "module load" $VMD >> $vini_dir/sourceme
#        else
#            if  [ ! -e $INSTALL/vmd-1.9.4a57.bin.LINUXAMD64-CUDA102-OptiX650-OSPRay185.opengl.tar ]
#            then
#                echo "Download VMD Version 1.9.4 <LINUX_64 (RHEL 7+) OpenGL, CUDA, OptiX RTX, OSPRay> from https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD to $INSTALL directory."
#                read -p "Press enter when the file is in place:" enter
#            fi
#            rm -rf $INSTALL/vmd-1.9.4
#            tar -xvf $INSTALL/vmd-1.9.4a57.bin.LINUXAMD64-CUDA102-OptiX650-OSPRay185.opengl.tar.gz -C $INSTALL
#            echo "#*****VMD section******" >> $vini_dir/sourceme
#            echo "export PATH=$INSTALL/vmd-1.9.3/scripts/:\$PATH" >> $vini_dir/sourceme
#        fi
#    else
#        if [ ! -e $INSTALL/vmd-1.9.4a57.bin.LINUXAMD64-CUDA102-OptiX650-OSPRay185.opengl.tar ]
#        then
#            echo "Download VMD Version 1.9.4 <LINUX_64 (RHEL 7+) OpenGL, CUDA, OptiX RTX, OSPRay > from https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD to $INSTALL directory."
#            read -p "Press enter when the file is in place:" enter
#        fi
#        rm -rf $INSTALL/vmd-1.9.4
#        tar -xvf $INSTALL/vmd-1.9.4a57.bin.LINUXAMD64-CUDA102-OptiX650-OSPRay185.opengl.tar.gz -C $INSTALL
#        echo "#*****VMD section******" >> $vini_dir/sourceme
#        echo "export PATH=$INSTALL/vmd-1.9.3/scripts/:\$PATH" >> $vini_dir/sourceme
#    fi
#else
#    echo "yes."
#fi
#rm -f VMD tmp

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

#grep Amber $vini_dir/sourceme > tmp
#if  [ ! -s tmp ]
#then
#    echo "no." ; echo -n "Checking if Amber module(s) exist..."
#    module spider Amber &> tmp
#    grep -w error tmp > Amber
#    if   [ ! -s Amber ] #no error means module found
#    then
#        echo "yes"
#        cat tmp
#        echo "#******* Amber section *******" >> $vini_dir/sourceme
#        read -p "Select the Amber module:" Amber
#        echo "module load $Amber ">> $vini_dir/sourceme
#        source $vini_dir/sourceme
#    else
#        echo "no."
#        echo "Download Amber tar archive from http://ambermd.org/GetAmber.php and put it in the $INSTALL folder."
#        tar -xf $INSTALL/AmberTools23.tar.bz2 -C $INSTALL
#        rm $INSTALL/AmberTools23.tar.bz2
#        cd $INSTALL/amber22_src/build
        #ensure that XZ software is installed and active
#        ./run_cmake
#        echo "#******* Amber section *******" >> $vini_dir/sourceme
#    fi
#else
#    echo "yes."
#fi


#echo -n "Checking if BCL is installed..."
#grep BCL $vini_dir/sourceme > tmp
#if  [ ! -s tmp ]
#then
#    module purge
#    module load Python/2.7.18-GCCcore-10.2.0
#    module load CMake/3.23.1-GCCcore-11.3.0
#    module load libGLU/9.0.2-GCCcore-11.3.0
#    echo "no. BCL will be installed. Performing the cleanup, please wait." 
#    rm -rf $INSTALL/bcl-master
#    wget -O $INSTALL/bcl.zip  https://codeload.github.com/BCLCommons/bcl/zip/refs/heads/master
#    unzip -o $INSTALL/bcl.zip -d $INSTALL
#    rm $INSTALL/bcl.zip
#    cd $INSTALL/bcl-master
#    ./scripts/build/build_cmdline.linux.sh
#    echo "#******* BCL section *******" >> $vini_dir/sourceme
#    echo "export PATH=$INSTALL/bcl-master/build/linux64_release/bin:\$PATH" >> $vini_dir/sourceme
#else
#    echo "yes."
#fi


echo -n "Checking if Hex docking software is installed..."
grep Hex $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    echo "no. Hex will be installed." 
    echo "#******* Hex section *******" >> $vini_dir/sourceme
    module spider libGLU 2&> tmp
    grep error tmp 2&> tmp2
    if [ ! -s tmp2 ] ; then
       echo "module load libGLU/9.0.2-GCCcore-11.3.0" >> $vini_dir/sourceme
    fi
    rm $INSTALL/hex-8.1.1-x64-centos7.run
    cp $vini_dir/hex-8.1.1-x64-centos7.run $INSTALL
    exec $INSTALL/hex-8.1.1-x64-centos7.run
else
    echo "yes."
fi



echo "You have to re-login in order to changes make effect!"
