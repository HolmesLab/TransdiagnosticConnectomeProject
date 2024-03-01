#!/bin/bash

##################################################################
# Author: Carrisa V. Cocuzza. 2023. Yale University. Holmes Lab. 

# Description: Per participant, this script performs the main steps in fMRI data processing after HCP minimal preprocessing (see: hcp_main_milgram_tcp_2023.sh).

# Project: transdiagnostic connectome project (TCP) dataset, Yale Milgram HPC cluster. 

##################################################################
# Set up command line option functions:

# EDIT to your path: ${path_to_opts_script} 
# NOTE: script itself should not need to change. 

path_to_opts_script=/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/post_hcp_processing/
source ${path_to_opts_script}opts_newPipe.shlib

##################################################################
# Function input variable; matched input for post_hcp_main.sh
subj=`opts_GetOpt1 "--subj" $@`

##################################################################
# PATHS:
# Edit the variables here to conform to your project's specifications, environment, etc. 

# Base directory for scripts 
export baseDir_Scripts="/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/post_hcp_processing/"

# Base directory for INPUT data (i.e., raw data & results from HCP minimal preprocessing)
export baseDir_Input_Data="/gpfs/milgram/project/holmes/PsychConnectome/MRI_Data/fmri_analysis/derivatives/hcp/"

# Base directory for OUTPUT data (i.e., parent directory to store postprocessing results to)
export baseDir_Output_Data="/gpfs/milgram/project/holmes/PsychConnectome/MRI_Data/fmri_analysis/derivatives/post_hcp/"

# Raw data directory, used to check which functional runs a participant has 
#export rawDataDir_Subj="/gpfs/milgram/project/holmes/PsychConnectome/MRI_Data/fmri_analysis/${subj}/"
export rawDataDir_Subj="${baseDir_Input_Data}${subj}/rawdata_for_hcp/"

##################################################################
# VARIABLES:

# Set up functional runs to cycle through for various computational steps (based on data the given participant has)
# NOTE: functional run names must match the strings used throughout hcp_main_milgram_tcp_2023.sh
funcDirSubj="${rawDataDir_Subj}func/"

#################################
# All functional runs present for this participant (rest and task); maximum possible = 7
funcRunNames_AllPossible=( restAP_run-01 restPA_run-01 restAP_run-02 restPA_run-02 stroopAP_run-01 stroopPA_run-01 hammerAP_run-01 )
funcRunNames_Present=()
for runName in "${funcRunNames_AllPossible[@]}" ; do
    funcFileHere="${funcDirSubj}${subj}_task-${runName}_bold.nii.gz"
    if [ -f "$funcFileHere" ]; then
        funcRunNames_Present=(${funcRunNames_Present[@]} "task-${runName}_bold")
    else
        echo "WARNING: Functional files missing for run: ${runName}. This run will be skipped for this participant in relevant HCP steps."
    fi
done
export funcRunNames_Present=$funcRunNames_Present

#################################
# All resting-state functional runs present for this participant; maximum possible = 4
funcRunNames_AllPossible_REST=( restAP_run-01 restPA_run-01 restAP_run-02 restPA_run-02 )
funcRunNames_Present_REST=()
for runName in "${funcRunNames_AllPossible_REST[@]}" ; do
    funcFileHere="${funcDirSubj}${subj}_task-${runName}_bold.nii.gz"
    if [ -f "$funcFileHere" ]; then
        funcRunNames_Present_REST=(${funcRunNames_Present_REST[@]} "task-${runName}_bold")
    fi
done
export funcRunNames_Present_REST=$funcRunNames_Present_REST

#################################
# From above, generate @ delimited list of resting-state runs present for this participant
fixMSM_Rest_SingleRun_Str="task-${funcRunNames_Present_REST[0]}_bold"
for runName in "${funcRunNames_Present_REST[@]:1}" ; do
    fixMSM_Rest_SingleRun_Str="${fixMSM_Rest_SingleRun_Str}@task-${runName}_bold"
done
echo $fixMSM_Rest_SingleRun_Str

#################################
# Related to above, generate concatenated resting-state scan list - relevant to multi-run ICA-FIX output; TBA ********
#concatNames_Rest="Rest_"
#if [[ $fixMSM_Rest_SingleRun_Str == *"01"* ]]; then 
    
#fi 

#################################
# All task-state functional runs present for this participant; maximum possible = 3
funcRunNames_AllPossible_TASK=( stroopAP_run-01 stroopPA_run-01 hammerAP_run-01 )
funcRunNames_Present_TASK=()
for runName in "${funcRunNames_AllPossible_TASK[@]}" ; do
    funcFileHere="${funcDirSubj}${subj}_task-${runName}_bold.nii.gz"
    if [ -f "$funcFileHere" ]; then
        funcRunNames_Present_TASK=(${funcRunNames_Present_TASK[@]} "task-${runName}_bold")
    else
        echo "WARNING: Functional files missing for run: ${runName}. This run will be skipped for this participant in relevant HCP steps."
    fi
done
export funcRunNames_Present_TASK=$funcRunNames_Present_TASK

#################################
# From above, generate @ delimited list of task-state runs present for this participant
fixMSM_Task_SingleRun_Str="task-${funcRunNames_Present_TASK[0]}_bold"
for runName in "${funcRunNames_Present_TASK[@]:1}" ; do
    fixMSM_Task_SingleRun_Str="${fixMSM_Task_SingleRun_Str}@task-${runName}_bold"
done
echo $fixMSM_Task_SingleRun_Str

#################################
# Bandpass filter used in ICA-FIX of hcp_main_milgram_tcp_2023.sh 
# This is in seconds (2000 corresponds to detrending i.e. very lenient highpass 1/2000Hz).
export bandpass=2000

##################################################################