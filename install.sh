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
    echo "High Performance Storage (scratch) will be on Lustre, mounted as $WORKDIR" ; echo
    read -p "enter full path for high performance storage (e.g. /exa5/scratch/user/$USER):" WORKDIR
    read -p "enter full path for 3rd party software installation (e.g. /ceph/hpc/data/d2203-0100-users/$USER):" INSTALL
    echo "Third party software will be installed in $INSTALL directory" ; echo
    SHARED=`dirname $INSTALL`
    echo "If Alphafold module is not available on this system, consider local AlphaFold installation on $SHARED" ; echo
    mkdir -p $WORKDIR
    mkdir -p $INSTALL
    echo "#************General section**********" >> $vini_dir/sourceme
    echo "export vini_dir=$vini_dir" >> $vini_dir/sourceme
    echo "export WORKDIR=$WORKDIR" >> $vini_dir/sourceme
    echo "export SHARED=$SHARED" >> $vini_dir/sourceme
    echo "export INSTALL=$INSTALL" >> $vini_dir/sourceme
    source $vini_dir/sourceme
fi
read -p "press enter when ready to start the installation of 3rd party software."

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
grep Vina $vini_dir/sourceme > tmp
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
    echo "#*****AlphaFold section******" >> $vini_dir/sourceme
    echo "no." ; echo -n "Checking if AlphaFold module(s) exists..."
    module spider Alphafold 2> tmp
    grep -w error tmp > alphafold
    if [ ! -s alphafold ]
    then
        echo "module(s) found" ; cat tmp
        read -p "Select module:" alphafold
        echo "module load" $alphafold >> $vini_dir/sourceme
        source $vini_dir/sourceme
    else
        read -p "no module found. Enter path where AlphaFold is installed:" AlphaFold
	echo "module load Python/3.9.6-GCCcore-11.2.0" >> $vini_dir/sourceme
	echo "export PATH=$AlphaFold:\$PATH"  >> $vini_dir/sourceme
	echo "export AlphaFoldSTART=$AlphaFold/run_singularity.py" >> $vini_dir/sourceme
	echo "export AlphaFoldBASE=$AlphaFold/alphafold-data" >> $vini_dir/sourceme
        echo "export AlphaFoldIMAGE=$AlphaFold/alphafold2.sif" >> $vini_dir/sourceme
        #echo "export DATA_DIRECTORY=$AlphaFold/alphafold-data" >> $vini_dir/sourceme
    fi
else
    echo "yes."
fi
rm -f alphafold tmp

echo -n "Checking if Rosetta is installed..."
grep Rosetta $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    echo "****** Rosetta *******" >> $vini_dir/sourceme
    echo "no." ; echo -n "Checking if Rosetta module(s) exists..."
    module spider rosetta 2> tmp
    grep -w error tmp > rosetta
    #if [ ! -s rosetta ] #commented for debug
    if [ -s rosetta ]    #added for debug
    then
        echo "module(s) found" ; cat tmp
        read -p "Select the Rosetta module:" rosetta
        echo "******* Rosetta *******" $vini_dir/sourceme
        echo "module load" $rosetta >> $vini_dir/sourceme
    else
        echo ; echo "If you never registered for Rosetta Common download before, go to https://els2.comotion.uw.edu/product/rosetta  and request license. Obtaining a license is free for academic users. Upon receiving a license, enter your username and password here."
        read -e -p "Already registered (y/n)? Press enter to accept default: " -i "y" yesno
        if  [ $yesno == "n" ]
        then
            read -p "Enter username:" username
            echo -n "Enter password:"; read -s password ; echo ""
            echo $username > $WORKDIR/Rosetta_username
            echo $password > $WORKDIR/Rosetta_password
            chmod g-r,o-r $WORKDIR/Rosetta_password
       else
           if  [ ! -e $WORKDIR/Rosetta_username ] || [ ! -e $WORKDIR/Rosetta_password ]
           then
               echo "No registration data found. You will need to enter data for the first time. "
               read -p "Enter username:" username
               echo -n "Enter password:"; read -s password ; echo ""
               echo $username > $WORKDIR/Rosetta_username
               echo $password > $WORKDIR/Rosetta_password
               chmod g-r,o-r $WORKDIR/Rosetta_password
           fi
       fi        
       Rosetta_username=`cat $WORKDIR/Rosetta_username`
       Rosetta_password=`cat $WORKDIR/Rosetta_password`
       if  [ ! -e $INSTALL/rosetta_bin_linux_3.13_bundle.tgz ]
       then
           echo -n "Downloading Rosetta binaries, may take a while..." 
           wget -O $INSTALL/rosetta_bin_linux_3.13_bundle.tgz --user=${Rosetta_username} --password=${Rosetta_password} https://www.rosettacommons.org/downloads/academic/3.13/rosetta_bin_linux_3.13_bundle.tgz
           echo "done."
       fi
       echo "Unpacking Rosetta binaries. Will take a minutes to finish, do not interrupt."
       tar -xf $INSTALL/rosetta_bin_linux_3.13_bundle.tgz --checkpoint=.4000 -C $INSTALL
       echo "Done"
       echo -n " Cleaning up the installation files..."
       rm $INSTALL/rosetta_bin_linux_3.13_bundle.tgz
       echo "done."
       echo "export PATH=$INSTALL/rosetta_bin_linux_2021.16.61629_bundle/main/source/bin:\$PATH" >> $vini_dir/sourceme
    fi
else
    echo "yes."
fi
rm -f rosetta tmp

echo "The downloaded source packages are in" $vini_dir/software
echo "Installation is done. You may want to put source" $vini_dir"/sourceme in your .bashrc file."
