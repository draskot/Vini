NULL=0   #checking if MD_run job finished or an error occured
error=0

while true
do
     sleep 1
     if  [ -e MD_prep.out ]; then
         grep Error MD_prep.out > gromacs_errors
     fi

     if  [ -e MD_run.out ]; then
         grep Error MD_run.out >> gromacs_errors
     fi

     if  [ -e ndx.out ]; then
         grep Error ndx.out >> gromacs_errors
     fi

     if  [ -e ndx.error ]; then
        echo "ndx error" >> gromacs_errors
     fi

     nolines=`wc -l < gromacs_errors`
     if  [ $nolines -gt $NULL ]; then
         echo "one of gromacs jobs failed. exiting loop."
         error=1 ; break
     fi

     if  [ -e md_0_1.log ] #exit loop if MD_run job finished
     then
         grep Finished md_0_1.log > tmp
         if  [ -s tmp ]
         then
             error=0 ; break
         fi
     fi
done

if  [ $error -eq $NULL ]
then
    while [ ! -e md_0_1.ndx ] #wait until ndx job finishes
    do
         sleep 1
    done
    echo 1 13 | g_mmpbsa -f md_0_1.xtc -s md_0_1.tpr -n md_0_1.ndx -i polar.mdp -nomme -pbsa -decomp
fi