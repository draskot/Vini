
NULL=0
module purge
rm -f tmp

read -p "First time installation of Vini on this system (y/n)? Note that the first time installation will remove previously installed 3rd party Vini's software:" yesno
if [ $yesno == y ]
then
    rm -f sourceme
else
    grep General sourceme > tmp
fi

if  [ ! -s tmp ]
then
    vini_dir=$HOME/Vini
    echo "Vini main directory will be set to $vini_dir" ; echo
    read -p "Please enter path for your scratch data on high performance storage (e.g. /exa5/scratch/user/$USER):" WORKDIR
    echo "High Performance Storage (scratch) will be on Lustre, mounted as $WORKDIR" ; echo
    read -p "Please enter path for Vini's 3rd party software installation (e.g. /ceph/hpc/data/d2203-0100-users/$USER):" INSTALL
    echo "Third party software will be installed in $INSTALL directory" ; echo
    SHARED=`dirname $INSTALL`
    mkdir -p $INSTALL
    echo "#************General section**********" >> $vini_dir/sourceme
    echo "export vini_dir=$vini_dir" >> $vini_dir/sourceme
    echo "export WORKDIR=$WORKDIR" >> $vini_dir/sourceme
    echo "export SHARED=$SHARED" >> $vini_dir/sourceme
    echo "export INSTALL=$INSTALL" >> $vini_dir/sourceme
    source $vini_dir/sourceme
fi
read -p "Press enter when ready to start the installation of 3rd party software."

echo -n "Checking if miniconda2 is installed..."
grep miniconda2 $vini_dir/sourceme > tmp  
if  [ ! -s tmp ]
then
    echo "no. Performing cleanup, please wait..."
    rm -rvf  $INSTALL/miniconda2
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
    echo "no."
    echo -n "Performing cleanup. Please be patient, this may take a while...."
    rm -rvf $INSTALL/miniconda3
    echo "done."
    echo "Please wait while downloading and installing miniconda3..."
    wget -P $INSTALL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    sh $INSTALL/Miniconda3-latest-Linux-x86_64.sh -b -p $INSTALL/miniconda3
    source $INSTALL/miniconda3/etc/profile.d/conda.sh
    conda create -n env310 --yes numpy scipy pandas requests mpi4py pyqt
    conda activate env310
    conda install -c conda-forge rdkit
    conda deactivate
    echo "#***miniconda3 section***" >> $vini_dir/sourceme
    rm $INSTALL/Miniconda3-latest-Linux-x86_64.sh
else
    echo "yes."
fi

echo -n "Checking if meeko is installed..."
grep meeko $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    source $INSTALL/miniconda3/bin/activate
    conda activate env310
    pip install meeko
    conda deactivate
    echo "#***meeko section***" >> $vini_dir/sourceme
else  
    echo "yes."
fi

echo -n "Checking if rdkit is installed..."
grep rdkit $vini_dir/sourceme > tmp
if  [ ! -s tmp ]
then
    source $INSTALL/miniconda3/bin/activate
    conda activate env310
    conda install -c conda-forge rdkit
    conda deactivate
    echo "#***rdkit section***" >> $vini_dir/sourceme
else
    echo "yes."
fi


echo -n "Checking if coreapi-cli is installed..."
grep coreapi $vini_dir/sourceme > tmp #install coreapi
if  [ ! -s tmp ]
then
    echo -n "no. Please wait while coreapi-cli is installed..."
    source $INSTALL/miniconda3/bin/activate
    conda activate env310
    conda install -c conda-forge coreapi-cli
    conda deactivate
    echo "#***coreapi***" >> $vini_dir/sourceme
else
    echo "yes."
fi

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
    wget -O $INSTALL/vina https://github.com/ccsb-scripps/AutoDock-Vina/releases/download/v1.2.3/vina_1.2.3_linux_x86_64
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
    echo "#***database***" >> $vini_dir/sourceme
    rm database.tar.bz2
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
        read -p "no. Enter path where AlphaFold is installed:" AlphaFold
	echo "module load Python/3.9.6-GCCcore-11.2.0" >> $vini_dir/sourceme
	echo "export PATH=$AlphaFold:\$PATH"  >> $vini_dir/sourceme
	echo "export AlphaFoldBASE=$AlphaFold/alphafold-data" >> $vini_dir/sourceme
        echo "export AlphaFoldIMAGE=$AlphaFold/alphafold2.sif" >> $vini_dir/sourceme
	#echo "export AlphaFoldSTART=$AlphaFold/run_singularity_vega.py" >> $vini_dir/sourceme
	echo "export AlphaFoldSTART=$AlphaFold/run_singularity_all.py" >> $vini_dir/sourceme
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
        echo "#***Blast***" >> $vini_dir/sourceme
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
        echo "#******* Rosetta *******" >> $vini_dir/sourceme
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
	echo "#******* Rosetta *******" >> $vini_dir/sourceme
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
           wget -O $INSTALL/rosetta_bin_linux_3.13_bundle.tgz --user=${Rosetta_username} --password=${Rosetta_password} https://www.rosettacommons.org/downloads/academic/3.13/rosetta_bin_linux_3.13_bundle.tgz
           echo "done."
       fi
       echo "Unpacking Rosetta binaries. Will take a minutes to finish, do not interrupt."
       tar -xf $INSTALL/rosetta_bin_linux_3.13_bundle.tgz --checkpoint=.4000 -C $INSTALL
       echo "Done"
       echo -n " Cleaning up installation files..."
       rm $INSTALL/rosetta_bin_linux_3.13_bundle.tgz
       echo "done."
       echo "export ROSETTA_BIN=$INSTALL/rosetta_bin_linux_2021.16.61629_bundle/main/source/bin" >> $vini_dir/sourceme
       echo "export ROSETTA_DB=$INSTALL/rosetta_bin_linux_2021.16.61629_bundle/main/database" 
       echo "export PATH=${ROSETTA_BIN}:\$PATH" >> $vini_dir/sourceme
    fi
    echo "nompi" > $WORKDIR/rosetta_version #tell Rosetta not to use MPI
else
    echo "yes."
fi
rm -f rosetta tmp

echo "The downloaded source packages are in" $vini_dir/software
