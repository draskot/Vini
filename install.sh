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
    read -p "Please enter path for your scratch data on high performance storage (e.g. /exa5/scratch/user/$USER):" WORKDIR
    echo "High Performance Storage (scratch) will be on Lustre, mounted as $WORKDIR" ; echo
    read -p "Please enter path for Vini's 3rd party software installation (e.g. /ceph/hpc/data/d2203-0100-users/$USER):" INSTALL
    echo "Third party software will be installed in $INSTALL directory" ; echo
    SHARED=`dirname $INSTALL`
    echo "If Alphafold module is not available on this system, consider local AlphaFold installation on $SHARED" ; echo
    mkdir -p $INSTALL
    echo "#************General section**********" >> $vini_dir/sourceme
    echo "export vini_dir=$vini_dir" >> $vini_dir/sourceme
    echo "export WORKDIR=$WORKDIR" >> $vini_dir/sourceme
    echo "export SHARED=$SHARED" >> $vini_dir/sourceme
    echo "export INSTALL=$INSTALL" >> $vini_dir/sourceme
    source $vini_dir/sourceme
fi
read -p "Press enter when ready to start the installation of 3rd party software."






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


