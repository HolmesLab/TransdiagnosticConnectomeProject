#!/bin/bash

# Taku Ito, 10/29/14. Modified by Ravi Mill for CPRO2_learning 03/16/18. Modified by Carrisa Cocuzza 2023 for Yale HPC and TCP dataset. 

#########################
# IMPORTANT NOTES: 

# 1. Assumes that dicom2nifti conversion has been carried out (e.g. as part of BIDS conversion). On Milgram, can module load and manually use dcm2niix if needed.

# 2. HCP pipeline version used here: 4.7.0. See README docs throughout ~/HCP_v2_prereqs/HCPpipelines-4.7.0; also see: https://github.com/Washington-University/HCPpipelines

# 3. This version can only be used on Milgram (Yale Psych HPC cluster). It has also been specified to work with specs of the TCP dataset and file paths set up by Carrisa. This can likely be adapted to other projects, directories, etc.; the best approach would be to:

# a) copy the following directories to your project/home directory: 
# /gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/HCP_v2_prereqs
# /gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/HCP_Scripts_StepWise

# b) change the "edit these" specs below (use find/search/etc. to see all sections to change within this script).

# c) also edit:
# all variables with cvc23 (change to your paths) in: ~/HCP_Scripts_StepWise/hcp_setup_milgram_tcp_2023.sh
# ${FSL_FIX_CIFTIRW} in: ~/HCP_v2_prereqs/HCPpipelines-4.7.0/fix-1.06.15/settings.sh 
# ${FSL_FIX_CIFTIRW} in: ~/HCP_v2_prereqs/HCPpipelines-4.7.0/ICAFIX/settings.sh 

# ${HCPPIPEDIR} in: ~/HCP_v2_prereqs/HCPpipelines-4.7.0/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh

# 4. Be careful to note how your particular MR sequence might affect some of the parameters entered here. See "edit these" sections below; refer to HCP user guides and your scan protocols for more info.

# 5. Recommended: run all preFS, FS, postFS, fmriVol, and fmriSurf together. Then run restFix and taskFix together. Then run msmAll and dedriftResample together.

# NOTE: per participant, all steps take ~1.5-2 days, thus sbatch processing over slurm (or similar parallel processing) is recommended. 
# NOTE: for larger datasets, array jobs are useful, see: https://docs.ycrc.yale.edu/clusters-at-yale/job-scheduling/.

#########################
# Command line set-up script:

# EDIT THESE: change ${path_to_opts_script} 
# NOTE: script itself should not need to change. 

echo "Sourcing command line option functions..."
path_to_opts_script=/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/HCP_Scripts_StepWise/

source ${path_to_opts_script}opts_newPipe.shlib # command line option functions

########################

show_usage() {
    cat <<EOF
    
This script serves to run an individual participant through the HCP Pipeline, along with other necessary commands to fit their pipeline to the TCP Dataset/Yale HPC.

hcp_main_milgram_tcp_2023.sh

Usage: hcp_main_milgram_tcp_2023.sh [options]

    --server=<servername>                        (required) The name of the HPC server you're running this from (e.g., "milgram").
    --subj=<subjectID>                           (required) The participant ID, exactly as it is throughout project directories. 
    --dirSetUp=<"true">                          (optional) Input "true" to set up directory structure for this participant. 
                                                            Not currently supported; either TBA or will be removed.
    --anatomicalRecon=<"true">                   (optional) Input "true" to run a DICOM reconstruction of the anatomicals. 
                                                            Not currently supported; either TBA or will be removed. 
    --epiRecon=<"true">                          (optional) Input "true" to run a DICOM reconstruction of the EPIs. 
                                                            Not currently supported; either TBA or will be removed.
    --preFS=<"true">                             (optional) Input "true" to run pre-freesurfer HCP scripts. Required before all 
                                                            remaining steps.
    --FS=<"true">                                (optional) Input "true" to run freesurfer HCP scripts. Required before all 
                                                            remaining steps.
    --postFS=<"true">                            (optional) Input "true" to run the post-freesurfer HCP scripts. Required before 
                                                            all remaining steps.
    --fmriVol=<"true">                           (optional) Input "true" to run the fMRIVolume processing. Required before all 
                                                            remaining steps.
    --fmriSurf=<"true">                          (optional) Input "true" to run the fMRISurface processing. Required before all 
                                                            remaining steps.
    --restFix_SingleRun=<"true">                 (optional) Input "true" to run ICA-FIX on rest data, for each run separately. 
                                                            Required before msmAll_Rest_SingleRun and dedriftResample.
    --restFix_MultiRun_All=<"true">              (optional) Input "true" to run FIX-ICA on the rest data, all runs concatenated. 
                                                            Required before msmAll_Rest_MultiRun_All and dedriftResample.
    --restFix_MultiRun_ByPhase=<"true">          (optional) Input "true" to run FIX-ICA on the rest data, concatenated by phase 
                                                            encoding direction (e.g., rest runs 1 AP and 2 AP concatenated). 
                                                            Required before msmAll_Rest_MultiRun_ByPhase and dedriftResample.
    --taskFix_SingleRun=<"true">                 (optional) Input "true" to run ICA-FIX on task data, for each run separately. 
                                                            Required before msmAll_Task_SingleRun and dedriftResample.
    --taskFix_MultiRun_All=<"true">              (optional) Input "true" to run FIX-ICA on the task data, all runs concatenated. 
                                                            Required before msmAll_Task_MultiRun_All and dedriftResample.
    --taskFix_MultiRun_ByState=<"true">          (optional) Input "true" to run FIX-ICA on the task data, concatenated by task 
                                                            state/context (e.g., Stroop task AP and PA concatenated.). 
                                                            Required before msmAll_Task_MultiRun_ByState and dedriftResample.
    --msmAll_Rest_SingleRun=<"true">             (optional) Input "true" to run MSMAll multimodal surface alignment on single-run rest. 
                                                            Required before dedriftResample_Rest_SingleRun.
    --msmAll_Task_SingleRun=<"true">             (optional) Input "true" to run MSMAll multimodal surface alignment on single-run task. 
                                                            Required before dedriftResample_Task_SingleRun.   
    --msmAll_Rest_MultiRun_All=<"true">          (optional) Input "true" to run MSMAll multimodal surface alignment on multi-run rest (all runs concatenated). 
                                                            Required before dedriftResample_Rest_MultiRun_All. 
    --msmAll_Rest_MultiRun_All=<"true">          (optional) Input "true" to run MSMAll multimodal surface alignment on multi-run task (all runs concatenated). 
                                                            Required before dedriftResample_Task_MultiRun_All.                                                             
    --dedriftResample_Rest_SingleRun=<"true">    (optional) Input "true" to run DeDriftAndResample w.r.t. single-run resting-state data.
                                                            This is where MSM-All is applied.
    --dedriftResample_Task_SingleRun=<"true">    (optional) Input "true" to run DeDriftAndResample w.r.t. single-run task-state data.
                                                            This is where MSM-All is applied.
    --dedriftResample_Rest_MultiRun_All=<"true"> (optional) Input "true" to run DeDriftAndResample w.r.t. multi-run resting-state data (all runs concatenated).
                                                            This is where MSM-All is applied. 
    --dedriftResample_Task_MultiRun_All=<"true"> (optional) Input "true" to run DeDriftAndResample w.r.t. multi-run task-state data (all runs concatenated).
                                                            This is where MSM-All is applied.                                                             
EOF
    exit 1
}
      
opts_ShowVersionIfRequested $@

if opts_CheckForHelpRequest $@; then
    show_usage
fi

#########################
# Input Variables:

echo "Setting input variables..."
server=`opts_GetOpt1 "--server" $@`
subj=`opts_GetOpt1 "--subj" $@`
#dirSetUp=`opts_GetOpt1 "--dirSetUp" $@`
#anatomicalRecon=`opts_GetOpt1 "--anatomicalRecon" $@`
#epiRecon=`opts_GetOpt1 "--epiRecon" $@`
preFS=`opts_GetOpt1 "--preFS" $@`
FS=`opts_GetOpt1 "--FS" $@`
postFS=`opts_GetOpt1 "--postFS" $@`
fmriVol=`opts_GetOpt1 "--fmriVol" $@`
fmriSurf=`opts_GetOpt1 "--fmriSurf" $@`
restFix_SingleRun=`opts_GetOpt1 "--restFix_SingleRun" $@`
restFix_MultiRun_All=`opts_GetOpt1 "--restFix_MultiRun_All" $@`
restFix_MultiRun_ByPhase=`opts_GetOpt1 "--restFix_MultiRun_ByPhase" $@`
taskFix_SingleRun=`opts_GetOpt1 "--taskFix_SingleRun" $@`
taskFix_MultiRun_All=`opts_GetOpt1 "--taskFix_MultiRun_All" $@`
taskFix_MultiRun_ByState=`opts_GetOpt1 "--taskFix_MultiRun_ByState" $@`
msmAll_Rest_SingleRun=`opts_GetOpt1 "--msmAll_Rest_SingleRun" $@`
msmAll_Task_SingleRun=`opts_GetOpt1 "--msmAll_Task_SingleRun" $@`
msmAll_Rest_MultiRun_All=`opts_GetOpt1 "--msmAll_Rest_MultiRun_All" $@`
msmAll_Task_MultiRun_All=`opts_GetOpt1 "--msmAll_Task_MultiRun_All" $@`
dedriftResample_Rest_SingleRun=`opts_GetOpt1 "--dedriftResample_Rest_SingleRun" $@`
dedriftResample_Task_SingleRun=`opts_GetOpt1 "--dedriftResample_Task_SingleRun" $@`
dedriftResample_Rest_MultiRun_All=`opts_GetOpt1 "--dedriftResample_Rest_MultiRun_All" $@`
dedriftResample_Task_MultiRun_All=`opts_GetOpt1 "--dedriftResample_Task_MultiRun_All" $@`

#########################
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
########################

#########################
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
#########################

#########################
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
#########################

#########################
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
#########################

#########################
# Start first node of HCP Pipeline: PreFreeSurferPipeline
# NOTE: make sure to use the run where anatomicals were collected in your project
# NOTE: option to also pass gre fieldmaps using --fmapmag and --fmapphase
# NOTE: takes ~1 hour, adds ~1-1.5 GB 

# EDIT THESE: make sure to change the 4 files in elif>true section below to project-specific file names.

if [ -z "$preFS" ]; then
    echo "Skipping HCP minimal preprocess computational step 1: pre-freesurfer."
elif [ $preFS = true ]; then
    echo "Running HCP minimal preprocess computational step 1: pre-freesurfer..."
    t1FilePreFS="${unprocesseddir}/anat/${subj}_run-01_T1w.nii.gz"
    t2FilePreFS="${unprocesseddir}/anat/${subj}_run-01_T2w.nii.gz"
    seNegFilePreFS="${unprocesseddir}/fmap/${subj}_dir-ap_epi.nii.gz"
    sePosFilePreFS="${unprocesseddir}/fmap/${subj}_dir-pa_epi.nii.gz"
    ${HCPPipe}/PreFreeSurfer/PreFreeSurferPipeline.sh --path="${datadir}" --subject="${subj}" --t1="$t1FilePreFS" --t2="$t2FilePreFS" --t1template="${t1template}" --t1templatebrain="${t1templatebrain}" --t1template2mm="${t1template2mm}" --t2template="${t2template}" --t2templatebrain="$t2templatebrain" --t2template2mm="$t2template2mm" --templatemask="$templatemask" --template2mmmask="$template2mmmask" --brainsize="${brainsize}" --fmapmag="NONE" --fnirtconfig="${HCPPipe}/global/config/T1_2_MNI152_2mm.cnf" --SEPhaseNeg="$seNegFilePreFS" --SEPhasePos="$sePosFilePreFS" --echospacing="$DwellTime_SE" --seunwarpdir="${seunwarpdir}" --t1samplespacing="$T1wSampleSpacing" --t2samplespacing="$T2wSampleSpacing" --unwarpdir="z" --grdcoeffs="NONE" --avgrdcmethod="${SPIN_ECHO_METHOD_OPT}" --topupconfig="${HCPPIPEDIR_Config}/b02b0.cnf" --printcom=""
fi
#########################

#########################
# Start second node of HCP Pipeline: FreeSurferPipeline
# NOTE: variable in elif>true section limits the number of threads used by FS
# NOTE: should not need to change file names (set by prefreesurfer node above if it ran fully and properly)

if [ -z "$FS" ]; then
    echo "Skipping HCP minimal preprocessing computational step 2: freesurfer."
elif [ $FS = true ]; then
    export OMP_NUM_THREADS=3
    echo "Running HCP minimal preprocessing computational step 2: freesurfer..."
    ${HCPPipe}/FreeSurfer/FreeSurferPipeline.sh --subject="${subj}" --subjectDIR="${datadir}/${subj}/T1w" --t1="${datadir}/${subj}/T1w/T1w_acpc_dc_restore.nii.gz" --t1brain="${datadir}/${subj}/T1w/T1w_acpc_dc_restore_brain.nii.gz" --t2="${datadir}/${subj}/T1w/T2w_acpc_dc_restore.nii.gz"
fi
#########################

#########################
# THIRD node of HCP Pipeline: PostFreeSurferPipeline
# Should not need to edit. 

if [ -z "$postFS" ]; then
    echo "Skipping HCP minimal preprocessing computational step 3: post-freesurfer."
elif [ $postFS = true ]; then
    echo "Running HCP minimal preprocessing computational step 3: post-freesurfer..."
    ${HCPPipe}/PostFreeSurfer/PostFreeSurferPipeline.sh --path="${datadir}" --subject="${subj}" --surfatlasdir="$SurfaceAtlasDIR" --grayordinatesdir="$GrayordinatesSpaceDIR" --grayordinatesres="$GrayordinatesResolutions" --hiresmesh="$HighResMesh" --lowresmesh="$LowResMeshes" --subcortgraylabels="$SubcorticalGrayLabels" --freesurferlabels="$FreeSurferLabels" --refmyelinmaps="$ReferenceMyelinMaps" --regname="$RegName"

fi
#########################

#########################
# FOURTH node of HCP Pipeline: GenericfMRIVolumeProcessing

# EDIT THESE: TCP datset specific edits: 1 block for each of the 4 states (+ AP/PA) (7 total): rest 1 (AP and PA), rest 2 (AP and PA), stroop (AP and PA), hammer (AP only). i.e., there are code blocks below fo each separately named functional sequence. 

# NOTE: need to iterate through each rest scan, and then each task scan
# NOTE: in this version you have to specify --biascorrection method; following parameter is taken from the HCP volume example script; previous Cole lab version of the pipeline might have used LEGACY, but SEBASED is better. So for the BiasCorrection parameter below the options are: NONE, LEGACY, or SEBASED. LEGACY uses the T1w bias field, SEBASED calculates bias field from spin echo images (which requires TOPUP distortion correction)

# NOTE: in each code block below (again, these are for the different functional sequences), the fmriname variable is the output name. 

if [ -z "$fmriVol" ]; then
    echo "Skipping HCP minimal preprocessing computational step 4: fMRI volume processing."
elif [ $fmriVol = true ]; then
    echo "Running HCP minimal preprocessing computational step 4: fMRI volume processing..."
    BiasCorrection="SEBASED"
    
    for runName in "${funcRunNames_Present[@]}" ; do        
        echo "Running fMRI Volume processing on ${runName} scan..." 
        if [[ "$runName" == *"AP"* ]]; then
            unwarpdir="-y" # A>>P
        elif [[ "$runName" == *"PA"* ]]; then
            unwarpdir="y" # P>>A
        fi
        
        fmriname="task-${runName}_bold"
        fmritcs="${unprocesseddir}/func/${subj}_task-${runName}_bold.nii.gz"
        
        fmriscout="NONE" # usually use SBRef, but we don't have those, so "None" will use 1st vol of timeseries
        fmap_neg_ap="${unprocesseddir}/fmap/${subj}_dir-ap_epi.nii.gz"
        fmap_pos_pa="${unprocesseddir}/fmap/${subj}_dir-pa_epi.nii.gz"
        dcMethodHere="TOPUP"
        ${HCPPipe}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh --path="${datadir}" --subject="${subj}" --fmritcs="${fmritcs}" --fmriname="${fmriname}" --fmrires="$fmrires" --biascorrection=${BiasCorrection} --dcmethod=${dcMethodHere} --fmriscout="${fmriscout}" --gdcoeffs="NONE" --echospacing="$DwellTime_fMRI" --unwarpdir="${unwarpdir}" --SEPhaseNeg="${fmap_neg_ap}" --SEPhasePos="${fmap_pos_pa}" --topupconfig="${HCPPIPEDIR_Config}/b02b0.cnf"
    done
fi
#########################

#########################
# FIFTH node of HCP Pipeline: GenericfMRISurfaceProcessing
# EDIT THESE: one code block for each of the separately named functinal sequences; this is project specific. 

# NOTE: conventions like fmriname (output) are same as above (volume step 4). 

if [ -z "$fmriSurf" ]; then
    echo "Skipping HCP minimal preprocessing computational step 5: fMRI surface processing."
elif [ $fmriSurf = true ]; then
    echo "Running HCP minimal preprocessing computational step 5: fMRI surface processing..."
    for runName in "${funcRunNames_Present[@]}" ; do 
        echo "Running fMRI Surface processing on ${runName} scan..." 
        fmriname="task-${runName}_bold"
        ${HCPPipe}/fMRISurface/GenericfMRISurfaceProcessingPipeline.sh --path="${datadir}" --subject="${subj}" --fmriname="${fmriname}" --fmrires="$fmrires" --lowresmesh="$LowResMeshes" --smoothingFWHM=$SmoothingFWHM --grayordinatesres="$GrayordinatesResolutions" --regname=$RegName
    done
fi
#########################

#########################
# SIXTH node of HCP Pipeline, part a: ICA-FIX for resting-state data, SINGLE RUN (i.e., run ICA-FIX on each resting-state functional run separately). 
# This step applies spatial ICA (via MELODIC, on volume space data) and identifies artifacts via ML classifier (via FIX).
# NOTE: This is needed for MSM-All (see following computational steps/"nodes").

# NOTES: 
# First (part a, here), applying *separately* to any runs acquired during separate sessions; combine if during the same session. Note this is ok when separate session scans are sufficiently long, >10 min, to provide good solutions, based on the Salimi-Khorshid 2014 paper).
# Second (part b, below), applying multi-run FIX to all resting states for purposes of data release (although it will be up to user which they want to use. 
# Outputs from Fix-ICA will be used for MSMall i.e. to provide the RSN spatial maps (between area FC) that constitute 1 of the 4 modalities. It might also be providing the rest visuotopic maps.

# EDIT THESE: ${fMRINames} and ${ConcatNames} to have each REST sequence (separated by @), following fmriname (output) conventions of prior steps. 
# NOTE: may also want to look at ${domot}, ${bandpass}, ${MRTrainingData}, ${SRTrainingData}, ${FixThreshold}, and ${DeleteIntermediates} below.

if [ -z "$restFix_SingleRun" ]; then
    echo "Skipping HCP minimal preprocessing computational step 6, part a: fMRI rest ICA-FIX module (single run)."
elif [ $restFix_SingleRun = true ]; then
    echo "Running HCP minimal preprocessing computational step 6, part a: fMRI rest ICA-FIX module (single run)..."
    
    # EDIT: Either set this to a downloaded version of FIX, or keep blank "" and use $FSL_FIXDIR specified in EnvironmentScript.
    DEFAULT_FIXDIR="${HCPPipe}/fix-1.06.15/" 
    
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    FixDir="${DEFAULT_FIXDIR}"
    source "$EnvironmentScript"

    # If DEFAULT_FIXDIR is set, or --FixDir argument was used, then use that to override the setting of FSL_FIXDIR in EnvironmentScript
    if [ ! -z ${FixDir} ]; then
        export FSL_FIXDIR=${FixDir}
    fi
    
    # EDIT: $fMRINames is used here for single run ICA-FIX. Use @ separated run names (that match sections above) to iterate/loop over. 
    #fMRINames="task-restAP_run-01_bold@task-restPA_run-01_bold@task-restAP_run-02_bold@task-restPA_run-02_bold"
    fMRINames="${fixMSM_Rest_SingleRun_Str}"
    
    # EDIT: $ConcatNames is left blank for single run ICA-FIX. See next section for more on multi-run ICA-FIX.
    ConcatNames=""
    
    # NOTE: temporal high-pass full-width filter to use (2 * sigma; in seconds); cannot be 0 for single-run FIX. 
    # Using the same bandpass filter as prior steps (likely value is 2000) is a common choice. 
    bandpassHere=${bandpass} 
    #bandpassHere=0
    
    # EDIT: $domot will determine whether or not to regress motion parameters (24 regressors) out of the data as part of FIX (TRUE or FALSE)
    domot=FALSE

    # Likely does not neeed editing: set the training data used in multi-run fix mode
    MRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_Style_Single_Multirun_Dedrift.RData"

    # Likely does not need editing: set the training data used in single-run fix mode
    SRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_hp2000.RData"

    # EDIT: set FIX threshold (controls sensitivity/specificity tradeoff)
    FixThreshold=10

    # EDIT: whether or not to delete highpass intermediate files (not really recommended; especially not in the multi-run sections to follow).
    DeleteIntermediates=FALSE
    
    ResultsFolder="${datadir}/${subj}/MNINonLinear/Results/"

    # Perform single-run FIX: 
    FixScript=${HCPPIPEDIR}/ICAFIX/hcp_fix
    fMRINamesFlat=$(echo ${fMRINames} | sed 's/[@%]/ /g')

    for fMRIName in ${fMRINamesFlat}; do
        echo "  ${fMRIName}"

        InputFile="${ResultsFolder}/${fMRIName}/${fMRIName}"

        cmd=("${FixScript}" "${InputFile}" ${bandpassHere} ${domot} "${SRTrainingData}" ${FixThreshold} "${DeleteIntermediates}")
        echo "About to run: ${cmd[*]}"
        "${cmd[@]}"
    done
    
    #sh ${path_to_opts_script}post_icafix_file_rename_scratch.sh --subj="${subj}" --fixrun="${restFix_SingleRun}"
    
fi

#########################

#########################
# SIXTH node of HCP Pipeline, part b: ICA-FIX for resting-state data, MULTI RUN. 
# Same as above, but applies ICA-FIX to multiple runs at once. With this option (restFix_MultiRun_All), all resting-state runs are concatenated. 

# EDIT THESE: ${fMRINames} and ${ConcatNames}. See below.
# NOTE: may also want to look at ${domot}, ${bandpass}, ${MRTrainingData}, ${SRTrainingData}, ${FixThreshold}, and ${DeleteIntermediates} below.

if [ -z "$restFix_MultiRun_All" ]; then
    echo "Skipping HCP minimal preprocessing computational step 6, part b: fMRI rest ICA-FIX module (multi-run; all resting-state runs)."
elif [ $restFix_MultiRun_All = true ]; then
    echo "Running HCP minimal preprocessing computational step 6, part b: fMRI rest ICA-FIX module (multi-run; all resting-state runs)..."
    
    # EDIT: Either set this to a downloaded version of FIX, or keep blank "" and use $FSL_FIXDIR specified in EnvironmentScript.
    DEFAULT_FIXDIR="${HCPPipe}/fix-1.06.15/"
    
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    FixDir="${DEFAULT_FIXDIR}"
    source "$EnvironmentScript"

    if [ ! -z ${FixDir} ]; then
        export FSL_FIXDIR=${FixDir}
    fi
    
    # EDIT: this still needs to be set for multi-run ICA-FIX because it will reference this list.
    #fMRINames="task-restAP_run-01_bold@task-restPA_run-01_bold@task-restAP_run-02_bold@task-restPA_run-02_bold"
    fMRINames="${fixMSM_Rest_SingleRun_Str}"
    
    # EDIT: If you wish to run "multi-run" (concatenated) FIX, specify the names to give the concatenated output files.
    # In this case, reference all the rest names together as follows: 
    ConcatNames="Rest_01_02_AP_PA"
    
    # NOTE: temporal high-pass full-width filter to use (2 * sigma; in seconds); cannot be 0 for single-run FIX. 
    # MR FIX also supports bandpassHere=0 for a linear detrend, or "pdX" for a polynomial detrend of order X.
    # e.g., bandpassHere=pd1 is linear detrend (functionally equivalent to bandpassHere=0) bandpassHere=pd2 is a quadratic detrend.
    # Multiple sources recommend using 0 for multi-run so I'm going with that but will double check with others.
    #bandpassHere=${bandpass} 
    bandpassHere=0 

    # EDIT: set whether or not to regress motion parameters (24 regressors) out of the data as part of FIX (TRUE or FALSE)
    domot=FALSE

    MRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_Style_Single_Multirun_Dedrift.RData"
    SRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_hp2000.RData"
    FixThreshold=10
    DeleteIntermediates=FALSE
    ResultsFolder="${datadir}/${subj}/MNINonLinear/Results/"
    
    # Generate arrays to check number of concat groups: 
    IFS=' @' read -a concatarray <<< "${ConcatNames}"
    IFS=% read -a fmriarray <<< "${fMRINames}"
    
    if ((${#concatarray[@]} != ${#fmriarray[@]})); then
        echo "ERROR: number of names in ConcatNames does not match number of fMRINames groups"
        exit 1
    fi

    for ((i = 0; i < ${#concatarray[@]}; ++i))
    do
        ConcatName="${concatarray[$i]}"
        fMRINamesGroup="${fmriarray[$i]}"
        # multi-run FIX
        FixScript=${HCPPIPEDIR}/ICAFIX/hcp_fix_multi_run
        ConcatFileName="${ResultsFolder}/${ConcatName}/${ConcatName}"

        IFS=' @' read -a namesgrouparray <<< "${fMRINamesGroup}"
        InputFile=""
        for fMRIName in "${namesgrouparray[@]}"; do
            if [[ "$InputFile" == "" ]]; then
                InputFile="${ResultsFolder}/${fMRIName}/${fMRIName}"
            else
                InputFile+="@${ResultsFolder}/${fMRIName}/${fMRIName}"
            fi
        done

        echo "  InputFile: ${InputFile}"

        cmd=("${FixScript}" "${InputFile}" ${bandpassHere} "${ConcatFileName}" ${domot} "${MRTrainingData}" ${FixThreshold} "${DeleteIntermediates}")
        echo "About to run: ${cmd[*]}"
        "${cmd[@]}"
    done

    #sh ${path_to_opts_script}post_icafix_file_rename_scratch.sh --subj="${subj}" --fixrun="${restFix_MultiRun_All}"

fi

#########################

#########################
# SIXTH node of HCP Pipeline, part c: ICA-FIX for resting-state data, MULTI RUN. 
# Same as above, but applies ICA-FIX to multiple runs at once. With this option (restFix_MultiRun_ByPhase), the 2 AP and PA phase-encoded rest runs are each concatenated.

# EDIT THESE: ${fMRINames} and ${ConcatNames}. See below.
# NOTE: may also want to look at ${domot}, ${bandpass}, ${MRTrainingData}, ${SRTrainingData}, ${FixThreshold}, and ${DeleteIntermediates} below.

if [ -z "$restFix_MultiRun_ByPhase" ]; then
    echo "Skipping HCP minimal preprocessing computational step 6, part c: fMRI rest ICA-FIX module (multi-run; concatenated by phase-encoding direction)."
elif [ $restFix_MultiRun_ByPhase = true ]; then
    echo "Running HCP minimal preprocessing computational step 6, part c: fMRI rest ICA-FIX module (multi-run; concatenated by phase-encoding direction)..."
    
    # EDIT: Either set this to a downloaded version of FIX, or keep blank "" and use $FSL_FIXDIR specified in EnvironmentScript.
    DEFAULT_FIXDIR="${HCPPipe}/fix-1.06.15/"
    
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    FixDir="${DEFAULT_FIXDIR}"
    source "$EnvironmentScript"

    if [ ! -z ${FixDir} ]; then
        export FSL_FIXDIR=${FixDir}
    fi
    
    # EDIT: this still needs to be set for multi-run ICA-FIX because it will reference this list.
    fMRINames="Rest_01_AP@Rest_01_PA@Rest_02_AP@Rest_02_PA"

    # EDIT: If you wish to run "multi-run" (concatenated) FIX, specify the names to give the concatenated output files.
    # In this case, reference all the rest names together as follows: 
    ConcatNames="Rest_01_02_AP@Rest_01_02_PA"
    
    # NOTE: temporal high-pass full-width filter to use (2 * sigma; in seconds); cannot be 0 for single-run FIX. 
    # MR FIX also supports bandpassHere=0 for a linear detrend, or "pdX" for a polynomial detrend of order X.
    # e.g., bandpassHere=pd1 is linear detrend (functionally equivalent to bandpassHere=0) bandpassHere=pd2 is a quadratic detrend.
    # Keeping at 2000 for consistency with single run. 
    bandpassHere=${bandpass} 

    # EDIT: set whether or not to regress motion parameters (24 regressors) out of the data as part of FIX (TRUE or FALSE)
    domot=FALSE

    MRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_Style_Single_Multirun_Dedrift.RData"
    SRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_hp2000.RData"
    FixThreshold=10
    DeleteIntermediates=FALSE
    ResultsFolder="${datadir}/${subj}/MNINonLinear/Results/"
    
    # Generate arrays to check number of concat groups: 
    IFS=' @' read -a concatarray <<< "${ConcatNames}"
    IFS=% read -a fmriarray <<< "${fMRINames}"
    
    if ((${#concatarray[@]} != ${#fmriarray[@]})); then
        echo "ERROR: number of names in ConcatNames does not match number of fMRINames groups"
        exit 1
    fi

    for ((i = 0; i < ${#concatarray[@]}; ++i))
    do
        ConcatName="${concatarray[$i]}"
        fMRINamesGroup="${fmriarray[$i]}"
        # multi-run FIX
        FixScript=${HCPPIPEDIR}/ICAFIX/hcp_fix_multi_run
        ConcatFileName="${ResultsFolder}/${ConcatName}/${ConcatName}"

        IFS=' @' read -a namesgrouparray <<< "${fMRINamesGroup}"
        InputFile=""
        for fMRIName in "${namesgrouparray[@]}"; do
            if [[ "$InputFile" == "" ]]; then
                InputFile="${ResultsFolder}/${fMRIName}/${fMRIName}"
            else
                InputFile+="@${ResultsFolder}/${fMRIName}/${fMRIName}"
            fi
        done

        echo "  InputFile: ${InputFile}"

        cmd=("${FixScript}" "${InputFile}" ${bandpassHere} "${ConcatFileName}" ${domot} "${MRTrainingData}" ${FixThreshold} "${DeleteIntermediates}")
        echo "About to run: ${cmd[*]}"
        "${cmd[@]}"
    done
    
    #sh ${path_to_opts_script}post_icafix_file_rename_scratch.sh --subj="${subj}" --fixrun="${restFix_MultiRun_ByPhase}"

fi
#########################

#########################
# SIXTH node of HCP Pipeline, part d: ICA-FIX for task-state data, SINGLE RUN (i.e., run ICA-FIX on each task-state functional run separately). 

# EDIT THESE: ${fMRINames} and ${ConcatNames} to have each REST sequence (separated by @), following fmriname (output) conventions of prior steps. 
# NOTE: may also want to look at ${domot}, ${bandpass}, ${MRTrainingData}, ${SRTrainingData}, ${FixThreshold}, and ${DeleteIntermediates} below.

if [ -z "$taskFix_SingleRun" ]; then
    echo "Skipping HCP minimal preprocessing computational step 6, part d: fMRI task ICA-FIX module (single run)."
elif [ $taskFix_SingleRun = true ]; then
    echo "Running HCP minimal preprocessing computational step 6, part d: fMRI task ICA-FIX module (single run)..."
    
    # EDIT: Either set this to a downloaded version of FIX, or keep blank "" and use $FSL_FIXDIR specified in EnvironmentScript.
    DEFAULT_FIXDIR="${HCPPipe}/fix-1.06.15/" 
    
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    FixDir="${DEFAULT_FIXDIR}"
    source "$EnvironmentScript"

    # If DEFAULT_FIXDIR is set, or --FixDir argument was used, then use that to override the setting of FSL_FIXDIR in EnvironmentScript
    if [ ! -z ${FixDir} ]; then
        export FSL_FIXDIR=${FixDir}
    fi
    
    # EDIT: $fMRINames is used here for single run ICA-FIX. Use @ separated run names (that match sections above) to iterate/loop over. 
    #fMRINames="Task_Stroop_AP@Task_Stroop_PA@Task_Hammer_AP"
    fMRINames="${fixMSM_Task_SingleRun_Str}"
    
    # EDIT: $ConcatNames is left blank for single run ICA-FIX. See next section for more on multi-run ICA-FIX.
    ConcatNames=""
    
    # NOTE: temporal high-pass full-width filter to use (2 * sigma; in seconds); cannot be 0 for single-run FIX. 
    # Using the same bandpass filter as prior steps (likely value is 2000) is a common choice. 
    bandpassHere=${bandpass} 
    
    # EDIT: $domot will determine whether or not to regress motion parameters (24 regressors) out of the data as part of FIX (TRUE or FALSE)
    domot=FALSE

    # Likely does not neeed editing: set the training data used in multi-run fix mode
    MRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_Style_Single_Multirun_Dedrift.RData"

    # Likely does not need editing: set the training data used in single-run fix mode
    SRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_hp2000.RData"

    # EDIT: set FIX threshold (controls sensitivity/specificity tradeoff)
    FixThreshold=10

    # EDIT: whether or not to delete highpass intermediate files (not really recommended; especially not in the multi-run sections to follow).
    DeleteIntermediates=FALSE
    
    ResultsFolder="${datadir}/${subj}/MNINonLinear/Results/"

    # Perform single-run FIX: 
    FixScript=${HCPPIPEDIR}/ICAFIX/hcp_fix
    fMRINamesFlat=$(echo ${fMRINames} | sed 's/[@%]/ /g')

    for fMRIName in ${fMRINamesFlat}; do
        echo "  ${fMRIName}"

        InputFile="${ResultsFolder}/${fMRIName}/${fMRIName}"

        cmd=("${FixScript}" "${InputFile}" ${bandpassHere} ${domot} "${SRTrainingData}" ${FixThreshold} "${DeleteIntermediates}")
        echo "About to run: ${cmd[*]}"
        "${cmd[@]}"
    done
    
    #sh ${path_to_opts_script}post_icafix_file_rename_scratch.sh --subj="${subj}" --fixrun="${taskFix_SingleRun}"
    
fi
#########################

#########################
# SIXTH node of HCP Pipeline, part e: ICA-FIX for task-state data, MULTI RUN. 
# Same as above, but applies ICA-FIX to multiple runs at once. With this option (taskFix_MultiRun_All), all task-state runs are concatenated. 

# EDIT THESE: ${fMRINames} and ${ConcatNames}. See below.
# NOTE: may also want to look at ${domot}, ${bandpass}, ${MRTrainingData}, ${SRTrainingData}, ${FixThreshold}, and ${DeleteIntermediates} below.

if [ -z "$taskFix_MultiRun_All" ]; then
    echo "Skipping HCP minimal preprocessing computational step 6, part e: fMRI rest ICA-FIX module (multi-run; all task-state runs)."
elif [ $taskFix_MultiRun_All = true ]; then
    echo "Running HCP minimal preprocessing computational step 6, part e: fMRI rest ICA-FIX module (multi-run; all task-state runs)..."
    
    # EDIT: Either set this to a downloaded version of FIX, or keep blank "" and use $FSL_FIXDIR specified in EnvironmentScript.
    DEFAULT_FIXDIR="${HCPPipe}/fix-1.06.15/"
    
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    FixDir="${DEFAULT_FIXDIR}"
    source "$EnvironmentScript"

    if [ ! -z ${FixDir} ]; then
        export FSL_FIXDIR=${FixDir}
    fi
    
    # EDIT: this still needs to be set for multi-run ICA-FIX because it will reference this list.
    fMRINames="${fixMSM_Task_SingleRun_Str}"
    
    # EDIT: If you wish to run "multi-run" (concatenated) FIX, specify the names to give the concatenated output files.
    # In this case, reference all the rest names together as follows: 
    ConcatNames="Task_Stroop_Hammer_AP_PA"
    
    # NOTE: temporal high-pass full-width filter to use (2 * sigma; in seconds); cannot be 0 for single-run FIX. 
    # MR FIX also supports bandpassHere=0 for a linear detrend, or "pdX" for a polynomial detrend of order X.
    # e.g., bandpassHere=pd1 is linear detrend (functionally equivalent to bandpassHere=0) bandpassHere=pd2 is a quadratic detrend.
    # Multiple sources recommend using 0 for multi-run so I'm going with that but will double check with others.
    #bandpassHere=${bandpass} 
    bandpassHere=0 

    # EDIT: set whether or not to regress motion parameters (24 regressors) out of the data as part of FIX (TRUE or FALSE)
    domot=FALSE

    MRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_Style_Single_Multirun_Dedrift.RData"
    SRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_hp2000.RData"
    FixThreshold=10
    DeleteIntermediates=FALSE
    ResultsFolder="${datadir}/${subj}/MNINonLinear/Results/"
    
    # Generate arrays to check number of concat groups: 
    IFS=' @' read -a concatarray <<< "${ConcatNames}"
    IFS=% read -a fmriarray <<< "${fMRINames}"
    
    if ((${#concatarray[@]} != ${#fmriarray[@]})); then
        echo "ERROR: number of names in ConcatNames does not match number of fMRINames groups"
        exit 1
    fi

    for ((i = 0; i < ${#concatarray[@]}; ++i))
    do
        ConcatName="${concatarray[$i]}"
        fMRINamesGroup="${fmriarray[$i]}"
        # multi-run FIX
        FixScript=${HCPPIPEDIR}/ICAFIX/hcp_fix_multi_run
        ConcatFileName="${ResultsFolder}/${ConcatName}/${ConcatName}"

        IFS=' @' read -a namesgrouparray <<< "${fMRINamesGroup}"
        InputFile=""
        for fMRIName in "${namesgrouparray[@]}"; do
            if [[ "$InputFile" == "" ]]; then
                InputFile="${ResultsFolder}/${fMRIName}/${fMRIName}"
            else
                InputFile+="@${ResultsFolder}/${fMRIName}/${fMRIName}"
            fi
        done

        echo "  InputFile: ${InputFile}"

        cmd=("${FixScript}" "${InputFile}" ${bandpassHere} "${ConcatFileName}" ${domot} "${MRTrainingData}" ${FixThreshold} "${DeleteIntermediates}")
        echo "About to run: ${cmd[*]}"
        "${cmd[@]}"
    done

    #sh ${path_to_opts_script}post_icafix_file_rename_scratch.sh --subj="${subj}" --fixrun="${restFix_MultiRun_All}"

fi

#########################

#########################
# SIXTH node of HCP Pipeline, part f: ICA-FIX for task-state data, MULTI RUN. 
# Same as above, but applies ICA-FIX to multiple runs at once. With this option (taskFix_MultiRun_ByState), the AP and PA phase-encoded task runs (Stroop) are concatenated.

# EDIT THESE: ${fMRINames} and ${ConcatNames}. See below.
# NOTE: may also want to look at ${domot}, ${bandpass}, ${MRTrainingData}, ${SRTrainingData}, ${FixThreshold}, and ${DeleteIntermediates} below.

if [ -z "$taskFix_MultiRun_ByState" ]; then
    echo "Skipping HCP minimal preprocessing computational step 6, part f: fMRI rest ICA-FIX module (multi-run; concatenated by task state)."
elif [ $taskFix_MultiRun_ByState = true ]; then
    echo "Running HCP minimal preprocessing computational step 6, part f: fMRI rest ICA-FIX module (multi-run; concatenated by task state)..."
    
    # EDIT: Either set this to a downloaded version of FIX, or keep blank "" and use $FSL_FIXDIR specified in EnvironmentScript.
    DEFAULT_FIXDIR="${HCPPipe}/fix-1.06.15/"
    
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    FixDir="${DEFAULT_FIXDIR}"
    source "$EnvironmentScript"

    if [ ! -z ${FixDir} ]; then
        export FSL_FIXDIR=${FixDir}
    fi
    
    # EDIT: this still needs to be set for multi-run ICA-FIX because it will reference this list.
    fMRINames="Task_Stroop_AP@Task_Stroop_PA@Task_Hammer_AP"

    # EDIT: If you wish to run "multi-run" (concatenated) FIX, specify the names to give the concatenated output files.
    # In this case, reference all the rest names together as follows: 
    ConcatNames="Task_Stroop_AP_PA"
    
    # NOTE: temporal high-pass full-width filter to use (2 * sigma; in seconds); cannot be 0 for single-run FIX. 
    # MR FIX also supports bandpassHere=0 for a linear detrend, or "pdX" for a polynomial detrend of order X.
    # e.g., bandpassHere=pd1 is linear detrend (functionally equivalent to bandpassHere=0) bandpassHere=pd2 is a quadratic detrend.
    # Keeping at 2000 for consistency with single run. 
    bandpassHere=${bandpass} 

    # EDIT: set whether or not to regress motion parameters (24 regressors) out of the data as part of FIX (TRUE or FALSE)
    domot=FALSE

    MRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_Style_Single_Multirun_Dedrift.RData"
    SRTrainingData="${DEFAULT_FIXDIR}/training_files/HCP_hp2000.RData"
    FixThreshold=10
    DeleteIntermediates=FALSE
    ResultsFolder="${datadir}/${subj}/MNINonLinear/Results/"
    
    # Generate arrays to check number of concat groups: 
    IFS=' @' read -a concatarray <<< "${ConcatNames}"
    IFS=% read -a fmriarray <<< "${fMRINames}"
    
    if ((${#concatarray[@]} != ${#fmriarray[@]})); then
        echo "ERROR: number of names in ConcatNames does not match number of fMRINames groups"
        exit 1
    fi

    for ((i = 0; i < ${#concatarray[@]}; ++i))
    do
        ConcatName="${concatarray[$i]}"
        fMRINamesGroup="${fmriarray[$i]}"
        # multi-run FIX
        FixScript=${HCPPIPEDIR}/ICAFIX/hcp_fix_multi_run
        ConcatFileName="${ResultsFolder}/${ConcatName}/${ConcatName}"

        IFS=' @' read -a namesgrouparray <<< "${fMRINamesGroup}"
        InputFile=""
        for fMRIName in "${namesgrouparray[@]}"; do
            if [[ "$InputFile" == "" ]]; then
                InputFile="${ResultsFolder}/${fMRIName}/${fMRIName}"
            else
                InputFile+="@${ResultsFolder}/${fMRIName}/${fMRIName}"
            fi
        done

        echo "  InputFile: ${InputFile}"

        cmd=("${FixScript}" "${InputFile}" ${bandpassHere} "${ConcatFileName}" ${domot} "${MRTrainingData}" ${FixThreshold} "${DeleteIntermediates}")
        echo "About to run: ${cmd[*]}"
        "${cmd[@]}"
    done
    
    #sh ${path_to_opts_script}post_icafix_file_rename_scratch.sh --subj="${subj}" --fixrun="${taskFix_MultiRun_ByState}"

fi
#########################

#########################
# SEVENTH node of HCP Pipeline, part a: MSM-All, to perform multi-modal surface alignment.
# This version (msmAll_Rest_SingleRun) is performed on each rest run separately and corresponds to restFix_SingleRun above. 

# NOTES: 
# MSMall computes the transform, whereas DedriftAndResample (8th step/node) corrects (dedrifts) the transform AND actually applies it in one step, and resamples from native to standard grayordinates.

# fMRINames should only contain rest scans, as this is the module where RSN maps and visuotopic FC maps (2 of the 4 modalities used for alignment) are generated
# Details from Glasser 2016 supplementary methods (2.3): MSMall performs Weighted spatial multiple regression (over 2 rounds) is used to derive 'refined subject-specific spatial maps', for RSN network maps; mapping group ICA template maps (representing likely canonical RSNs) with subject ICA FIX maps in a refined way.

# After performing the weighted regression to generate subject-specific RSN info, MSMall was performed as follows (Glasser 2016 supplement, 2.4):
# The following 44 maps were jointly used in the final iteration of MSMAll: 34 RSNs (from Fix ICA), the subject's myelin map, eight V1-based rfMRI visotopic regressor maps (see below 4.4; based on FC gradients), and a binary non-cortical medial wall ROI (i.e. the region of the surface mesh that does not contain neocortical grey matter). Group versions of all these maps served as the multimodal registration target.

# TAKE HOME MESSAGE: Alignment of these subject-specific maps with their corresponding group templates (all represented as spherical surfaces) was performed using modified versions of the MSM algorithm reported in Robinson et al 2014.

# EDIT THESE: for the elif>true section (i.e., project specific):
# See notes in the elif>true section below for single-run (SR) vs multi-run (MR) options. 
# NOTE: SR usage of @ gives separated list of scans to perform MSMall alignment on: performs concatenation of rest scans (across runs/sessions), and generation of subject RSN ICA (after regression with group RSN templates). This is slightly different then MR usage of @: use ICA-FIX results that were concatenated beforehand. 
# OutfMRIName: name to give to single subject "scan">. In both SR/MR cases, there is concatenation, so think of a good way to distinguish these. 
# fMRIProcSTRING: Identification for FIX cleaned dtseries to use. The dense timeseries files used will be named <fmri_name>_<fmri_proc_string>.dtseries.nii where fmri_name> is each of the fMRIs specified in the <fMRI Names> list and <fmri_proc_string> is this specified value
# MSMAllTemplates: path to group templates generated in Glasser 2016 from group ICA - weighted regression is used to generate subject-specific maps, which are then used for MSMall alignment (in 2 steps)
# RegName_MSMall: name to give output registration.
# InRegName: input registration - from PostFreesurfer step (i.e. MSMSulc).
# MatlabMode: Mode=0 compiled Matlab, Mode=1 interpreted Matlab

# Note for --high-pass: Use HighPass = 2000 for single-run (SR) FIX data, HighPass = 0 for multi-run (MR) FIX data

if [ -z "$msmAll_Rest_SingleRun" ]; then
    echo "Skipping HCP minimal preprocessing computational step 7, step a: MSM-All multi-modal surface alignment (single-run resting-state)."
elif [ $msmAll_Rest_SingleRun = true ]; then
    echo "Running HCP minimal preprocessing computational step 7, step a: MSM-All multi-modal surface alignment (single-run resting-state)..."
    
    #Set up additional pipeline environment variables and software
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    source "$EnvironmentScript"

    # fMRINames is for single-run (SR) FIX data, set multi-run (MR) FIX settings to empty. If doing MR, set: fMRINames=""
    #fMRINames="task-restAP_run-01_bold@task-restPA_run-01_bold@task-restAP_run-02_bold@task-restPA_run-02_bold"
    fMRINames="${fixMSM_Rest_SingleRun_Str}"
    
    # If SR: OutfMRIName="All_Rest". If MR: this is the FIX output concat name for this new MSMAll run of MR FIX; e.g., OutfMRIName="MultiRun_Rest"
    OutfMRIName="All_Rest"
    
    # Name to reflect high pass setting; identification for FIX cleaned dtseries to use. The dense timeseries files used will be named <fmri_name>_<fmri_proc_string>.dtseries.nii where <fmri_name> is each of the fMRIs specified in the <fMRI Names> list and <fmri_proc_string> is this specified value
    fMRIProcSTRING="_Atlas_hp${bandpass}_clean"
    
    # If SR, set to: "". If MR: this is the original MR FIX parameter for what to concatenate. List all single runs from one concatenated group separated with @.
    mrfixNames=""
    
    # If SR, set to: "". If MR: this is the original MR FIX concatenated name (only one group); e.g., mrfixConcatName="fMRI_CONCAT"
    mrfixConcatName=""
    
    # If SR, set to: "". If MR: this is the @-separated list of runs to use for this new MSMAll run of MR FIX; e.g., mrfixNamesToUse="Rest_01_AP@Rest_01_PA@Rest_02_AP@Rest_02_PA"
    mrfixNamesToUse=""
    
    # Same as MATLAB Mode as before; best options are 0 or 1 
    MatlabMode="0"
    
    # Settings that likely don't need to change: 
    MSMAllTemplates="${HCPPIPEDIR}/global/templates/MSMAll"
    RegName_MSMall="MSMAll_InitalReg"
    InRegName=${RegName}
    
    ${HCPPipe}/MSMAll/MSMAllPipeline.sh --path=${datadir} --subject=${subj} --fmri-names-list=${fMRINames} --output-fmri-name=${OutfMRIName} --high-pass=${bandpass} --fmri-proc-string=${fMRIProcSTRING} --msm-all-templates=${MSMAllTemplates} --output-registration-name=${RegName_MSMall} --high-res-mesh=${HighResMesh} --low-res-mesh=${LowResMeshes} --input-registration-name=${InRegName} --matlab-run-mode=${MatlabMode}
fi

#########################
# SEVENTH node of HCP Pipeline, part b: MSM-All, to perform multi-modal surface alignment.
# This version (msmAll_Task_SingleRun) is performed on each rest run separately and corresponds to taskFix_SingleRun above. 

if [ -z "$msmAll_Task_SingleRun" ]; then
    echo "Skipping HCP minimal preprocessing computational step 7, step b: MSM-All multi-modal surface alignment (single-run task-state)."
elif [ $msmAll_Task_SingleRun = true ]; then
    echo "Running HCP minimal preprocessing computational step 7, step b: MSM-All multi-modal surface alignment (single-run task-state)..."
    
    #Set up additional pipeline environment variables and software
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    source "$EnvironmentScript"

    # fMRINames is for single-run (SR) FIX data, set multi-run (MR) FIX settings to empty. If doing MR, set: fMRINames=""
    fMRINames="${fixMSM_Task_SingleRun_Str}"
    
    # If SR: OutfMRIName="All_Task". If MR: this is the FIX output concat name for this new MSMAll run of MR FIX; e.g., OutfMRIName="MultiRun_Rest"
    OutfMRIName="All_Task"
    
    # Name to reflect high pass setting; identification for FIX cleaned dtseries to use. The dense timeseries files used will be named <fmri_name>_<fmri_proc_string>.dtseries.nii where <fmri_name> is each of the fMRIs specified in the <fMRI Names> list and <fmri_proc_string> is this specified value
    fMRIProcSTRING="_Atlas_hp${bandpass}_clean"
    
    # If SR, set to: "". If MR: this is the original MR FIX parameter for what to concatenate. List all single runs from one concatenated group separated with @.
    mrfixNames=""
    
    # If SR, set to: "". If MR: this is the original MR FIX concatenated name (only one group); e.g., mrfixConcatName="fMRI_CONCAT"
    mrfixConcatName=""
    
    # If SR, set to: "". If MR: this is the @-separated list of runs to use for this new MSMAll run of MR FIX; e.g., mrfixNamesToUse="Rest_01_AP@Rest_01_PA@Rest_02_AP@Rest_02_PA"
    mrfixNamesToUse=""
    
    # Same as MATLAB Mode as before; best options are 0 or 1 
    MatlabMode="0"
    
    # Settings that likely don't need to change: 
    MSMAllTemplates="${HCPPIPEDIR}/global/templates/MSMAll"
    RegName_MSMall="MSMAll_InitalReg"
    InRegName=${RegName}
    
    ${HCPPipe}/MSMAll/MSMAllPipeline.sh --path=${datadir} --subject=${subj} --fmri-names-list=${fMRINames} --output-fmri-name=${OutfMRIName} --high-pass=${bandpass} --fmri-proc-string=${fMRIProcSTRING} --msm-all-templates=${MSMAllTemplates} --output-registration-name=${RegName_MSMall} --high-res-mesh=${HighResMesh} --low-res-mesh=${LowResMeshes} --input-registration-name=${InRegName} --matlab-run-mode=${MatlabMode}
fi

#########################

#########################
# SEVENTH node of HCP Pipeline, part c: MSM-All, to perform multi-modal surface alignment.
# This version (msmAll_Rest_MultiRun_All) is performed on each rest run separately and corresponds to restFix_MultiRun_All above. 

if [ -z "$msmAll_Rest_MultiRun_All" ]; then
    echo "Skipping HCP minimal preprocessing computational step 7, step c: MSM-All multi-modal surface alignment (multi-run resting-state, ALL concatenated)."
elif [ $msmAll_Rest_MultiRun_All = true ]; then
    echo "Running HCP minimal preprocessing computational step 7, step c: MSM-All multi-modal surface alignment (multi-run resting-state, ALL concatenated)..."
    
    #Set up additional pipeline environment variables and software
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    source "$EnvironmentScript"
    
    # Use HighPass = 2000 for single-run FIX data, HighPass = 0 for MR FIX data
    bandpass_MR="0"
    
    # fMRINames is for single-run (SR) FIX data, set multi-run (MR) FIX settings to empty. If doing MR, set: fMRINames=""
    fMRINames=""
    
    # If SR: OutfMRIName="All_Rest". If MR: this is the FIX output concat name for this new MSMAll run of MR FIX; e.g., OutfMRIName="MultiRun_Rest"
    OutfMRIName="MultiRun_Rest_AllConcat"
    
    # Name to reflect high pass setting; identification for FIX cleaned dtseries to use. The dense timeseries files used will be named <fmri_name>_<fmri_proc_string>.dtseries.nii where <fmri_name> is each of the fMRIs specified in the <fMRI Names> list and <fmri_proc_string> is this specified value
    fMRIProcSTRING="_Atlas_hp${bandpass_MR}_clean"
    
    # If SR, set to: "". If MR: this is the original MR FIX parameter for what to concatenate. List all single runs from one concatenated group separated with @.
    mrfixNames="${fixMSM_Rest_SingleRun_Str}"
    
    # If SR, set to: "". If MR: this is identical to the original MR FIX concatenated name (only one group); e.g., mrfixConcatName="fMRI_CONCAT"
    mrfixConcatName="Rest_01_02_AP_PA" 
    
    # If SR, set to: "". If MR: this is the @-separated list of runs to use (i.e., what to pull from mrfixNames) for this new MSMAll run of MR FIX; e.g., mrfixNamesToUse="Rest_01_AP@Rest_01_PA@Rest_02_AP@Rest_02_PA" (Note: this may match mrfixNames exactly, or just be a subset)
    mrfixNamesToUse="${fixMSM_Rest_SingleRun_Str}"
    
    # Same as MATLAB Mode as before; best options are 0 or 1 
    MatlabMode="0"
    
    # Settings that likely don't need to change: 
    MSMAllTemplates="${HCPPIPEDIR}/global/templates/MSMAll"
    RegName_MSMall="MSMAll_InitalReg"
    InRegName=${RegName}
    
    ${HCPPipe}/MSMAll/MSMAllPipeline.sh --path=${datadir} --subject=${subj} --fmri-names-list=${fMRINames} --multirun-fix-names="$mrfixNames" --multirun-fix-concat-name="$mrfixConcatName" --multirun-fix-names-to-use="$mrfixNamesToUse" --output-fmri-name=${OutfMRIName} --high-pass=${bandpass_MR} --fmri-proc-string=${fMRIProcSTRING} --msm-all-templates=${MSMAllTemplates} --output-registration-name=${RegName_MSMall} --high-res-mesh=${HighResMesh} --low-res-mesh=${LowResMeshes} --input-registration-name=${InRegName} --matlab-run-mode=${MatlabMode}

fi
#########################

#########################
# SEVENTH node of HCP Pipeline, part d: MSM-All, to perform multi-modal surface alignment.
# This version (msmAll_Task_MultiRun_All) is performed on each task run separately and corresponds to msmAll_Task_MultiRun_All above. 

if [ -z "$msmAll_Task_MultiRun_All" ]; then
    echo "Skipping HCP minimal preprocessing computational step 7, step d: MSM-All multi-modal surface alignment (multi-run task-state, ALL concatenated)."
elif [ $msmAll_Task_MultiRun_All = true ]; then
    echo "Running HCP minimal preprocessing computational step 7, step d: MSM-All multi-modal surface alignment (multi-run task-state, ALL concatenated)..."
    
    #Set up additional pipeline environment variables and software
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    source "$EnvironmentScript"
    
    # Use HighPass = 2000 for single-run FIX data, HighPass = 0 for MR FIX data
    bandpass_MR="0"
    
    # fMRINames is for single-run (SR) FIX data, set multi-run (MR) FIX settings to empty. If doing MR, set: fMRINames=""
    fMRINames=""
    
    # If SR: OutfMRIName="All_Rest". If MR: this is the FIX output concat name for this new MSMAll run of MR FIX; e.g., OutfMRIName="MultiRun_Rest"
    OutfMRIName="MultiRun_Task_AllConcat"
    
    # Name to reflect high pass setting; identification for FIX cleaned dtseries to use. The dense timeseries files used will be named <fmri_name>_<fmri_proc_string>.dtseries.nii where <fmri_name> is each of the fMRIs specified in the <fMRI Names> list and <fmri_proc_string> is this specified value
    fMRIProcSTRING="_Atlas_hp${bandpass_MR}_clean"
    
    # If SR, set to: "". If MR: this is the original MR FIX parameter for what to concatenate. List all single runs from one concatenated group separated with @.
    mrfixNames="${fixMSM_Task_SingleRun_Str}"
    
    # If SR, set to: "". If MR: this is identical to the original MR FIX concatenated name (only one group); e.g., mrfixConcatName="fMRI_CONCAT"
    mrfixConcatName="Task_Stroop_Hammer_AP_PA" 
    
    # If SR, set to: "". If MR: this is the @-separated list of runs to use (i.e., what to pull from mrfixNames) for this new MSMAll run of MR FIX; e.g., mrfixNamesToUse="Rest_01_AP@Rest_01_PA@Rest_02_AP@Rest_02_PA" (Note: this may match mrfixNames exactly, or just be a subset)
    mrfixNamesToUse="${fixMSM_Task_SingleRun_Str}"
    
    # Same as MATLAB Mode as before; best options are 0 or 1 
    MatlabMode="0"
    
    # Settings that likely don't need to change: 
    MSMAllTemplates="${HCPPIPEDIR}/global/templates/MSMAll"
    RegName_MSMall="MSMAll_InitalReg"
    InRegName=${RegName}
    
    ${HCPPipe}/MSMAll/MSMAllPipeline.sh --path=${datadir} --subject=${subj} --fmri-names-list=${fMRINames} --multirun-fix-names="$mrfixNames" --multirun-fix-concat-name="$mrfixConcatName" --multirun-fix-names-to-use="$mrfixNamesToUse" --output-fmri-name=${OutfMRIName} --high-pass=${bandpass_MR} --fmri-proc-string=${fMRIProcSTRING} --msm-all-templates=${MSMAllTemplates} --output-registration-name=${RegName_MSMall} --high-res-mesh=${HighResMesh} --low-res-mesh=${LowResMeshes} --input-registration-name=${InRegName} --matlab-run-mode=${MatlabMode}

fi
#########################
#########################
# EIGHTH node of HCP Pipeline, part a: De-drift and resample (rest-single-run).

# Dedrift and Resample: computes group 'drift' in MSM alignment and corrects for this. 
# NOTE: this correction is an optional step; NOT applying for now as prereq MSMRemoveGroupDrift code is hard to parse. 
# Then, this step actually applies the MSMall transform + resamples to specified /func files, and specifies whether FIX-ICA is applied to resulting surface files.

# NOTE: check that it is feasible to provide same filenames to rfmrinames and tfmrinames - enables comparison of FIX-ICA for rest and task - NOW not running ICA FIX on rest or task, so only fill out tfmrinames.

# NOTE: check that RegName_out is correct below (based on previous MSMall output)

# CHANGE ME notes for the elif>true section (i.e., may be project specific): 
# RegName_out: String corresponding to the MSMAll or other registration sphere name e.g. ${Subject}.${Hemisphere}.sphere.${RegName}.native.surf.gii
# DeDriftRegFiles: Path to the spheres output by the MSMRemoveGroupDrift pipeline or NONE; from example: "${HCPPIPEDIR}/global/templates/MSMAll/DeDriftingGroup.L.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii@${HCPPIPEDIR}/global/templates/MSMAll/DeDriftingGroup.R.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii"
# ConcatRegName: String corresponding to the output name of the concatenated registration i.e. the dedrifted registration; Given that we are not running the group dedrift (Glasser says this is optional and the code is not easy to parse), seems like this should equal RegName_out (based on looking at the DeDrift shell script).
# Maps: delimited map name strings corresponding to maps that are not myelin maps e.g. sulc curvature corrThickness thickness.
# MyelinMaps: delimited map name strings corresponding to myelin maps e.g. MyelinMap SmoothedMyelinMap) No _BC, this will be reapplied.

# NOTE: may need to generate run names per-subject if there were aborted scans. 

# NOTE: SmoothingFWHM should equal previous grayordinate smoothing in fMRISurface (because we are resampling from unsmoothed native mesh timeseries - already set. 

if [ -z "$dedriftResample_Rest_SingleRun" ]; then
    echo "Skipping HCP minimal preprocessing computational step 8, part a: De-drift and resample (apply MSM-All) (single-run rest-state)."
elif [ "$dedriftResample_Rest_SingleRun" == "true" ]; then
    echo "Running HCP minimal preprocessing computational step 8, part a: De-drift and resample (apply MSM-All) (single-run rest-state)..."
 
    #Set up additional pipeline environment variables and software
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    source "$EnvironmentScript"
    
    #Do not use RegName from MSMAllPipelineBatch.sh
    RegName_out="MSMAll_InitalReg_2_d40_WRN"
    
    #DeDriftRegFiles="NONE"
    DeDriftRegFiles="${HCPPIPEDIR}/global/templates/MSMAll/DeDriftingGroup.L.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii@${HCPPIPEDIR}/global/templates/MSMAll/DeDriftingGroup.R.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii"
    
    #ConcatRegName=${RegName_out}
    ConcatRegName="MSMAll"
    
    Maps="sulc@curvature@corrThickness@thickness"
    MyelinMaps="MyelinMap@SmoothedMyelinMap"
    
    # EDIT: 
    # $fixNames was previously --rfmri-names and should contain an @ delimited fMRIName strings corresponding to maps that will have ICA+FIX reapplied to them (could be either rfMRI or tfMRI). If none are to be used, specify "NONE".
    fixNames="${fixMSM_Rest_SingleRun_Str}"
    
    # $dontFixNames was previously --tfmri-names and should contain an @ delimited fMRIName strings corresponding to maps that will NOT have ICA+FIX reapplied to them. If none are to be used, specify "NONE". It is not recommended to use this. 
    dontFixNames="NONE"
    
    MatlabMode="0"
    MotionRegression=FALSE

    ${HCPPipe}/DeDriftAndResample/DeDriftAndResamplePipeline.sh --path=${datadir} --subject=${subj} --high-res-mesh=${HighResMesh} --low-res-meshes=${LowResMeshes} --registration-name=${RegName_out} --dedrift-reg-files=${DeDriftRegFiles} --concat-reg-name=${ConcatRegName} --maps=${Maps} --myelin-maps=${MyelinMaps} --fix-names=${fixNames} --dont-fix-names=${dontFixNames} --smoothing-fwhm=${SmoothingFWHM} --highpass=${bandpass} --matlab-run-mode=${MatlabMode} --motion-regression=$MotionRegression
fi

#########################

#########################
# EIGHTH node of HCP Pipeline, part b: De-drift and resample (task-single-run).
# Same as above, but for single-run task-state data. 

if [ -z "$dedriftResample_Task_SingleRun" ]; then
    echo "Skipping HCP minimal preprocessing computational step 8, part b: De-drift and resample (apply MSM-All) (single-run task-state)."
elif [ "$dedriftResample_Task_SingleRun" == "true" ]; then
    echo "Running HCP minimal preprocessing computational step 8, part b: De-drift and resample (apply MSM-All)(single-run task-state)..."
 
    #Set up additional pipeline environment variables and software
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    source "$EnvironmentScript"
    
    #Do not use RegName from MSMAllPipelineBatch.sh
    RegName_out="MSMAll_InitalReg_2_d40_WRN"
    
    #DeDriftRegFiles="NONE"
    DeDriftRegFiles="${HCPPIPEDIR}/global/templates/MSMAll/DeDriftingGroup.L.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii@${HCPPIPEDIR}/global/templates/MSMAll/DeDriftingGroup.R.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii"
    
    #ConcatRegName=${RegName_out}
    ConcatRegName="MSMAll"
    
    Maps="sulc@curvature@corrThickness@thickness"
    MyelinMaps="MyelinMap@SmoothedMyelinMap"
    
    # EDIT: 
    # $fixNames was previously --rfmri-names and should contain an @ delimited fMRIName strings corresponding to maps that will have ICA+FIX reapplied to them (could be either rfMRI or tfMRI). If none are to be used, specify "NONE".
    fixNames="${fixMSM_Task_SingleRun_Str}"
    
    # $dontFixNames was previously --tfmri-names and should contain an @ delimited fMRIName strings corresponding to maps that will NOT have ICA+FIX reapplied to them. If none are to be used, specify "NONE". It is not recommended to use this. 
    dontFixNames="NONE"
    
    MatlabMode="0"
    MotionRegression=FALSE

    ${HCPPipe}/DeDriftAndResample/DeDriftAndResamplePipeline.sh --path=${datadir} --subject=${subj} --high-res-mesh=${HighResMesh} --low-res-meshes=${LowResMeshes} --registration-name=${RegName_out} --dedrift-reg-files=${DeDriftRegFiles} --concat-reg-name=${ConcatRegName} --maps=${Maps} --myelin-maps=${MyelinMaps} --fix-names=${fixNames} --dont-fix-names=${dontFixNames} --smoothing-fwhm=${SmoothingFWHM} --highpass=${bandpass} --matlab-run-mode=${MatlabMode} --motion-regression=$MotionRegression
fi

#########################

#########################
# EIGHTH node of HCP Pipeline, part c: De-drift and resample (rest-multi-run ALL).
# Same as above, but for multi-run resting-state data; all rest runs concatenated together. 

if [ -z "$dedriftResample_Rest_MultiRun_All" ]; then
    echo "Skipping HCP minimal preprocessing computational step 8, part c: De-drift and resample (apply MSM-All) (multi-run rest-state, all concatenated)."
elif [ "$dedriftResample_Rest_MultiRun_All" == "true" ]; then
    echo "Running HCP minimal preprocessing computational step 8, part c: De-drift and resample (apply MSM-All)(multi-run rest-state, all concatenated)..."
 
    #Set up additional pipeline environment variables and software
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    source "$EnvironmentScript"
    
    # Use HighPass = 2000 for single-run FIX data, HighPass = 0 for MR FIX data
    bandpass_MR="0"
    
    #Do not use RegName from MSMAllPipelineBatch.sh
    RegName_out="MSMAll_InitalReg_2_d40_WRN"
    
    #DeDriftRegFiles="NONE"
    DeDriftRegFiles="${HCPPIPEDIR}/global/templates/MSMAll/DeDriftingGroup.L.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii@${HCPPIPEDIR}/global/templates/MSMAll/DeDriftingGroup.R.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii"
    
    #ConcatRegName=${RegName_out}
    ConcatRegName="MSMAll"
    
    Maps="sulc@curvature@corrThickness@thickness"
    MyelinMaps="MyelinMap@SmoothedMyelinMap"
    
    # EDIT: 
    # $fixNames was previously --rfmri-names and should contain an @ delimited fMRIName strings corresponding to maps that will have ICA+FIX reapplied to them (could be either rfMRI or tfMRI). If none are to be used, specify "NONE". For SR: this should match the SR used in ICA-FIX and MSMAll steps. For MR: set to empty (either use "NONE" or () ).
    fixNames="NONE"
    
    # $dontFixNames was previously --tfmri-names and should contain an @ delimited fMRIName strings corresponding to maps that will NOT have ICA+FIX reapplied to them. If none are to be used, specify "NONE". It is not recommended to use this. 
    dontFixNames="NONE"
    
    MatlabMode="0"
    MotionRegression=FALSE
    
    # Whether to also extract the specified MR FIX runs from the volume data, requires --multirun-fix-extract-concat-names to work, default FALSE
    extractMRFromVol=FALSE
    
    # MRFixConcatNames and MRFixNames must exactly match the way MR FIX was run on the subjects. IF SR: these are left empty (default). If MR: in $MRFixNames use an @ separated list of runs to be used; in $MRFixConcatNames use the same string as in $OutfMRIName
    #MRFixConcatNames="MultiRun_Rest_AllConcat"
    MRFixConcatNames="Rest_01_02_AP_PA"
    MRFixNames="${fixMSM_Rest_SingleRun_Str}"
    

    ${HCPPipe}/DeDriftAndResample/DeDriftAndResamplePipeline.sh --path=${datadir} --subject=${subj} --high-res-mesh=${HighResMesh} --low-res-meshes=${LowResMeshes} --registration-name=${RegName_out} --dedrift-reg-files=${DeDriftRegFiles} --concat-reg-name=${ConcatRegName} --maps=${Maps} --myelin-maps=${MyelinMaps} --multirun-fix-concat-names="$MRFixConcatNames" --multirun-fix-names="$MRFixNames" --multirun-fix-extract-volume=$extractMRFromVol --fix-names=${fixNames} --dont-fix-names=${dontFixNames} --smoothing-fwhm=${SmoothingFWHM} --highpass=${bandpass_MR} --matlab-run-mode=${MatlabMode} --motion-regression=$MotionRegression
fi

#########################

#########################
# EIGHTH node of HCP Pipeline, part d: De-drift and resample (task-multi-run ALL).
# Same as above, but for multi-run task-state data; all task runs concatenated together. 

if [ -z "$dedriftResample_Task_MultiRun_All" ]; then
    echo "Skipping HCP minimal preprocessing computational step 8, part d: De-drift and resample (apply MSM-All) (multi-run task-state, all concatenated)."
elif [ "$dedriftResample_Task_MultiRun_All" == "true" ]; then
    echo "Running HCP minimal preprocessing computational step 8, part d: De-drift and resample (apply MSM-All) (multi-run task-state, all concatenated)..."
 
    #Set up additional pipeline environment variables and software
    EnvironmentScript="${HCPPipe}/Examples/Scripts/SetUpHCPPipeline_TestSubj.sh"
    source "$EnvironmentScript"
    
    # Use HighPass = 2000 for single-run FIX data, HighPass = 0 for MR FIX data
    bandpass_MR="0"
    
    #Do not use RegName from MSMAllPipelineBatch.sh
    RegName_out="MSMAll_InitalReg_2_d40_WRN"
    
    #DeDriftRegFiles="NONE"
    DeDriftRegFiles="${HCPPIPEDIR}/global/templates/MSMAll/DeDriftingGroup.L.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii@${HCPPIPEDIR}/global/templates/MSMAll/DeDriftingGroup.R.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii"
    
    #ConcatRegName=${RegName_out}
    ConcatRegName="MSMAll"
    
    Maps="sulc@curvature@corrThickness@thickness"
    MyelinMaps="MyelinMap@SmoothedMyelinMap"
    
    # EDIT: 
    # $fixNames was previously --rfmri-names and should contain an @ delimited fMRIName strings corresponding to maps that will have ICA+FIX reapplied to them (could be either rfMRI or tfMRI). If none are to be used, specify "NONE". For SR: this should match the SR used in ICA-FIX and MSMAll steps. For MR: set to empty (either use "NONE" or () ).
    fixNames="NONE"
    
    # $dontFixNames was previously --tfmri-names and should contain an @ delimited fMRIName strings corresponding to maps that will NOT have ICA+FIX reapplied to them. If none are to be used, specify "NONE". It is not recommended to use this. 
    dontFixNames="NONE"
    
    MatlabMode="0"
    MotionRegression=FALSE
    
    # Whether to also extract the specified MR FIX runs from the volume data, requires --multirun-fix-extract-concat-names to work, default FALSE
    extractMRFromVol=FALSE
    
    # MRFixConcatNames and MRFixNames must exactly match the way MR FIX was run on the subjects. IF SR: these are left empty (default). If MR: in $MRFixNames use an @ separated list of runs to be used; in $MRFixConcatNames use the same string as in $OutfMRIName
    #MRFixConcatNames="MultiRun_Rest_AllConcat"
    MRFixConcatNames="Task_Stroop_Hammer_AP_PA"
    MRFixNames="${fixMSM_Task_SingleRun_Str}"
    

    ${HCPPipe}/DeDriftAndResample/DeDriftAndResamplePipeline.sh --path=${datadir} --subject=${subj} --high-res-mesh=${HighResMesh} --low-res-meshes=${LowResMeshes} --registration-name=${RegName_out} --dedrift-reg-files=${DeDriftRegFiles} --concat-reg-name=${ConcatRegName} --maps=${Maps} --myelin-maps=${MyelinMaps} --multirun-fix-concat-names="$MRFixConcatNames" --multirun-fix-names="$MRFixNames" --multirun-fix-extract-volume=$extractMRFromVol --fix-names=${fixNames} --dont-fix-names=${dontFixNames} --smoothing-fwhm=${SmoothingFWHM} --highpass=${bandpass_MR} --matlab-run-mode=${MatlabMode} --motion-regression=$MotionRegression
fi

#########################

# NOTE: after HCP minimal preprocessing steps above are complete, consider running various steps in: post_hcp_main.sh 