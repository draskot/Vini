
if [ "$#" -lt 8 ]; then # Check if the correct number of arguments is provided
    echo "Usage: $0 <input_list> <input_list> <pbs_script> <output_command_file> <I> <J> <L> <M>"
    exit 1
fi

input_list=$1
out_list=$2
pbs_script=$3
output_command_file=$4
I=$5 ; J=$6 ; L=$7 ; M=$8

echo $I $J $L $M


if  [ ${input_list} == "NONE" ]
then
    qsub_command="jobid=\$(qsub $pbs_script)"
else                              # Read the input list and extract job IDs
    job_dependencies="" 
    while read -r line
    do
        job_id=$(echo "$line" | awk -v I="$I" -v J="$J" -v L="$L" -v M="$M" '{print $5}')
        if [ -z "$job_dependencies" ]; then
            job_dependencies="$job_id"
        else
            job_dependencies="$job_dependencies,$job_id"
        fi
    done < "$input_list"
    qsub_command="jobid=\$(qsub -W depend=afterany:$job_dependencies $pbs_script)"
fi

echo "$qsub_command" > $output_command_file # Write the qsub command to the output command file
echo "jobid=\`echo \$jobid | awk '{print \$4}'\`" >> $output_command_file
echo "echo $I $J $L $M \$jobid >> ${out_list}" >> $output_command_file


