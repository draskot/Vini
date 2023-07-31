
NULL=0
module purge

if  [ ! -e sourceme ]
then
    vini_dir=$HOME/Vini
    echo "Vini main directory will be set to $vini_dir" ; echo
    read -p "Please enter your SLURM account (e.g. r2022r03-224-users):" SLURMACCT
    read -p "Please enter path for your scratch data on the high-performance storage (e.g. /exa5/scratch/user/$USER):" WORKDIR
    echo "High Performance Storage (scratch) will be on Lustre, mounted as $WORKDIR" ; echo
    read -p "Please enter path for Vini's 3rd party software installation (e.g. /ceph/hpc/data/d2203-0100-users/$USER):" INSTALL
    echo "Third party software will be installed in $INSTALL directory" ; echo
    SHARED=`dirname $INSTALL`
    mkdir -p $INSTALL
    echo "#************General section**********" >> $vini_dir/sourceme
    echo "export vini_dir=$vini_dir"   >> $vini_dir/sourceme
    echo "export SLURMACCT=$SLURMACCT" >> $vini_dir/sourceme
    echo "export WORKDIR=$WORKDIR"     >> $vini_dir/sourceme
    echo "export SHARED=$SHARED"       >> $vini_dir/sourceme
    echo "export INSTALL=$INSTALL"     >> $vini_dir/sourceme
else
    read -e -p "Do you want to modify the location of the high-performance storage (scratch)? (y/n). Press enter to accept the default: " -i "n" yesno
    if [ $yesno == y ]
    then
        read -p "Enter the path to your new scratch (e.g. /exa5/scratch/user/$USER):" WORKDIR
        echo "High Performance Storage (scratch) will be on $WORKDIR" ; echo
        lineno=`grep -n WORKDIR sourceme | cut -d: -f1`    #Get number of line to be replaced
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
    wget -P $INSTALL https://repo.anaconda.com/miniconda/Miniconda2-latest-Linux-x86_64.sh
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
    wget -P $INSTALL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
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
    echo -n "Chimera installation directory must be empty. Performing cleanup..."
    rm -rf $INSTALL/chimera-1.16-linux_x86_64
    echo "done."
    echo "Download UCSF Chimera chimera-1.16-linux_x86_64.bin from https://www.cgl.ucsf.edu/chimera/download.html into" $INSTALL
    read -p "Press enter when chimera-1.16-linux_x86_64.bin is placed in $INSTALL directory." enter
    echo "Chimera installation started. When asked for the install location enter:" $INSTALL/chimera-1.16-linux_x86_64
    echo "enter <no> when asked <Install desktop menu and icon?>" ; echo
    echo "choose no link (0) when asked <Install symbolic link to chimera executable for command line use in which directory?>" ; echo
    read -p "press enter to continue." enter
    chmod u+x $INSTALL/chimera-1.16-linux_x86_64.bin
    cd $INSTALL
    ./chimera-1.16-linux_x86_64.bin
    rm chimera-1.16-linux_x86_64.bin
    cd $vini_dir
    echo "#******UCSF Chimera section******" >> $vini_dir/sourceme
    echo "export PATH=$INSTALL/chimera-1.16-linux_x86_64/bin:\$PATH" >> $vini_dir/sourceme
    #source $vini_dir/sourceme
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
    rm -f $INSTALL/vina
    wget -O $INSTALL/vina https://github.com/ccsb-scripps/AutoDock-Vina/releases/download/v1.2.4/vina_1.2.4_linux_x86_64
    chmod u+x $INSTALL/vina
    echo "#***** Vina section******" >> $vini_dir/sourceme
    echo "export PATH=$INSTALL:\$PATH" >> $vini_dir/sourceme
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
            #export ALPHAFOLD_DATA_DIR
            #source $vini_dir/sourceme
        else
            sleep 1
            #read -p "no. Enter path where AlphaFold is installed (e.g. /ceph/hpc/data/r2022r03-224-users):" AlphaFold
	    #echo "module load Python/3.9.6-GCCcore-11.2.0" >> $vini_dir/sourceme
	    #echo "export PATH=$AlphaFold:\$PATH"  >> $vini_dir/sourceme
	    #echo "export AlphaFoldBASE=$AlphaFold/alphafold-data" >> $vini_dir/sourceme
            #echo "export AlphaFoldIMAGE=$AlphaFold/alphafold2.sif" >> $vini_dir/sourceme
	    #echo "export AlphaFoldSTART=$AlphaFold/run_singularity_all.py" >> $vini_dir/sourceme
	    #echo "export AlphaFoldSTART=$AlphaFold/run_singularity_vega.py" >> $vini_dir/sourceme
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
        rm -f $INSTALL/ncbi-blast-2.13.0+-src.tar.gz
        rm -rf $INSTALL/ncbi-blast-2.13.0+-src
        wget -P $INSTALL https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.13.0+-src.tar.gz
        tar -xzf $INSTALL/ncbi-blast-2.13.0+-src.tar.gz -C $INSTALL
        cd $INSTALL/ncbi-blast-2.13.0+-src/c++
        ./configure
        cd ReleaseMT/build
        make all_r
        echo "#***Blast section***" >> $vini_dir/sourceme
        echo "export PATH=$INSTALL/ncbi-blast-2.13.0+-src/c++/ReleaseMT/bin:\$PATH" >> $vini_dir/sourceme
        source $vini_dir/sourceme
        rm $INSTALL/ncbi-blast-2.13.0+-src.tar.gz
    fi
else
    echo "yes."
fi

echo -n "Checking if Rosetta is installed..."
grep Rosetta $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    echo "no." ; echo -n "Checking if Rosetta module(s) exist..."
    module spider rosetta &> tmp
    grep -w error tmp > rosetta
    if   [ ! -s rosetta ] #no error means module found
    then
	echo "yes"
	cat tmp
        echo "#******* Rosetta section *******" >> $vini_dir/sourceme
        read -p "Select the Rosetta module:" rosetta
        echo "module load" $rosetta >> $vini_dir/sourceme
        source $vini_dir/sourceme
        which docking_protocol.static.linuxgccrelease &> tmp #search for Rosetta docking commands and Rosetta bin directory
        grep "no docking_protocol" tmp > tmp2
        if  [ -s tmp2 ]
        then
            which docking_protocol.default.linuxgccrelease &> tmp
            grep "no docking_protocol" tmp > tmp2
            if  [ -s tmp2 ]
            then
                which  docking_protocol.mpi.linuxgccrelease 2> tmp
                grep "no docking_protocol" tmp > tmp2
                if  [ -s tmp2 ]
                then
                    echo "no Rosetta docking protocol found. Check Rosetta module for errors. Exiting."
                    file=$vini_dir/sourceme
                    tail -n 1 "$file" | wc -c | xargs -I {} truncate "$file" -s -{}
                    exit
                else
                    echo docking_protocol.mpi.linuxgccrelease > $WORKDIR/rosetta_docking_command
                    echo relax.mpi.linuxgccrelease > $WORKDIR/rosetta_relax_command
                fi
            else
                echo docking_protocol.default.linuxgccrelease > $WORKDIR/rosetta_docking_command
                echo relax.default.linuxgccrelease > $WORKDIR/rosetta_relax_command
            fi
        else
            echo "docking_protocol.static.linuxgccrelease" > $WORKDIR/rosetta_docking_command
            echo "" $WORKDIR/rosetta_relax_command
        fi

        which `cat $WORKDIR/rosetta_docking_command` > tmp
        dirname `cat tmp` > $WORKDIR/rosetta_bin_directory
        rosetta_bin=`cat $WORKDIR/rosetta_bin_directory`
        echo "export PATH=${rosetta_bin}:\$PATH" >> $vini_dir/sourceme
        rm tmp*
    else
	echo "no."
        if  [ -e $WORKDIR/Rosetta_username ] && [ -e $WORKDIR/Rosetta_password ]
        then
	    echo "registration data exist."
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
       if  [ ! -e $INSTALL/rosetta_bin_linux_3.13_bundle.tgz ]
       then
           echo -n "Downloading Rosetta binaries, may take a while..." 
           wget -O $INSTALL/rosetta_bin_linux_3.13_bundle.tgz --user=${Rosetta_username} --password=${Rosetta_password} https://www.rosettacommons.org/downloads/academic/2023/wk6/rosetta.source.release-340.tar.bz2
           echo "done."
       fi
       echo "Unpacking Rosetta source. May take several minutes to finish, do not interrupt."
       tar -xf $INSTALL/https://www.rosettacommons.org/downloads/academic/2023/wk6/rosetta.source.release-340.tar.bz2 --checkpoint=.4000 -C $INSTALL
       echo "Done"
       echo -n " Cleaning up installation files..."
       rm $INSTALL/rosetta.source.release-340.tar.bz2
       echo "done."
       . $HOME/spack/share/spack/setup-env.sh
       spack load scons
       cd $INSTALL/rosetta.source.release-340/main/source
       scons -j 20 mode=release bin extras=cxx11thread

       echo "#******* Rosetta section *******" >> $vini_dir/sourceme
       ROSETTA_BIN=$INSTALL/rosetta.source.release-340/main/source/bin
       echo "export PATH=${ROSETTA_BIN}:\$PATH" >> $vini_dir/sourceme
       ROSETTA_DB=$INSTALL/rosetta.source.release-340/main/database
       echo "export PATH=${ROSETTA_DB}:\$PATH" >> $vini_dir/sourceme
       echo "export ROSETTA_TOOLS=$INSTALL/rosetta.source.release-340/main/tools/protein_tools/scripts"  >> $vini_dir/sourceme
       echo "export ROSETTA_PUB=$INSTALL/rosetta.source.release-340/main/source/src/apps/public/relax_w_allatom_cst" >> $vini_dir/sourceme
    fi
    echo "nompi" > $WORKDIR/rosetta_version #tell Rosetta not to use MPI
else
    echo "yes."
fi
rm -f rosetta tmp

echo -n "Checking if NAMD is installed..."
grep NAMD $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    echo "no." ; echo -n "Checking if NAMD module(s) exists..."
    module spider NAMD 2> tmp
    grep -w error tmp > NAMD
    if [ ! -s NAMD ]
    then
        echo "module(s) found" ; cat tmp
        read -p "Do you want to use an existing NAMD module [m] or your local NAMD installation [l]?" use
        if  [ $use == m ]
        then
            read -p "Select the module from the list above:" NAMD
            echo "#*****NAMD section******" >> $vini_dir/sourceme
            echo "module load" $NAMD >> $vini_dir/sourceme
        else
            read -p "Enter path where your NAMD distribution is located (e.g. /ceph/hpc/data/d2203-0100-users/eudraskot/NAMD_Git-2022-07-21_Linux-x86_64-verbs)" NAMD_PATH
            echo "#*****NAMD section******" >> $vini_dir/sourceme
            echo "export PATH=${NAMD_PATH}:\$PATH" >> $vini_dir/sourceme
        fi
    else
         echo "Download NAMD binary from https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=NAMD to $INSTALL directory. (e.g. /ceph/hpc/data/r2022r03-224-users/eudraskot/NAMD_Git-2022-07-21_Linux-x86_64-verbs)"
         read -p "Enter path where your NAMD distribution is located:" enter
         echo "#*****NAMD section******" >> $vini_dir/sourceme
         echo "export PATH=${NAMD_PATH}:\$PATH" >> $vini_dir/sourceme
    fi
else
    echo "yes."
fi
rm -f NAMD tmp

echo -n "Checking if VMD is installed..."
grep VMD $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    echo "no." ; echo -n "Checking if VMD module(s) exists..."
    module spider VMD 2> tmp
    grep -w error tmp > VMD
    if [ ! -s VMD ]
    then
        echo "module(s) found" ; cat tmp
        read -p "Do you want to use one of the existing VMD modules [m] or install your own copy [i]?" use
        if  [ $use == m ]
        then
            read -p "Select the module from the list above:" VMD
            echo "#*****VMD section******" >> $vini_dir/sourceme
            echo "module load" $VMD >> $vini_dir/sourceme
        else
            if  [ ! -e $INSTALL/vmd-1.9.4a57.bin.LINUXAMD64-CUDA102-OptiX650-OSPRay185.opengl.tar ]
            then
                echo "Download VMD Version 1.9.4 <LINUX_64 (RHEL 7+) OpenGL, CUDA, OptiX RTX, OSPRay> from https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD to $INSTALL directory."
                read -p "Press enter when the file is in place:" enter
            fi
            rm -rf $INSTALL/vmd-1.9.4
            tar -xvf $INSTALL/vmd-1.9.4a57.bin.LINUXAMD64-CUDA102-OptiX650-OSPRay185.opengl.tar.gz -C $INSTALL
            echo "#*****VMD section******" >> $vini_dir/sourceme
            echo "export PATH=$INSTALL/vmd-1.9.3/scripts/:\$PATH" >> $vini_dir/sourceme
        fi
    else
        if [ ! -e $INSTALL/vmd-1.9.4a57.bin.LINUXAMD64-CUDA102-OptiX650-OSPRay185.opengl.tar ]
        then
            echo "Download VMD Version 1.9.4 <LINUX_64 (RHEL 7+) OpenGL, CUDA, OptiX RTX, OSPRay > from https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD to $INSTALL directory."
            read -p "Press enter when the file is in place:" enter
        fi
        rm -rf $INSTALL/vmd-1.9.4
        tar -xvf $INSTALL/vmd-1.9.4a57.bin.LINUXAMD64-CUDA102-OptiX650-OSPRay185.opengl.tar.gz -C $INSTALL
        echo "#*****VMD section******" >> $vini_dir/sourceme
        echo "export PATH=$INSTALL/vmd-1.9.3/scripts/:\$PATH" >> $vini_dir/sourceme
    fi
else
    echo "yes."
fi
rm -f VMD tmp

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
        module load CMake/3.20.1-GCCcore-10.3.0
        module load Boost/1.76.0-GCC-10.3.0
        cmake ../ -DCMAKE_INSTALL_PREFIX=$INSTALL/openbabel-3.1.1
        make -j 12
        make -j 12 install
        echo "#*****OpenBabel section******" >> $vini_dir/sourceme
        echo "export PATH=$INSTALL/openbabel-3.1.1/bin:\$PATH" >> $vini_dir/sourceme
        echo "module load Boost/1.76.0-GCC-10.3.0" >> $vini_dir/sourceme
        cd $vini_dir
        echo -n "done."
    fi
fi
rm -f openbabel tmp $INSTALL/openbabel-3-1-1.tar.gz


echo "You have to re-login in order to changes make effect!"
