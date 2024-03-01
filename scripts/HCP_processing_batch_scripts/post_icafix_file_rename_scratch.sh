#!/bin/bash
# C. Cocuzza 2023

path_to_opts_script=/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/HCP_Scripts_StepWise/
source ${path_to_opts_script}opts_newPipe.shlib # command line option functions

subj=`opts_GetOpt1 "--subj" $@`

# Options for below: restFix_SingleRun, restFix_MultiRun_All, restFix_MultiRun_ByPhase, taskFix_SingleRun, taskFix_MultiRun_All, taskFix_MultiRun_ByState
fixrun=`opts_GetOpt1 "--fixrun" $@`

HCPPipe=/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/HCP_v2_prereqs/HCPpipelines-4.7.0/
EnvScript=/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/HCP_Scripts_StepWise/hcp_setup_milgram_tcp_2023.sh
basedir_data="/gpfs/milgram/project/holmes/PsychConnectome/MRI_Data/fmri_analysis/"
datadir="${basedir_data}/derivatives/hcp/"
subjdir=${datadir}
unprocesseddir="${basedir_data}/${subj}/"
. ${EnvScript}

if [ "$fixrun" == "restFix_SingleRun" ]; then
    export funcRunNames=( Rest_01_AP Rest_01_PA Rest_02_AP Rest_02_PA )
    addStr="_SingleRunICAFIX"
    fixType="SR"
elif [ "$fixrun" == "taskFix_SingleRun" ]; then
    export funcRunNames=( Task_Stroop_AP Task_Stroop_PA Task_Hammer_AP )
    addStr="_SingleRunICAFIX"
    fixType="SR"
elif [ "$fixrun" == "restFix_MultiRun_All" ]; then
    export funcRunNames=( Rest_01_AP Rest_01_PA Rest_02_AP Rest_02_PA )
    addStr="_MultiRunICAFIX_All"
    fixType="MR"
elif [ "$fixrun" == "restFix_MultiRun_ByPhase" ]; then
    export funcRunNames=( Rest_01_AP Rest_01_PA Rest_02_AP Rest_02_PA )
    addStr="_MultiRunICAFIX_ByPhase"
    fixType="MR"
elif [ "$fixrun" == "taskFix_MultiRun_All" ]; then
    export funcRunNames=( Task_Stroop_AP Task_Stroop_PA Task_Hammer_AP )
    addStr="_MultiRunICAFIX_All"
    fixType="MR"
elif [ "$fixrun" == "taskFix_MultiRun_ByState" ]; then
    export funcRunNames=( Task_Stroop_AP Task_Stroop_PA )
    addStr="_MultiRunICAFIX_ByState"
    fixType="MR"
fi 

echo "Renaming select files for: "
for runName in "${funcRunNames[@]}" ; do
    echo ${runName}
done

for runName in "${funcRunNames[@]}" ; do
    # Overlapping files between ICA-FIX applications 
    dirHere=${datadir}${subj}/MNINonLinear/Results/${runName}/
    cp ${dirHere}${runName}_hp2000.ica/filtered_func_data.ica/stats/stats.log ${dirHere}${runName}_hp2000.ica/filtered_func_data.ica/stats/stats${addStr}.log
    cp ${dirHere}${runName}_hp2000.ica/.fix_2b_predict.log ${dirHere}${runName}_hp2000.ica/.fix_2b_predict${addStr}.log 
    cp ${dirHere}${runName}_hp2000.ica/.fix.log ${dirHere}${runName}_hp2000.ica/.fix${addStr}.log
    cp ${dirHere}${runName}_hp2000.ica/filtered_func_data.ica/eigenvalues_percent ${dirHere}${runName}_hp2000.ica/filtered_func_data.ica/eigenvalues_percent${addStr}
    cp ${dirHere}${runName}_hp2000.ica/.fix ${dirHere}${runName}_hp2000.ica/.fix${addStr}
    cp ${dirHere}${runName}_hp2000.ica/fix/.version ${dirHere}${runName}_hp2000.ica/fix/.version${addStr}
    cp ${dirHere}${runName}_hp2000.ica/mc/prefiltered_func_data_mcf.par ${dirHere}${runName}_hp2000.ica/mc/prefiltered_func_data_mcf${addStr}.par
    cp ${dirHere}${runName}_hp2000_clean.nii.gz ${dirHere}${runName}_hp2000_clean${addStr}.nii.gz
    cp ${dirHere}${runName}_hp2000.ica/mc/prefiltered_func_data_mcf_conf_hp_clean.nii.gz ${dirHere}${runName}_hp2000.ica/mc/prefiltered_func_data_mcf_conf_hp_clean${addStr}.nii.gz
    cp ${dirHere}${runName}_hp2000.ica/mc/prefiltered_func_data_mcf_conf.nii.gz ${dirHere}${runName}_hp2000.ica/mc/prefiltered_func_data_mcf_conf${addStr}.nii.gz
    cp ${dirHere}${runName}_Atlas_hp2000_clean.dtseries.nii ${dirHere}${runName}_Atlas_hp2000_clean${addStr}.dtseries.nii
    
    # After single-run OR multi-run: 
    if [ "$fixType" == "SR" ]; then
        cp ${dirHere}${runName}_Atlas_hp2000.dtseries.nii ${dirHere}${runName}_Atlas_hp2000${addStr}.dtseries.nii
        cp ${dirHere}${runName}_hp2000.nii.gz ${dirHere}${runName}_hp2000${addStr}.nii.gz
        
    elif [ "$fixType" == "MR" ]; then
        cp ${dirHere}Movement_Regressors_demean.txt ${dirHere}Movement_Regressors_demean${addStr}.txt
        cp ${dirHere}Movement_Regressors_hp2000_clean.txt ${dirHere}Movement_Regressors_hp2000_clean${addStr}.txt 
        cp ${dirHere}${runName}_Atlas_hp2000_clean.README.txt ${dirHere}${runName}_Atlas_hp2000_clean.README${addStr}.txt
        cp ${dirHere}${runName}_Atlas_hp2000_vn.dscalar.nii ${dirHere}${runName}_Atlas_hp2000_vn${addStr}.dscalar.nii
        cp ${dirHere}${runName}_dims.txt ${dirHere}${runName}_dims${addStr}.txt
        cp ${dirHere}${runName}_hp2000_vn.nii.gz ${dirHere}${runName}_hp2000_vn${addStr}.nii.gz
        cp ${dirHere}${runName}_mean.nii.gz ${dirHere}${runName}_mean${addStr}.nii.gz
        
    fi 
done