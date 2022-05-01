#updated on 26042022
NULL=0
module purge
rm -f tmp

if [ -e sourceme ]
then
    grep General sourceme > tmp
fi

if  [ ! -s tmp ]
then
    vini_dir=$HOME/Vini
    echo "Vini main directory will be set to $vini_dir" ; echo
        
    name=`uname -n | grep vega`
    if [[ ! -z "$name" ]]
    then
        WORKDIR=/exa5/scratch/user/$USER
        echo "High Performance Storage (scratch) will be on Lustre, mounted as $WORKDIR" ; echo
        SHARED=/ceph/hpc/data/d2203-0100-users
	echo "Alphafold and Rosetta installation is on CEPH filesystem, mounted as $SHARED" ; echo
        INSTALL=$SHARED/$USER
    else
        WORKDIR=/scratch/IRB/$USER
        echo "High Performance Storage (scratch) will be on Lustre, mounted as $WORKDIR" ; echo
        INSTALL=$WORKDIR/packages
    fi
    echo "Third party software will be installed in $INSTALL directory" ; echo

    mkdir -p $WORKDIR
    mkdir -p $INSTALL

    echo "#************General section**********" >> $vini_dir/sourceme
    echo "export vini_dir=$vini_dir" >> $vini_dir/sourceme
    echo "export WORKDIR=$WORKDIR" >> $vini_dir/sourceme
    echo "export SHARED=$SHARED" >> $vini_dir/sourceme
    echo "export INSTALL=$INSTALL" >> $vini_dir/sourceme
    source $vini_dir/sourceme
fi
read -p "press enter when ready to start the installation."

echo -n "checking if miniconda2 is installed..."
grep miniconda2 $vini_dir/sourceme > tmp  
if  [ ! -s tmp ]
then
    echo "no. Please wait while downloading and installing miniconda2..."
    rm -f $vini_dir/software/Miniconda2-latest-Linux-x86_64.sh
    rm -rf  $INSTALL/miniconda2
    rm -f $vini_dir/software/Miniconda2-latest-Linux-x86_64.sh
    wget -P $vini_dir/software -q https://repo.anaconda.com/miniconda/Miniconda2-latest-Linux-x86_64.sh
    sh $vini_dir/software/Miniconda2-latest-Linux-x86_64.sh -b -p $INSTALL/miniconda2
    source $INSTALL/miniconda2/etc/profile.d/conda.sh
    conda create -n env27 --yes numpy pandas requests mpi4py pyqt python=2.7
    rm $vini_dir/software/Miniconda2-latest-Linux-x86_64.sh
    echo "#************miniconda2 section**********" >> $vini_dir/sourceme
else
    echo "yes."
fi

echo -n "checking if Meeko is installed..."
grep Meeko $vini_dir/sourceme > tmp 
if  [ ! -s tmp ]
then
    echo "no. Please wait while Meeko 0.3.0 is downloaded and installed..."
    rm -f $vini_dir/software/Miniconda2-latest-Linux-x86_64.sh
    rm -rf $INSTALL/miniconda3
    rm -f $vini_dir/software/Miniconda3-latest-Linux-x86_64.sh
    wget -P $vini_dir/software -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    sh $vini_dir/software/Miniconda3-latest-Linux-x86_64.sh -b -p $INSTALL/miniconda3
    source $INSTALL/miniconda3/etc/profile.d/conda.sh
    conda create -n meeko -c conda-forge numpy scipy rdkit
    conda activate meeko
    pip install meeko
    conda deactivate
    echo "#***Meeko 0.3.0 section***" >> $vini_dir/sourceme
else
    echo "yes."
fi

echo -n "Checking if coreapi-cli is installed..."
grep coreapi $vini_dir/sourceme > tmp #install coreapi
if  [ ! -s tmp ]
then
    echo -n "no. Please wait while coreapi-cli is installed..."
    source $INSTALL/miniconda3/etc/profile.d/conda.sh
    conda create -n coreapi --yes -c conda-forge coreapi-cli
    echo "#***coreapi***" >> $vini_dir/sourceme
else
    echo "yes."
fi


echo -n "checking if UCSF Chimera is installed..."
grep Chimera $vini_dir/sourceme > tmp    #install UCSF Chimera
if  [ ! -s tmp ]
then
    if  [ ! -e $vini_dir/software/chimera*.bin ]
    then
        echo "Download Chimera distribution from https://www.cgl.ucsf.edu/chimera/download.html into" $vini_dir/software
        read -p "press enter when ready to go." enter
        if [ ! -e $vini_dir/software/chimera*bin ]
        then
            echo "Chimera distribution not found. Download and run install.sh again"
        fi
    fi
    chmod u+x $vini_dir/software/chimera*.bin
    echo "Chimera installation started. When asked for the install location enter:" $INSTALL/chimera
    echo "enter <no> when asked <Install desktop menu and icon?>" ; echo
    echo "choose no link (0) when asked <Install symbolic link to chimera executable for command line use in which directory?>" ; echo
    read -p "press enter when ready to continue." enter
    rm -rf $INSTALL/chimera
    cp $vini_dir/software/chimera*.bin $INSTALL 
    cd $INSTALL
    ./chimera*.bin
    cd $vini_dir
    echo "#******UCSF Chimera section******" >> $vini_dir/sourceme
    echo "export PATH=$INSTALL/chimera/bin:\$PATH" >> $vini_dir/sourceme
    source $vini_dir/sourceme
else
    echo "yes."
fi

echo -n "checking if MGLTools are installed..."
grep mgltools_x86_64Linux2_1.5.7 $vini_dir/sourceme > tmp #install mgltools 1.5.7
if  [ ! -s tmp ]
then
    echo "no."
    rm -rf $vini_dir/software/index*
    wget -P $vini_dir/software -q --no-check-certificate https://ccsb.scripps.edu/download/532/
    mv $vini_dir/software/index.html $vini_dir/software/mgltools_x86_64Linux2_1.5.7.tar.gz
    tar -xvzf $vini_dir/software/mgltools_x86_64Linux2_1.5.7.tar.gz -C $INSTALL
    cd $INSTALL/mgltools_x86_64Linux2_1.5.7
    sh install.sh
    echo "#***mgltools_x86_64Linux2_1.5.7 section***" >> $vini_dir/sourceme
    echo "export MGLTOOLS=$INSTALL/mgltools_x86_64Linux2_1.5.7/MGLToolsPckgs/AutoDockTools" >> $vini_dir/sourceme
    echo "export MGLUTILS=$INSTALL/mgltools_x86_64Linux2_1.5.7/MGLToolsPckgs/AutoDockTools/Utilities24" >> $vini_dir/sourceme
    echo "export MGLBIN=$INSTALL/mgltools_x86_64Linux2_1.5.7/bin" >> $vini_dir/sourceme
    source $vini_dir/sourceme
    echo "export MGL=$INSTALL/mgltools_x86_64Linux2_1.5.7" >> $vini_dir/sourceme #next entries for DeltaVina
    echo "export PATH=$INSTALL/mgltools_x86_64Linux2_1.5.7/bin:\$PATH" >> $vini_dir/sourceme
    source $vini_dir/sourceme
else
    echo "yes."
fi

echo -n "checking if Vina is installed..."
grep Vina sourceme > tmp
nolines=`wc -l < tmp`
if [ $nolines -eq $NULL ]
then
    echo "no. Installing Vina..."
    rm -f $vini_dir/software/vina*
    wget -P $vini_dir/software -q --no-check-certificate https://github.com/ccsb-scripps/AutoDock-Vina/releases/download/v1.2.3/vina_1.2.3_linux_x86_64
    chmod u+x $vini_dir/software/vina*
    mkdir -p $INSTALL/vina
    cp $vini_dir/software/vina* $INSTALL/vina/vina
    echo "#***** Vina section******" >> $vini_dir/sourceme
    echo "export PATH=$INSTALL/vina:\$PATH" >> $vini_dir/sourceme
    source $vini_dir/sourceme
else
    echo "yes."
fi

echo -n "Checking if ADFR suite is installed..."
grep ADFRsuite $vini_dir/sourceme > tmp    #install ADFRsuite1.0
if  [ ! -s tmp ]
then
    echo -n "no. Please wait while ADFR suite 1.0 is installed..."
    rm -f $vini_dir/software/ADFRsuite_x86_64Linux_1.0.tar.gz
    rm -rf $INSTALL/ADFRsuite_x86_64Linux_1.0
    #curl -Lfs -o $vini_dir/software/ADFRsuite_x86_64Linux_1.0.tar.gz https://ccsb.scripps.edu/adfr/download/1038/
    wget -O $vini_dir/software/ADFRsuite_x86_64Linux_1.0.tar.gz -q https://ccsb.scripps.edu/adfr/download/1038/
    tar -xzf $vini_dir/software/ADFRsuite_x86_64Linux_1.0.tar.gz -C $INSTALL
    cd $INSTALL/ADFRsuite_x86_64Linux_1.0
    sh install.sh
    echo "#***ADFRsuite 1.0 section***" >> $vini_dir/sourceme
    echo "export PATH=$INSTALL/ADFRsuite_x86_64Linux_1.0/bin:\$PATH"  >> $vini_dir/sourceme
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
    echo "#***database***" >> $vini_dir/sourceme
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
        read -p "Select module:" alphafold
        echo "module load" $alphafold >> $vini_dir/sourceme
        echo "#*****AlphaFold section******" >> $vini_dir/sourceme
        source $vini_dir/sourceme
    else
        echo "no module found. Will use AlphaFold local installation."
        echo "#*****AlphaFold section******" >> $vini_dir/sourceme
	echo "module load Python/3.9.6-GCCcore-11.2.0" >> $vini_dir/sourceme
	echo "export PATH=$SHARED:\$PATH"  >> $vini_dir/sourceme
	echo "export AlphaFoldSTART=$SHARED" >> $vini_dir/sourceme
	echo "export AlphaFoldBASE=$SHARED/alphafold-data" >> $vini_dir/sourceme
    fi
else
    echo "yes."
fi
rm -f alphafold tmp

exit

grep rosetta $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    module avail Rosetta 2> tmp
    grep Rosetta tmp > rosetta
    if [ -s rosetta ]
    then
        echo "Found the following module(s) that may be associated with Rosetta:" ; cat rosetta
    fi
    read -p "Write the Rosetta module name or q to quit:" rosetta
    if  [ $rosetta != q ] ; then
        module avail 2> tmp
        grep "$rosetta" tmp > tmp2
        if [ -s tmp2 ] ; then
            echo "#*****Rosetta section******" >> $vini_dir/sourceme
            echo "module load" $rosetta >> $vini_dir/sourceme
            module load $rosetta
            which docking_protocol.linuxgccrelease > tmp          #defining ROSETTA var
            var=`cat tmp`
            var2=${var::-48}
            echo "export ROSETTA=$var2" >> $vini_dir/sourceme
            command -v docking_protocol.mpi.linuxgccrelease > tmp #checking for MPI support
            if  [ -s tmp ] ; then
                echo "mpi" > $WORKDIR/rosie
            else
                echo "static" > $WORKDIR/rosie
            fi
            source $vini_dir/sourceme
        else
            > $WORKDIR/rosie
            echo "module" $rosetta "does not exist."
            echo "Rosetta is used for the analysis of mAb drugs and can be installed later."
            echo "However, to activate Rosetta you must restart this install.sh script."
            read -p "Press <enter> to continue." anykey
        fi
    else
        echo "Rosetta is used for the analysis of mAb drugs and can be installed later."
        echo "However, to activate Rosetta you must restart this install.sh script."
        read -p "Press <enter> to continue." anykey
    fi
fi
rm -f rosetta tmp tmp2

echo "The downloaded source packages are in" $vini_dir/software
echo "Installation is done. You may want to put source" $vini_dir"/sourceme in your .bashrc file."

#grep Openbabel $vini_dir/sourceme > tmp
#if  [ ! -s tmp ]
#then
#    #echo "#*****OpenBabel section******" >> $vini_dir/sourceme
#    module spider Openbabel 2> tmp
#    grep -w error tmp > openbabel
#    if [ ! -s openbabel ]
#    then
#        echo "Found the following openbabel module(s):" ; cat tmp
#        read -p "Please select one of Openbabel modules found:" openbabel
#        echo "#*****OpenBabel section******" >> $vini_dir/sourceme
#        echo "module load" $openbabel >> $vini_dir/sourceme
#        source $vini_dir/sourceme
#    else
#        #echo "No Openbabel module found on this system. Installing Openbabel 3.1.1..."
#        #wget -P $vini_dir/software https://codeload.github.com/openbabel/openbabel/tar.gz/refs/tags/openbabel-3-1-1
#        #mv $vini_dir/software/openbabel-3-1-1 $vini_dir/software/openbabel-3-1-1.tar.gz
#        #tar -xvzf $vini_dir/software/openbabel-3-1-1.tar.gz -C $vini_dir/software
#        #mkdir $vini_dir/software/openbabel-openbabel-3-1-1/build
#        #cd $vini_dir/software/openbabel-openbabel-3-1-1/build
#        #rm -rf $INSTALL/openbabel-3.1.1
#        #cmake ../ -DCMAKE_INSTALL_PREFIX=$INSTALL/openbabel-3.1.1
#        #make -j 4
#        #make -j 4 install
#        #echo "#*****OpenBabel section******" >> $vini_dir/sourceme
#        #echo "export PATH=$INSTALL/openbabel-3.1.1/bin:\$PATH" >> $vini_dir/sourceme
#        #cd $vini_dir
#        echo "No Openbabel module found. Will use own Openbabel version 2.4.1"
#    fi
#fi
#rm -f openbabel tmp

#echo -n "Checking if Reduce is installed..."
#grep Reduce $vini_dir/sourceme > tmp #install Reduce
#if  [ ! -s tmp ]
#then
#    echo "no. Please wait while installing Reduce..."
#    wget https://codeload.github.com/rlabduke/reduce/zip/refs/heads/master
#    mv master reduce-master.zip
#    rm -rf reduce-master
#    rm -rf $INSTALL/reduce ; mkdir $INSTALL/reduce
#    unzip -oq reduce-master.zip
#    cd reduce-master
#    mkdir build
#    cd build
#    cmake .. -DCMAKE_INSTALL_PREFIX=$INSTALL/reduce
#    make
#    make install
#    echo "#***Reduce section***" >> $vini_dir/sourceme
#    echo "export PATH=\$PATH:$INSTALL/reduce/bin" >> $vini_dir/sourceme
#    echo "You may also want to su and place" $INSTALL/reduce/reduce_wwPDB_het_dict.txt
#    echo "into /usr/local. If you don't, Reduce will still run, but you'll probably get the"
#    echo "error message: ERROR CTab(/usr/local/reduce_wwPDB_het_dict.txt): could not open"
#    #https://github.com/jaredsampson/pymolprobity
#    read -p "Press enter to continue." enter
#    source $vini_dir/sourceme
#    rm -f tmp
#else
#    "yes."
#fi
