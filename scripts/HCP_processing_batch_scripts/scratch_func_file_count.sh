#!/bin/bash 

subj=sub-PCM003
dirHere=/gpfs/milgram/project/holmes/PsychConnectome/MRI_Data/fmri_analysis/${subj}/func/
funcRunNames_AllPossible=( restAP_run-01 restPA_run-01 restAP_run-02 restPA_run-02 stroopAP_run-01 stroopPA_run-01 hammerAP_run-01 )

funcRunNames_Present=()
for runName in "${funcRunNames_AllPossible[@]}" ; do
    cd ${dirHere}
    numFiles=$(find . -type f -name "${subj}_task-${runName}_bold.nii.gz" | wc -l)
    if [ $numFiles -gt 0 ]; then
        funcRunNames_Present=(${funcRunNames_Present[@]} ${runName})
    fi 
done

for runName in "${funcRunNames_Present[@]}" ; do
    echo $runName
done