#!/bin/bash

# C. Cocuzza, 2023-2024. Running HCP processing pipelines on Transdiagnostic Connectome Project (TCP) data. 
# This script is specifically for post-fix QA (visualizing scenes) on select participants.
# Based on HCP-provided example PostFixBatch.sh 

# NOTE: set up of environment, compilers, paths, etc. are consistent with main HCP processing script here: hcp_main_milgram_tcp_2023.sh 

###########################################################################
# Command line set-up script:

# EDIT THESE: change ${path_to_opts_script} 
# NOTE: script itself should not need to change. 

echo "Sourcing command line option functions..."
path_to_opts_script=/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/HCP_Scripts_StepWise/

source ${path_to_opts_script}opts_newPipe.shlib # command line option functions

###########################################################################
###########################################################################

show_usage() {
    cat <<EOF
    
This script serves to run an individual participant through the HCP Pipeline, along with other necessary commands to fit their pipeline to the TCP Dataset/Yale HPC.

hcp_main_milgram_tcp_2023.sh

Usage: hcp_main_milgram_tcp_2023.sh [options]

    --server=<servername>                        (required) The name of the HPC server you're running this from (e.g., "milgram").
    --subj=<subjectID>                           (required) The participant ID, exactly as it is throughout project directories. 
    --dirSetUp=<"true">                          (optional) Input "true" to set up directory structure for this participant. 
                                                            Not currently supported; either TBA or will be removed.
                                                            
    --postFix=<"true">                           (optional) Input "true" to run PostFix.sh
                                                         
EOF
    exit 1
}
      
opts_ShowVersionIfRequested $@

if opts_CheckForHelpRequest $@; then
    show_usage
fi

###########################################################################
###########################################################################
# Input Variables:

echo "Setting input variables..."
server=`opts_GetOpt1 "--server" $@`
subj=`opts_GetOpt1 "--subj" $@`
#dirSetUp=`opts_GetOpt1 "--dirSetUp" $@`
postFix=`opts_GetOpt1 "--postFix" $@`

###########################################################################
###########################################################################
# Set up HCP Environment for Milgram: figure out which server is being used and set main paths.

# EDIT THESE:
# Modify the 'milgram' section in the if statement below to suit input/output directories for your project. 
# Consult HCP github, or the example scripts for each module in HCP_v2_prereqs/HCPpipelines-4.7.0/Examples/Scripts if unsure. 

if [ -z "$server" ]; then
    echo "Missing required option. Indicate which server you're using! Exiting script..."
    exit
elif [ "$server" == "milgram" ]; then
    echo "Setting up HCP environment for Milgram cluster..."
    
    # HCP pipelines main directory (from HCP GitHub); contains all the main scripts called below.
    # NOTE: there are helper/compiler/etc. scripts/tools that are stored elsewhere (hence the set-up script on the next line).
    HCPPipe=/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/HCP_v2_prereqs/HCPpipelines-4.7.0/
    
    # HCP set-up script (adapted from example scripts in above HCP pipeline directories).
    EnvScript=/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/HCP_Scripts_StepWise/hcp_setup_milgram_tcp_2023.sh
    
    # Base directory for data:
    #basedir_data="/gpfs/milgram/project/holmes/PsychConnectome/MRI_Data/fmri_analysis/" # Previous subject ID system
    basedir_data="/gpfs/milgram/project/holmes/PsychConnectome/MRI_Data/fmri_analysis/derivatives/hcp/" # NDA GUID system 
    
    # Output directory:
    #datadir="${basedir_data}/derivatives/hcp/" # Previous subject ID system
    datadir="${basedir_data}" # NDA GUID system  
    if [ ! -e $datadir ]; then mkdir -p $datadir; fi
    
    # Input directory (post-BIDS):
    unprocesseddir="${basedir_data}/${subj}/rawdata_for_hcp/"
    if [ ! -e $unprocesseddir ]; then 
        echo "No raw data directory for ${subj}. Exiting HCP preprocessing scripts, please check and re-run."
        exit
    fi
    
    # Set up functional runs to cycle through for various computational steps (based on data the given participant has)
    funcDirSubj="${unprocesseddir}func/"
    funcRunNames_AllPossible=( restAP_run-01 restPA_run-01 restAP_run-02 restPA_run-02 stroopAP_run-01 stroopPA_run-01 hammerAP_run-01 )
    funcRunNames_Present=()
    for runName in "${funcRunNames_AllPossible[@]}" ; do
        funcFileHere="${funcDirSubj}${subj}_task-${runName}_bold.nii.gz"
        if [ -f "$funcFileHere" ]; then
            funcRunNames_Present=(${funcRunNames_Present[@]} ${runName})
        else
            echo "WARNING: Functional files missing for run: ${runName}. This run will be skipped for this participant in relevant HCP steps."
        fi
    done
    echo "Functional runs present for this participant ${subj}:"
    for runName in "${funcRunNames_Present[@]}" ; do
        echo $runName
    done
    
    # Set up functional runs to cycle through and/or concatenate for various ICA-FIX/MSMAll/DedriftResample steps 
    funcRunNames_AllPossible_REST=( restAP_run-01 restPA_run-01 restAP_run-02 restPA_run-02 )
    funcRunNames_Present_REST=()
    for runName in "${funcRunNames_AllPossible_REST[@]}" ; do
        funcFileHere="${funcDirSubj}${subj}_task-${runName}_bold.nii.gz"
        if [ -f "$funcFileHere" ]; then
            funcRunNames_Present_REST=(${funcRunNames_Present_REST[@]} ${runName})
        fi
    done
    export funcRunNames_Present_REST=$funcRunNames_Present_REST

    fixMSM_Rest_SingleRun_Str="task-${funcRunNames_Present_REST[0]}_bold"
    for runName in "${funcRunNames_Present_REST[@]:1}" ; do
        fixMSM_Rest_SingleRun_Str="${fixMSM_Rest_SingleRun_Str}@task-${runName}_bold"
    done
    export fixMSM_Rest_SingleRun_Str=$fixMSM_Rest_SingleRun_Str
    echo "Concatenated resting-state string (for various rest FIX-ICA steps): $fixMSM_Rest_SingleRun_Str"

    funcRunNames_AllPossible_TASK=( stroopAP_run-01 stroopPA_run-01 hammerAP_run-01 )
    funcRunNames_Present_TASK=()
    for runName in "${funcRunNames_AllPossible_TASK[@]}" ; do
        funcFileHere="${funcDirSubj}${subj}_task-${runName}_bold.nii.gz"
        if [ -f "$funcFileHere" ]; then
            funcRunNames_Present_TASK=(${funcRunNames_Present_TASK[@]} ${runName})
        else
            echo "WARNING: Functional files missing for run: ${runName}. This run will be skipped for this participant in relevant HCP steps."
        fi
    done
    export funcRunNames_Present_TASK=$funcRunNames_Present_TASK

    fixMSM_Task_SingleRun_Str="task-${funcRunNames_Present_TASK[0]}_bold"
    for runName in "${funcRunNames_Present_TASK[@]:1}" ; do
        fixMSM_Task_SingleRun_Str="${fixMSM_Task_SingleRun_Str}@task-${runName}_bold"
    done
    export fixMSM_Task_SingleRun_Str=$fixMSM_Task_SingleRun_Str
    echo "Concatenated task-state string (for various task FIX-ICA steps): $fixMSM_Task_SingleRun_Str"

fi
# Set up HCP Pipeline Environment
echo "Sourcing HCP environment script..."
. ${EnvScript}

###########################################################################
###########################################################################
# HCP Conventions and Parameters. Shouldn't need to edit this.
# PostFreeSurfer input file names / Input Variables: 
echo "Setting HCP conventions and parameters..."
SurfaceAtlasDIR="${HCPPIPEDIR_Templates}/standard_mesh_atlases"
GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/91282_Greyordinates"
GrayordinatesResolutions="2" #Usually 2mm, if multiple delimit with @, must already exist in templates dir
HighResMesh="164" #Usually 164k vertices
LowResMeshes="32" #Usually 32k vertices, if multiple delimit with @, must already exist in templates dir
SubcorticalGrayLabels="${HCPPIPEDIR_Config}/FreeSurferSubcorticalLabelTableLut.txt"
FreeSurferLabels="${HCPPIPEDIR_Config}/FreeSurferAllLut.txt"
ReferenceMyelinMaps="${HCPPIPEDIR_Templates}/standard_mesh_atlases/Conte69.MyelinMap_BC.164k_fs_LR.dscalar.nii"
#Note MSMSulc is applied prior to MSMAll for regional alignment...
#RegName="MSMSulc" #MSMSulc is recommended, if binary is not available use FS (FreeSurfer)
RegName="MSMSulc"
# set bandpass filter used in FIX-ICA in seconds (2000 corresponds to detrending i.e. very lenient highpass 1/2000Hz)
bandpass=2000

###########################################################################
###########################################################################
# Data and scan parameters

# EDIT THESE AS NEEDED:

echo "Setting project-specific scan parameters..."
SmoothingFWHM="2" # smoothing that is restricted within each parcel, applied during Surface and DedriftResample modules
DwellTime_SE="0.0000021" # the dwell time or echo spacing of the SE FieldMaps (see protocol); *note that this has to be divided by GRAPPA ipat factor if this is used in your sequence, see user guide for details. Can alternatively look at parameters in fmap json (use dict keys).
DwellTime_fMRI="0.0000021" # the dwell time or echo spacing of the fMRI multiband sequence (see protocol); *note that this has to be divided by GRAPPA ipat factor if this is used in your sequence, see user guide for details. Can alternatively look at parameters in fmap json (use dict keys).
T1wSampleSpacing="0.000004" # This parameter can be found at DICOM field (0019,1018) (use command `dicom_hdr *001.dcm | grep "0019 1018"`. Do this on command line by using module load AFNI first. dcm files are in raw data for TCP (/gpfs/milgram/project/holmes/PsychConnectome/MRI_Data/fmri_analysis/sourcedata/<subj>/RAW/). NOTE: this needs to be converted into seconds. 
T2wSampleSpacing="0.000004" # This parameter can be found at DICOM field (0019,1018) (use command `dicom_hdr *001.dcm | grep "0019 1018"`
#this describes rationale behind these parameters (and the unwarpdir parameter in prefreesurfer which is set to z) https://www.mail-archive.com/hcp-users@humanconnectome.org/msg06751.html
seunwarpdir="y" # unwarp direction for spin echos; AP/PA is Y
unwarpdir="-y" # unwarp direction for functionals; A >> P phase encoded data is -y (think about how anterior to posterior coordinate direction is -y). It follows that unwarpdir for P >> A collected data would be "y", but we have not collected this data for the IndivRITL study.
numTRsPerTaskRun=521 #parm only used for concat + mask modules (which you should not be using)
# Default parameters (should not need to be changed for this study
fmrires="2"
brainsize="150"

###########################################################################
###########################################################################
# Anatomical templates for this study (MNI templates) (shouldn't need to edit):

echo "Setting anatomical templates for this study..."
t1template="${HCPPipe}/global/templates/MNI152_T1_0.8mm.nii.gz"
t1template2mm="${HCPPipe}/global/templates/MNI152_T1_2mm.nii.gz"
t1templatebrain="${HCPPipe}/global/templates/MNI152_T1_0.8mm_brain.nii.gz"
t2template="${HCPPipe}/global/templates/MNI152_T2_0.8mm.nii.gz"
t2templatebrain="${HCPPipe}/global/templates/MNI152_T2_0.8mm_brain.nii.gz"
t2template2mm="${HCPPipe}/global/templates/MNI152_T2_2mm.nii.gz"
templatemask="${HCPPipe}/global/templates/MNI152_T1_0.8mm_brain_mask.nii.gz"
template2mmmask="${HCPPipe}/global/templates/MNI152_T1_2mm_brain_mask_dil.nii.gz"

###########################################################################
###########################################################################

# Run PostFix
# EDIT THESE: one code block for each of the separately named functinal sequences; this is project specific. 

EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
source "$EnvironmentScript"

HighPass="2000" # 2000 (single run ICA-FIX) or 0 (multi-run ICA-FIX)
ReUseHighPass="NO" #Use YES if running on output from multi-run FIX, otherwise use NO
DualScene=${HCPPipe}/ICAFIX/PostFixScenes/ICA_Classification_DualScreenTemplate.scene
SingleScene=${HCPPipe}/ICAFIX/PostFixScenes/ICA_Classification_SingleScreenTemplate.scene
MatlabMode="0" #Mode=0 compiled Matlab, Mode=1 interpreted Matlab, Mode=2 octave

if [ -z "$postFix" ]; then
    echo "Skipping post-processing QA: PostFix."
elif [ $postFix = true ]; then
    echo "Running post-processing QA: PostFix..."
    for runName in "${funcRunNames_Present[@]}" ; do 
        echo "Running PostFix QA on ${runName} scan..." 
        fmriname="task-${runName}_bold"
        ${HCPPipe}/ICAFIX/PostFix.sh --path="${datadir}" --subject="${subj}" --fmri-name="${fmriname}" --high-pass="$HighPass" --template-scene-dual-screen="$DualScene" --template-scene-single-screen=$SingleScene --reuse-high-pass="$ReUseHighPass" --matlab-run-mode=$MatlabMode
    done
fi

###########################################################################



