#!/bin/bash

########################################################
# Author: Carrisa V. Cocuzza. 2023. Yale University. Holmes Lab. 

# Description: Per participant, this script performs the main steps in fMRI data processing after HCP minimal preprocessing. 

# NOTES: 
# (1) This is set up for the TCP dataset and the Milgram HPC cluster at Yale. It likely can be adapted for other projects by changing sections that are tagged with "EDIT" (e.g., use a find/search/etc. tool in this script to see areas that are project-specific and should be changed). 
# (2) If you wish to run this for your project, it is likely best to copy the directory here (/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/post_hcp_processing) and edit the portions of this script that say "EDIT". In addition, edit post_hcp_processing_setup.sh. 
# (3) These steps are not necessarily universal, hence the modular format of this script: where certain steps can be set to true/false as needed (see usage below).
# (4) HCP minimal preprocessing performed before this: /gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/HCP_Scripts_StepWise/hcp_main_milgram_tcp_2023.sh
# (5) Some of the steps below are written/performed within this script, and some steps call other scripts/functions/tools (all stored in the same parent directory). This could likely be edited/optimized in the future if need be, but generally, lightweight code was written here, and heavier-weight and/or more more complex code was outsourced. 
# (6) Programming/scripting languages here: bash (shell), python

########################################################
# EDIT: Modules/tools that are already configured on Yale's HPC 
module load FSL 

export FSLDIR=/gpfs/milgram/apps/hpc.rhel7/software/FSL/6.0.5-centos7_64/
. ${FSLDIR}/etc/fslconf/fsl.sh

########################################################
# Set up command line option functions:

# EDIT to your path: ${path_to_opts_script} 
# NOTE: script itself should not need to change. 

echo -e "\nSourcing command line option functions...\n"

path_to_opts_script=/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/post_hcp_processing/
source ${path_to_opts_script}opts_newPipe.shlib
########################################################

########################################################
# Set up variables for your dataset, environment:

# EDIT: Go to the script sourced here and edit it for your project's specs. Also edit the path listed below in ${envScript}.

echo -e "Setting project-specific environment and variables...\n"

subj=`opts_GetOpt1 "--subj" $@`

envScript=/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/post_hcp_processing/post_hcp_processing_setup.sh
. ${envScript} --subj="$subj"

########################################################

########################################################
# Main script usage:

show_usage() {
    cat <<EOF
    
This script runs an individual participant's fMRI data through various post-minimal-preprocessing steps.

post_hcp_main.sh

Usage: post_hcp_main.sh [options]

    --subj=<subjectID>                         (required) Subject ID, exactly as used throughout your project directories.
    --dirSetUp=<"true">                        (optional) Input "true" to set up directory structure for this participant.
    --runCreateMasks_NotDenoised=<"true">      (optional) Input "true" to create physiological masks; non-denoised data. 
                                                          Required before runTaskDenoising.
    --runCreateMasks_ICAFIX_SingleRun=<"true"> (optional) "true" to create physiological masks; single-run ICA-FIX'd data. 
                                                          Required before surface based GSR and maybe runTaskDenoising. 
    --runCreateMasks_ICAFIX_MultiRun=<"true">  (optional) "true" to create physiological masks; multi-run ICA-FIX'd data. 
                                                          Required before surface based GSR and maybe runTaskDenoising. 
    --runGSR_Vol_NonVN=<"true">                (optional) "true" to run GSR. Performed per functional run. 
                                                          This variant: GSR on ICA-FIX'd, non-variance-normalized 
                                                          volumetric timeseries.
    --runGSR_Vol_NonVN_NonDenoised=<"true">    (optional) "true" to run GSR. Performed per functional run. 
                                                          This variant: GSR on non-denoised, non-variance-normalized 
                                                          volumetric timeseries. Useful for QC.                                                     
    --runGSR_Vol_VN=<"true">                   (optional) "true" to run GSR. Performed per functional run. This variant: 
                                                          GSR on ICA-FIX'd, variance-normalized volumetric timeseries.
                                                          Saved with "_vn" tag to avoid overwriting above.
    --runGSR_Surf_NonVN=<"true">               (optional) "true" to run GSR. Performed per functional run. This variant: 
                                                          GSR on ICA-FIX'd, non-variance-normalized surface (dense) 
                                                          timeseries. Saved as dtseries, but same prefix strings as 
                                                          runGSR_Vol_VN.
    --runGSR_Surf_VN=<"true">                  (optional) "true" to run GSR. Performed per functional run. This variant: 
                                                          GSR on cleaned (ICA-FIX'd), variance-normalized surface (dense) 
                                                          timeseries. Saved with "_vn" tag to avoid overwriting above.
    --runGSR_Surf_NonVN_MSMAll=<"true">        (optional) "true" to run GSR. Performed per functional run. This variant: 
                                                          GSR on ICA-FIX'd, MSMAll aligned, non-variance-normalized surface 
                                                          (dense) timeseries. Saved with "MSMAll" to avoid overwriting above.
    --runGSR_Surf_VN_MSMAll=<"true">           (optional) "true" to run GSR. Performed per functional run. This variant: 
                                                          GSR on ICA-FIX'd, MSMAll aligned, variance-normalized surface 
                                                          (dense) timeseries. Saved with "MSMAll_vn" to avoid overwriting 
                                                          above. NOTE: this variant requires variance normalizing in-script
                                                          (HCP does not perform this for some reason).
    --runTaskDenoising=<"true">                (optional) "true" to run non-ICA-FIX rest denoising 
                                                          (motion regression + aCompCor).
    --runRestDenoising=<"true">                (optional) Input "true" to run non-ICA-FIX task denoising 
                                                          (motion regression + aCompCor).
    --runParcellateData=<"true">               (optional) Input "true" to parcellate (vertices >> regions) using various 
                                                          popular atlases.
    --runTaskGLM=<"true">                      (optional) Input "true" to run a task GLM based on task timings, trials, 
                                                          conditions, etc. Required before runTaskContrasts and 
                                                          runTaskFCByCondition.
    --runTaskContrasts=<"true">                (optional) Input "true" to run sensible task contrasts (for QC, etc.).
    --fcMethod="pearson"                       (optional) Input a string from the following options: "pearson", 
                                                          "multiple_regression".
                                                          NOTE: uses pearson's correlation for FC estimation is the default.
                                                          NOTE: this will apply to the remaining options below.
                                                          NOTE: I'd like to also add these options in the future: 
                                                                "combined_FC" (Sanchez-Romero, 2019),and the following 
                                                                regularized methods (e.g., for vertex-level, short 
                                                                timeseries data, etc.): 
                                                                "lasso", "elastic_net", "glasso", "ridge", 
                                                                "multiple_regression_pca".
                                                          NOTE: case and spelling sensitive (could be improved).
    --fcDataType="surface"                     (optional) Input a string from the following: "surface" or "volume". 
                                                          Default is surface.
                                                          NOTE: case and spelling sensitive (could be improved).
    --fcDataLevel="regions_schaefer_400"       (optional) Input a string from the following: 
                                                          "regions_schaefer_400" (default), "regions_glasser_360", OR
                                                          "regions_yeo_homeotopic". 
                                                          NOTE: Other options TBA: various vertex-level options, 
                                                                other schaefer/yeo variants.
                                                          NOTE: case and spelling sensitive (could be improved). 
    --fcDenoisingType="ica_fix_single_run"     (optional) Input a string from the following: 
                                                          "ica_fix_single_run" (default), "ica_fix_multi_run_all",
                                                          "ica_fix_multi_run_select", "ciric_style" (aCompCor + motion). 
                                                          NOTE: More variants TBA.
                                                          NOTE: case and spelling sensitive (could be improved).
    --fcUseGSR=<"false">                       (optional) "true" to use GSR'd version of above options during FC estimation. 
                                                          Default is "false".
    --fcUseVN=<"false">                        (optional) "true" to use variance normalized data in FC estimation.
                                                          Default is "false".
    --fcExtraSaveStr=<"">                      (optional) Input string of your choosing to tag onto saved FC estimates 
                                                          file names. Default is an empty string.
    --runRestFC=<"true">                       (optional) "true" to estimate resting-state functional connectivity (rest-FC) 
                                                          using FC estimation method specified by fcMethod. 
                                                          Required before runRestNetMetrics.
    --runTaskFCGeneral=<"true">                (optional) "true" to estimate task-general FC (i.e., 1 network per task run). 
                                                          Required before runTaskNetMetricsGeneral.
    --runTaskFCByCond=<"true">                 (optional) "true" to estimate condition-specific task-FC (i.e., 1 network
                                                          per task condition) (r, mult-reg). Required before 
                                                          runTaskNetMetricsByCondition.
    --runRestNetMetrics=<"true">               (optional) "true" to perform common network diagnostics on rest-FC data. 
    --runTaskNetMetricsGeneral=<"true">        (optional) "true" to perform common net diagnostics on task-FC-general data.
    --runTaskNetMetricsByCond=<"true">         (optional) "true" to perform common net diagnostics on task-FC-by-condition data. 
EOF
    exit 1
}

opts_ShowVersionIfRequested $@

if opts_CheckForHelpRequest $@; then
    show_usage
fi

########################################################

########################################################
# Set input variables from above:

echo -e "\nSetting input variables...\n"

#subj=`opts_GetOpt1 "--subj" $@`
dirSetUp=`opts_GetOpt1 "--dirSetUp" $@`

runCreateMasks_NotDenoised=`opts_GetOpt1 "--runCreateMasks_NotDenoised" $@`
runCreateMasks_ICAFIX_SingleRun=`opts_GetOpt1 "--runCreateMasks_ICAFIX_SingleRun" $@`
runCreateMasks_ICAFIX_MultiRun=`opts_GetOpt1 "--runCreateMasks_ICAFIX_MultiRun" $@`

runGSR_Vol_NonVN=`opts_GetOpt1 "--runGSR_Vol_NonVN" $@`
runGSR_Vol_NonVN_NonDenoised=`opts_GetOpt1 "--runGSR_Vol_NonVN_NonDenoised" $@`
runGSR_Vol_VN=`opts_GetOpt1 "--runGSR_Vol_VN" $@`
runGSR_Surf_NonVN=`opts_GetOpt1 "--runGSR_Surf_NonVN" $@`
runGSR_Surf_VN=`opts_GetOpt1 "--runGSR_Surf_VN" $@`
runGSR_Surf_NonVN_MSMAll=`opts_GetOpt1 "--runGSR_Surf_NonVN_MSMAll" $@`
runGSR_Surf_VN_MSMAll=`opts_GetOpt1 "--runGSR_Surf_VN_MSMAll" $@`

runTaskDenoising=`opts_GetOpt1 "--runTaskDenoising" $@`
runRestDenoising=`opts_GetOpt1 "--runRestDenoising" $@`

runParcellateData=`opts_GetOpt1 "--runParcellateData" $@`

runTaskGLM=`opts_GetOpt1 "--runTaskGLM" $@`
runTaskContrasts=`opts_GetOpt1 "--runTaskContrasts" $@`

runRestFC=`opts_GetOpt1 "--runRestFC" $@`
runTaskFCGeneral=`opts_GetOpt1 "--runTaskFCGeneral" $@`
runTaskFCByCond=`opts_GetOpt1 "--runTaskFCByCond" $@`
runRestNetMetrics=`opts_GetOpt1 "--runRestNetMetrics" $@`
runTaskNetMetricsGeneral=`opts_GetOpt1 "--runTaskNetMetricsGeneral" $@`
runTaskNetMetricsByCond=`opts_GetOpt1 "--runTaskNetMetricsByCond" $@`

runGSR_Vol_VN_TEST=`opts_GetOpt1 "--runGSR_Vol_VN_TEST" $@`

fcMethod=`opts_GetOpt1 "--fcMethod" $@`
fcDataType=`opts_GetOpt1 "--fcDataType" $@`
fcDataLevel=`opts_GetOpt1 "--fcDataLevel" $@`
fcDenoisingType=`opts_GetOpt1 "--fcDenoisingType" $@`
fcUseGSR=`opts_GetOpt1 "--fcUseGSR" $@`
fcUseVN=`opts_GetOpt1 "--fcUseVN" $@`
fcExtraSaveStr=`opts_GetOpt1 "--fcExtraSaveStr" $@`

# Check for required input argument: --subj=participant_ID. participant_ID should match the string used throughout your project's directories. 
if [ -z "$subj" ]; then 
    echo -e "ERROR: Missing required input argument --subj. Terminating script now. Please rerun with --subj=participant_ID\n"
    exit
else
    echo -e "Running post-HCP processing for participant ${subj}...\n"
fi 

########################################################

########################################################
# Directory set up: 

if [ -z "$dirSetUp" ]; then
    echo -e "Skipping directory set up.\n"
    subjDir_Output_Data="${baseDir_Output_Data}/${subj}/"
    if [ ! -d "$subjDir_Output_Data" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_Masks="${subjDir_Output_Data}/masks/"
    if [ ! -d "$subjDir_Masks" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_VN="${subjDir_Output_Data}/variance_normalized_timeseries/"
    if [ ! -d "$subjDir_VN" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_GSR="${subjDir_Output_Data}/GSR/"
    if [ ! -d "$subjDir_GSR" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_Denoising="${subjDir_Output_Data}/denoising_alt/"
    if [ ! -d "$subjDir_Denoising" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_Parcellation="${subjDir_Output_Data}/parcellated_data/"
    if [ ! -d "$subjDir_Parcellation" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_Task_GLM="${subjDir_Output_Data}/task_GLM/"
    if [ ! -d "$subjDir_Task_GLM" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_Task_Contrasts="${subjDir_Output_Data}/task_contrasts/"
    if [ ! -d "$subjDir_Task_Contrasts" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_Network="${subjDir_Output_Data}/network_analyses/"
    if [ ! -d "$subjDir_Network" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_FC="${subjDir_Network}/functional_connectivity_estimates/"
    if [ ! -d "$subjDir_FC" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_FC_Rest="${subjDir_FC}/rest_FC/"
    if [ ! -d "$subjDir_FC_Rest" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_FC_Task="${subjDir_FC}/task_FC/"
    if [ ! -d "$subjDir_FC_Task" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_NetMetrics="${subjDir_Network}/network_diagnostic_metrics/"
    if [ ! -d "$subjDir_NetMetrics" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_NetMetrics_Rest="${subjDir_NetMetrics}/rest_network_metrics/"
    if [ ! -d "$subjDir_NetMetrics_Rest" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
    subjDir_NetMetrics_Task="${subjDir_NetMetrics}/task_network_metrics/"
    if [ ! -d "$subjDir_NetMetrics_Task" ]; then
      echo -e "ERROR: Directory structure to store postprocessing output for this participant does not exist. Terminating script. Please re-run with --dirSetUp=true\n"
      exit
    fi
    
elif [ $dirSetUp = true ]; then
    echo -e "Running directory set up...\n"
    
    subjDir_Output_Data="${baseDir_Output_Data}/${subj}/"
    if [ ! -e $subjDir_Output_Data ]; then mkdir -p $subjDir_Output_Data; fi

    subjDir_VN="${subjDir_Output_Data}/variance_normalized_timeseries/"
    if [ ! -e $subjDir_VN ]; then mkdir $subjDir_VN; fi
    
    subjDir_Masks="${subjDir_Output_Data}/masks/"
    if [ ! -e $subjDir_Masks ]; then mkdir $subjDir_Masks; fi

    subjDir_GSR="${subjDir_Output_Data}/GSR/"
    if [ ! -e $subjDir_GSR ]; then mkdir $subjDir_GSR; fi
    
    subjDir_Denoising="${subjDir_Output_Data}/denoising_alt/"
    if [ ! -e $subjDir_Denoising ]; then mkdir $subjDir_Denoising; fi

    subjDir_Parcellation="${subjDir_Output_Data}/parcellated_data/"
    if [ ! -e $subjDir_Parcellation ]; then mkdir $subjDir_Parcellation; fi
    
    subjDir_Task_GLM="${subjDir_Output_Data}/task_GLM/"
    if [ ! -e $subjDir_Task_GLM ]; then mkdir $subjDir_Task_GLM; fi
    
    subjDir_Task_Contrasts="${subjDir_Output_Data}/task_contrasts/"
    if [ ! -e $subjDir_Task_Contrasts ]; then mkdir $subjDir_Task_Contrasts; fi
    
    subjDir_Network="${subjDir_Output_Data}/network_analyses/"
    if [ ! -e $subjDir_Network ]; then mkdir $subjDir_Network; fi
    
    subjDir_FC="${subjDir_Network}/functional_connectivity_estimates/"
    if [ ! -e $subjDir_FC ]; then mkdir $subjDir_FC; fi
    
    subjDir_FC_Rest="${subjDir_FC}/rest_FC/"
    if [ ! -e $subjDir_FC_Rest ]; then mkdir $subjDir_FC_Rest; fi
    
    subjDir_FC_Task="${subjDir_FC}/task_FC/"
    if [ ! -e $subjDir_FC_Task ]; then mkdir $subjDir_FC_Task; fi
    
    subjDir_NetMetrics="${subjDir_Network}/network_diagnostic_metrics/"
    if [ ! -e $subjDir_NetMetrics ]; then mkdir $subjDir_NetMetrics; fi
    
    subjDir_NetMetrics_Rest="${subjDir_NetMetrics}/rest_network_metrics/"
    if [ ! -e $subjDir_NetMetrics_Rest ]; then mkdir $subjDir_NetMetrics_Rest; fi
    
    subjDir_NetMetrics_Task="${subjDir_NetMetrics}/task_network_metrics/"
    if [ ! -e $subjDir_NetMetrics_Task ]; then mkdir $subjDir_NetMetrics_Task; fi
    
fi
########################################################

########################################################
# Create physiological masks: use non-denoised data here.
# NOTE: This is required before running alternative denoising (next sections). 
# This section calls: create_masks_HCP.sh 

if [ -z "$runCreateMasks_NotDenoised" ]; then
    echo -e "Skipping physiological mask creation (non-denoised data).\n"
elif [ $runCreateMasks_NotDenoised = true ]; then
    echo -e "Running physiological mask creation (non-denoised data)...\n"
    
    # Create masks:
    for runName in "${funcRunNames_Present[@]}" ; do
        echo "....on ${runName}..."
        sh ${baseDir_Scripts}create_masks_HCP.sh ${subj} ${runName} ${runName} ${baseDir_Input_Data} ${baseDir_Output_Data}
    done
    
fi
########################################################

########################################################
# Create physiological masks: use ICA-FIX'd (single run; i.e., each run denoised by itself) data here.
# NOTE: This is required before running surface-based GSR and potentially some alternative denoising steps.
# This section calls: create_masks_HCP.sh 

if [ -z "$runCreateMasks_ICAFIX_SingleRun" ]; then
    echo -e "Skipping physiological mask creation (single run ICA-FIX'd data).\n"
elif [ $runCreateMasks_ICAFIX_SingleRun = true ]; then
    echo -e "Running physiological mask creation (single run ICA-FIX'd data)...\n"
    
    # Create masks:
    for runName in "${funcRunNames_Present[@]}" ; do
        runNameHere="${runName}_hp2000_clean"
        echo "....on ${runNameHere}..."
        sh ${baseDir_Scripts}create_masks_HCP.sh ${subj} ${runName} ${runNameHere} ${baseDir_Input_Data} ${baseDir_Output_Data}
    done
    
fi

########################################################

########################################################
# Create physiological masks: use ICA-FIX'd (single run; i.e., each run denoised by itself) data here.
# NOTE: This is required before running surface-based GSR and potentially some alternative denoising steps.
# This section calls: create_masks_HCP.sh 

if [ -z "$runCreateMasks_ICAFIX_MultiRun" ]; then
    echo -e "Skipping physiological mask creation (multi-run ICA-FIX'd data).\n"
elif [ $runCreateMasks_ICAFIX_MultiRun = true ]; then
    echo -e "Running physiological mask creation (multi-run ICA-FIX'd data)...\n"
    
    # Create masks:
    for runName in "${funcRunNames_Present[@]}" ; do
        runNameHere="${runName}_hp0_clean"
        echo "....on ${runNameHere}..."
        sh ${baseDir_Scripts}create_masks_HCP.sh ${subj} ${runName} ${runNameHere} ${baseDir_Input_Data} ${baseDir_Output_Data}
    done
    
fi

########################################################

########################################################
# Global signal regression: regress out whole-brain fMRI signal from every voxel/vertex to account for head motion, respiration/cardiac rhythms, etc. (i.e., global artifacts).
# This variant includes: GSR on cleaned (ICA-FIX'd) non-variance-normalized volumetric timeseries.
# Generates ~3GB of data; takes ~5-10 minutes to run. 

# NOTES: 
# (1) This section uses FSL; this module is loaded at the top of this script, but alternative methods are available if need be (e.g., installing FSL via HCP, configuring it, and exporting those variables). One example would be if you need a specific version of FSL tools. 
# (2) This section's results are saved to: ${baseDir_Output_Data}/${subj}/GSR/
# (3) In HCP 4.7.0, hcp_fix (see HCP pipeline directories), <run>_filtered_func_data_clean.nii.gz is renamed and moved; the proper image files are referenced below. 
# (4) Related to the above, you can use variance normalized HCP results by adding _vn before .nii.gz
# (5) Note that, while this section does not take a long time to run, it does require a good amount of memory/RAM (because it's performing computations on 4D volumetric timeseries and/or dense vertex-wise timeseries), so using the SLURM scheduler (where you can request more computational resources) or otherise calling up a compute node, etc., is advised. 

if [ -z "$runGSR_Vol_NonVN" ]; then
    echo -e "Skipping global signal regression (GSR) on clean (ICA-FIX'd), non-variance-normalized volumetric timeseries.\n"
elif [ $runGSR_Vol_NonVN = true ]; then
    echo -e "Running global signal regression (GSR) on clean (ICA-FIX'd), non-variance-normalized volumetric timeseries...\n"
    
    # EDIT: these variables could be edited:
    export FSLOUTPUTTYPE='NIFTI_GZ'
    #atlasFileHere="${baseDir_Scripts}/atlas_files/FC419_MNI2mm.nii.gz"
    filterHere=1
    
    extraSaveStr="_From_Vol_NonVN"
    
    # Run GSR on ICA-FIX'd (clean), non-variance-normalized, volumetric timeseries (takes 5-10 minutes):
    for runName in "${funcRunNames_Present[@]}" ; do
        echo "....on ${runName}..."
        
        # EXTRACT GLOBAL SIGNAL:
        inputFileHere_Extract="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean.nii.gz"
        outputFileHere_Extract="${subjDir_GSR}/${runName}_hp${bandpass}_clean_GSR${extraSaveStr}.txt"
        labelFileHere="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}.ica/mask.nii.gz"
        fslmeants -i ${inputFileHere_Extract} -o ${outputFileHere_Extract} --label=${labelFileHere}
        
        # APPLY GSR: 
        inputFileHere_GSR="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean.nii.gz"
        outputFileHere_GSR="${subjDir_GSR}/${runName}_hp${bandpass}_clean_GSR${extraSaveStr}.nii.gz"
        designFileHere_GSR=${outputFileHere_Extract}
        fsl_regfilt -i ${inputFileHere_GSR} -d ${designFileHere_GSR} -o ${outputFileHere_GSR} -f ${filterHere}

        #fslmeants -i ${inputFileHere_Extract_GSR_TS} -o ${outputFileHere_Extract_GSR_TS} --label=${atlasFileHere} --transpose --verbose
    done
fi

########################################################

########################################################
# Global signal regression: regress out whole-brain fMRI signal from every voxel/vertex to account for head motion, respiration/cardiac rhythms, etc. (i.e., global artifacts).
# This variant includes: GSR on non-denoised, non-variance-normalized volumetric timeseries (used for QC).
# Generates ~3GB of data; takes ~5-10 minutes to run. 

if [ -z "$runGSR_Vol_NonVN_NonDenoised" ]; then
    echo -e "Skipping global signal regression (GSR) on non-denoised, non-variance-normalized volumetric timeseries.\n"
elif [ $runGSR_Vol_NonVN_NonDenoised = true ]; then
    echo -e "Running global signal regression (GSR) on non-denoised, non-variance-normalized volumetric timeseries...\n"
    
    # EDIT: these variables could be edited:
    export FSLOUTPUTTYPE='NIFTI_GZ'
    #atlasFileHere="${baseDir_Scripts}/atlas_files/FC419_MNI2mm.nii.gz"
    filterHere=1
    
    extraSaveStr="_From_Vol_NonVN_NonDenoised"
    
    # Run GSR on ICA-FIX'd (clean), non-variance-normalized, volumetric timeseries (takes 5-10 minutes):
    for runName in "${funcRunNames_Present[@]}" ; do
        echo "....on ${runName}..."
        
        # EXTRACT GLOBAL SIGNAL:
        inputFileHere_Extract="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}.nii.gz"
        outputFileHere_Extract="${subjDir_GSR}/${runName}.txt"
        #labelFileHere="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}.ica/mask.nii.gz"
        #fslmeants -i ${inputFileHere_Extract} -o ${outputFileHere_Extract} --label=${labelFileHere}
        fslmeants -i ${inputFileHere_Extract} -o ${outputFileHere_Extract}
        
        # APPLY GSR: 
        inputFileHere_GSR="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}.nii.gz"
        outputFileHere_GSR="${subjDir_GSR}/${runName}_GSR${extraSaveStr}.nii.gz"
        designFileHere_GSR=${outputFileHere_Extract}
        fsl_regfilt -i ${inputFileHere_GSR} -d ${designFileHere_GSR} -o ${outputFileHere_GSR} -f ${filterHere}

    done
fi

########################################################

########################################################
# Global signal regression: regress out whole-brain fMRI signal from every voxel/vertex to account for head motion, respiration/cardiac rhythms, etc. (i.e., global artifacts).
# This variant includes: GSR on cleaned (ICA-FIX'd) variance-normalized volumetric timeseries. See NOTES from runGSR_Vol_NonVN section above for detailed info.
# Generates ~3GB of data; takes ~5-10 minutes to run. 

if [ -z "$runGSR_Vol_VN_TEST" ]; then
    echo -e "Skipping global signal regression (GSR) on clean (ICA-FIX'd), variance-normalized volumetric timeseries.\n"
elif [ $runGSR_Vol_VN_TEST = true ]; then
    echo -e "Running global signal regression (GSR) on clean (ICA-FIX'd), variance-normalized volumetric timeseries...\n"
    
    # EDIT: these variables could be edited:
    export FSLOUTPUTTYPE='NIFTI_GZ'
    atlasFileHere="${baseDir_Scripts}/atlas_files/FC419_MNI2mm.nii.gz"
    filterHere=1
    
    runName="task-restAP_run-01_bold"
    
    echo "....on ${runName}..."
        
    # VARIANCE NORMALIZE: 
    docsDir="${baseDir_Scripts}"
    dirHere="${baseDir_Input_Data}${subj}/MNINonLinear/Results/${runName}/"
    fileHere="${dirHere}${runName}_hp${bandpass}_clean.nii.gz"
    savePath="${baseDir_Output_Data}${subj}/variance_normalized_timeseries/"
    saveFile="${runName}_hp${bandpass}_clean_vn"

    python3 -c "import sys; sys.path.insert(0, '${docsDir}'); import variance_normalize_timeseries as vnts; fileHere='${fileHere}'; savePath='${savePath}'; saveFile='${saveFile}'; vnts.variance_normalize(fileHere,savePath,saveFile)"        

    # EXTRACT GLOBAL SIGNAL:
    #inputFileHere_Extract="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean_vn.nii.gz"
    #inputFileHere_Extract="${baseDir_Output_Data}${subj}/variance_normalized_timeseries/${runName}_hp${bandpass}_clean_vn.nii.gz"
    outputFileHere_Extract="${subjDir_GSR}/${runName}_hp${bandpass}_clean_vn_GSR.txt"
    # NOTE: same mask/label file for all variants, but may want to check this.
    #labelFileHere="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}.ica/mask.nii.gz" 
    #fslmeants -i ${inputFileHere_Extract} -o ${outputFileHere_Extract} --label=${labelFileHere}

    # APPLY GSR: 
    #inputFileHere_GSR="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean_vn.nii.gz"
    inputFileHere_GSR="${baseDir_Output_Data}${subj}/variance_normalized_timeseries/${runName}_hp${bandpass}_clean_vn.nii.gz"
    outputFileHere_GSR="${subjDir_GSR}/${runName}_hp${bandpass}_clean_vn_GSR.nii.gz"
    designFileHere_GSR=${outputFileHere_Extract}
    fsl_regfilt -i ${inputFileHere_GSR} -d ${designFileHere_GSR} -o ${outputFileHere_GSR} -f ${filterHere}

    # EXTRACT GSR'd TIME-SERIES & SAVE TO TXT FILE: 
    #inputFileHere_Extract_GSR_TS=${outputFileHere_GSR}
    #outputFileHere_Extract_GSR_TS="${subjDir_GSR}/${subj}_${runName}_fix_clean_vn_gsr_timeseries.txt"
    #fslmeants -i ${inputFileHere_Extract_GSR_TS} -o ${outputFileHere_Extract_GSR_TS} --label=${atlasFileHere} --transpose --verbose

fi

########################################################

########################################################
# Global signal regression: regress out whole-brain fMRI signal from every voxel/vertex to account for head motion, respiration/cardiac rhythms, etc. (i.e., global artifacts).
# This variant includes: GSR on cleaned (ICA-FIX'd) variance-normalized volumetric timeseries. See NOTES from runGSR_Vol_NonVN section above for detailed info.
# Generates ~3GB of data; takes ~5-10 minutes to run. 

if [ -z "$runGSR_Vol_VN" ]; then
    echo -e "Skipping global signal regression (GSR) on clean (ICA-FIX'd), variance-normalized volumetric timeseries.\n"
elif [ $runGSR_Vol_VN = true ]; then
    echo -e "Running global signal regression (GSR) on clean (ICA-FIX'd), variance-normalized volumetric timeseries...\n"
    
    # EDIT: these variables could be edited:
    export FSLOUTPUTTYPE='NIFTI_GZ'
    atlasFileHere="${baseDir_Scripts}/atlas_files/FC419_MNI2mm.nii.gz"
    filterHere=1
    
    # Run GSR on ICA-FIX'd (clean), variance-normalized, volumetric timeseries (takes 5-10 minutes):
    for runName in "${funcRunNames_Present[@]}" ; do
        echo "....on ${runName}..."
        
        # VARIANCE NORMALIZE: 
        docsDir="${baseDir_Scripts}"
        dirHere="${baseDir_Input_Data}${subj}/MNINonLinear/Results/${runName}/"
        fileHere="${dirHere}${runName}_hp${bandpass}_clean.nii.gz"
        savePath="${baseDir_Output_Data}${subj}/variance_normalized_timeseries/"
        saveFile="${runName}_hp${bandpass}_clean_vn"

        python3 -c "import sys; sys.path.insert(0, '${docsDir}'); import variance_normalize_timeseries as vnts; fileHere='${fileHere}'; savePath='${savePath}'; saveFile='${saveFile}'; vnts.variance_normalize(fileHere,savePath,saveFile)"        

        # EXTRACT GLOBAL SIGNAL:
        #inputFileHere_Extract="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean_vn.nii.gz"
        inputFileHere_Extract="${baseDir_Output_Data}${subj}/variance_normalized_timeseries/${runName}_hp${bandpass}_clean_vn.nii.gz"
        outputFileHere_Extract="${subjDir_GSR}/${runName}_hp${bandpass}_clean_vn_GSR.txt"
        # NOTE: same mask/label file for all variants, but may want to check this.
        labelFileHere="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}.ica/mask.nii.gz" 
        fslmeants -i ${inputFileHere_Extract} -o ${outputFileHere_Extract} --label=${labelFileHere}
        
        # APPLY GSR: 
        #inputFileHere_GSR="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean_vn.nii.gz"
        inputFileHere_GSR="${baseDir_Output_Data}${subj}/variance_normalized_timeseries/${runName}_hp${bandpass}_clean_vn.nii.gz"
        outputFileHere_GSR="${subjDir_GSR}/${runName}_hp${bandpass}_clean_vn_GSR.nii.gz"
        designFileHere_GSR=${outputFileHere_Extract}
        fsl_regfilt -i ${inputFileHere_GSR} -d ${designFileHere_GSR} -o ${outputFileHere_GSR} -f ${filterHere}
        
        # EXTRACT GSR'd TIME-SERIES & SAVE TO TXT FILE: 
        #if [[ ! -f ${subjDir_GSR}/${subj}_${runName}_fix_clean_vn_gsr_timeseries.txt ]] ; then
        inputFileHere_Extract_GSR_TS=${outputFileHere_GSR}
        outputFileHere_Extract_GSR_TS="${subjDir_GSR}/${subj}_${runName}_fix_clean_vn_gsr_timeseries.txt"
        fslmeants -i ${inputFileHere_Extract_GSR_TS} -o ${outputFileHere_Extract_GSR_TS} --label=${atlasFileHere} --transpose --verbose
        #fi
    done
fi

########################################################

########################################################
# Global signal regression: regress out whole-brain fMRI signal from every voxel/vertex to account for head motion, respiration/cardiac rhythms, etc. (i.e., global artifacts).
# This variant includes: GSR on cleaned (ICA-FIX'd) non-variance-normalized surface (dense) timeseries. See NOTES from runGSR_Vol_NonVN section above for detailed info.
# Generates ~3GB of data; takes ~5-10 minutes to run. 

if [ -z "$runGSR_Surf_NonVN" ]; then
    echo -e "Skipping global signal regression (GSR) on clean (ICA-FIX'd), non-variance-normalized surface (dense) timeseries.\n"
elif [ $runGSR_Surf_NonVN = true ]; then
    echo -e "Running global signal regression (GSR) on clean (ICA-FIX'd), non-variance-normalized surface (dense) timeseries...\n"
    
    # EDIT: these variables could be edited:
    export FSLOUTPUTTYPE='NIFTI_GZ'
    atlasFileHere="${baseDir_Scripts}/atlas_files/FC419_MNI2mm.nii.gz"
    filterHere=1
    
    # Run GSR on ICA-FIX'd (clean), non-variance-normalized, volumetric timeseries (takes 5-10 minutes):
    for runName in "${funcRunNames_Present[@]}" ; do
        echo "....on ${runName}..."
        
        # EXTRACT GLOBAL SIGNAL:
        inputFileHere_Extract="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean.nii.gz"
        outputFileHere_Extract="${subjDir_GSR}/${runName}_hp${bandpass}_clean_GSR.txt"
        labelFileHere="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}.ica/mask.nii.gz"
        fslmeants -i ${inputFileHere_Extract} -o ${outputFileHere_Extract} --label=${labelFileHere}
        
        # APPLY GSR: 
        inputFileHere_GSR="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean.nii.gz"
        outputFileHere_GSR="${subjDir_GSR}/${runName}_hp${bandpass}_clean_GSR.nii.gz"
        designFileHere_GSR=${outputFileHere_Extract}
        fsl_regfilt -i ${inputFileHere_GSR} -d ${designFileHere_GSR} -o ${outputFileHere_GSR} -f ${filterHere}
        
        # EXTRACT GSR'd TIME-SERIES & SAVE TO TXT FILE: 
        if [[ ! -f ${subjDir_GSR}/${subj}_${runName}_fix_clean_gsr_timeseries.txt ]] ; then
            inputFileHere_Extract_GSR_TS=${outputFileHere_GSR}
            outputFileHere_Extract_GSR_TS="${subjDir_GSR}/${subj}_${runName}_fix_clean_gsr_timeseries.txt"
            fslmeants -i ${inputFileHere_Extract_GSR_TS} -o ${outputFileHere_Extract_GSR_TS} --label=${atlasFileHere} --transpose --verbose
        fi
    done
fi

########################################################

########################################################
# Global signal regression: regress out whole-brain fMRI signal from every voxel/vertex to account for head motion, respiration/cardiac rhythms, etc. (i.e., global artifacts).
# This variant includes:  GSR on cleaned (ICA-FIX'd) variance-normalized surface (dense) timeseries. See NOTES from runGSR_Vol_NonVN section above for detailed info.
# Generates ~3GB of data; takes ~5-10 minutes to run. 

if [ -z "$runGSR_Surf_VN" ]; then
    echo -e "Skipping global signal regression (GSR) on clean (ICA-FIX'd), variance-normalized surface (dense) timeseries.\n"
elif [ $runGSR_Surf_VN = true ]; then
    echo -e "Running global signal regression (GSR) on clean (ICA-FIX'd), variance-normalized surface (dense) timeseries...\n"
    
    # EDIT: these variables could be edited:
    export FSLOUTPUTTYPE='NIFTI_GZ'
    atlasFileHere="${baseDir_Scripts}/atlas_files/FC419_MNI2mm.nii.gz"
    filterHere=1
    
    # Run GSR on ICA-FIX'd (clean), non-variance-normalized, volumetric timeseries (takes 5-10 minutes):
    for runName in "${funcRunNames_Present[@]}" ; do
        echo "....on ${runName}..."
        
        # EXTRACT GLOBAL SIGNAL:
        inputFileHere_Extract="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean.nii.gz"
        outputFileHere_Extract="${subjDir_GSR}/${runName}_hp${bandpass}_clean_GSR.txt"
        labelFileHere="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}.ica/mask.nii.gz"
        fslmeants -i ${inputFileHere_Extract} -o ${outputFileHere_Extract} --label=${labelFileHere}
        
        # APPLY GSR: 
        inputFileHere_GSR="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean.nii.gz"
        outputFileHere_GSR="${subjDir_GSR}/${runName}_hp${bandpass}_clean_GSR.nii.gz"
        designFileHere_GSR=${outputFileHere_Extract}
        fsl_regfilt -i ${inputFileHere_GSR} -d ${designFileHere_GSR} -o ${outputFileHere_GSR} -f ${filterHere}
        
        # EXTRACT GSR'd TIME-SERIES & SAVE TO TXT FILE: 
        if [[ ! -f ${subjDir_GSR}/${subj}_${runName}_fix_clean_gsr_timeseries.txt ]] ; then
            inputFileHere_Extract_GSR_TS=${outputFileHere_GSR}
            outputFileHere_Extract_GSR_TS="${subjDir_GSR}/${subj}_${runName}_fix_clean_gsr_timeseries.txt"
            fslmeants -i ${inputFileHere_Extract_GSR_TS} -o ${outputFileHere_Extract_GSR_TS} --label=${atlasFileHere} --transpose --verbose
        fi
    done
fi

########################################################

########################################################
# Global signal regression: regress out whole-brain fMRI signal from every voxel/vertex to account for head motion, respiration/cardiac rhythms, etc. (i.e., global artifacts).
# This variant includes:  GSR on cleaned (ICA-FIX'd) & MSMAll aligned, non-variance-normalized surface (dense) timeseries. See NOTES from runGSR_Vol_NonVN section above for detailed info.
# Generates ~3GB of data; takes ~5-10 minutes to run. 

if [ -z "$runGSR_Surf_NonVN_MSMAll" ]; then
    echo -e "Skipping global signal regression (GSR) on clean (ICA-FIX'd), MSMAll aligned, non-variance-normalized surface (dense) timeseries.\n"
elif [ $runGSR_Surf_NonVN_MSMAll = true ]; then
    echo -e "Running global signal regression (GSR) on clean (ICA-FIX'd),  MSMAll aligned, non-variance-normalized surface (dense) timeseries...\n"
    
    # EDIT: these variables could be edited:
    export FSLOUTPUTTYPE='NIFTI_GZ'
    atlasFileHere="${baseDir_Scripts}/atlas_files/FC419_MNI2mm.nii.gz"
    filterHere=1
    
    # Run GSR on ICA-FIX'd (clean), non-variance-normalized, volumetric timeseries (takes 5-10 minutes):
    for runName in "${funcRunNames_Present[@]}" ; do
        echo "....on ${runName}..."
        
        # EXTRACT GLOBAL SIGNAL:
        inputFileHere_Extract="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean.nii.gz"
        outputFileHere_Extract="${subjDir_GSR}/${runName}_hp${bandpass}_clean_GSR.txt"
        labelFileHere="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}.ica/mask.nii.gz"
        fslmeants -i ${inputFileHere_Extract} -o ${outputFileHere_Extract} --label=${labelFileHere}
        
        # APPLY GSR: 
        inputFileHere_GSR="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean.nii.gz"
        outputFileHere_GSR="${subjDir_GSR}/${runName}_hp${bandpass}_clean_GSR.nii.gz"
        designFileHere_GSR=${outputFileHere_Extract}
        fsl_regfilt -i ${inputFileHere_GSR} -d ${designFileHere_GSR} -o ${outputFileHere_GSR} -f ${filterHere}
        
        # EXTRACT GSR'd TIME-SERIES & SAVE TO TXT FILE: 
        if [[ ! -f ${subjDir_GSR}/${subj}_${runName}_fix_clean_gsr_timeseries.txt ]] ; then
            inputFileHere_Extract_GSR_TS=${outputFileHere_GSR}
            outputFileHere_Extract_GSR_TS="${subjDir_GSR}/${subj}_${runName}_fix_clean_gsr_timeseries.txt"
            fslmeants -i ${inputFileHere_Extract_GSR_TS} -o ${outputFileHere_Extract_GSR_TS} --label=${atlasFileHere} --transpose --verbose
        fi
    done
fi

########################################################

########################################################
# Global signal regression: regress out whole-brain fMRI signal from every voxel/vertex to account for head motion, respiration/cardiac rhythms, etc. (i.e., global artifacts).
# This variant includes:  GSR on cleaned (ICA-FIX'd) & MSMAll aligned, variance-normalized surface (dense) timeseries. See NOTES from runGSR_Vol_NonVN section above for detailed info.
# Generates ~3GB of data; takes ~5-10 minutes to run. 

# NOTES:
# HCP does not variance normalize the MSMAll aligned data de facto, so doing it here before running GSR for this variant.

if [ -z "$runGSR_Surf_VN_MSMAll" ]; then
    echo -e "Skipping global signal regression (GSR) on clean (ICA-FIX'd), MSMAll aligned, variance-normalized surface (dense) timeseries.\n"
elif [ $runGSR_Surf_VN_MSMAll = true ]; then
    echo -e "Running global signal regression (GSR) on clean (ICA-FIX'd),  MSMAll aligned, variance-normalized surface (dense) timeseries...\n"
    
    # EDIT: these variables could be edited:
    export FSLOUTPUTTYPE='NIFTI_GZ'
    atlasFileHere="${baseDir_Scripts}/atlas_files/FC419_MNI2mm.nii.gz"
    filterHere=1
    
    # Run GSR on ICA-FIX'd (clean), non-variance-normalized, volumetric timeseries (takes 5-10 minutes):
    for runName in "${funcRunNames_Present[@]}" ; do
        echo "....on ${runName}..."
        
        # EXTRACT GLOBAL SIGNAL:
        inputFileHere_Extract="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean.nii.gz"
        outputFileHere_Extract="${subjDir_GSR}/${runName}_hp${bandpass}_clean_GSR.txt"
        labelFileHere="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}.ica/mask.nii.gz"
        fslmeants -i ${inputFileHere_Extract} -o ${outputFileHere_Extract} --label=${labelFileHere}
        
        # APPLY GSR: 
        inputFileHere_GSR="${baseDir_Input_Data}/${subj}/MNINonLinear/Results/${runName}/${runName}_hp${bandpass}_clean.nii.gz"
        outputFileHere_GSR="${subjDir_GSR}/${runName}_hp${bandpass}_clean_GSR.nii.gz"
        designFileHere_GSR=${outputFileHere_Extract}
        fsl_regfilt -i ${inputFileHere_GSR} -d ${designFileHere_GSR} -o ${outputFileHere_GSR} -f ${filterHere}
        
        # EXTRACT GSR'd TIME-SERIES & SAVE TO TXT FILE: 
        if [[ ! -f ${subjDir_GSR}/${subj}_${runName}_fix_clean_gsr_timeseries.txt ]] ; then
            inputFileHere_Extract_GSR_TS=${outputFileHere_GSR}
            outputFileHere_Extract_GSR_TS="${subjDir_GSR}/${subj}_${runName}_fix_clean_gsr_timeseries.txt"
            fslmeants -i ${inputFileHere_Extract_GSR_TS} -o ${outputFileHere_Extract_GSR_TS} --label=${atlasFileHere} --transpose --verbose
        fi
    done
fi

########################################################

########################################################
# Denoise task data with motion regression and aCompCor:
# NOTE: This is an alternative to ICA-FIX, and is supported by Ciric et al., 2017

if [ -z "$runTaskDenoising" ]; then
    echo -e "Skipping task denoising.\n"
elif [ $runTaskDenoising = true ]; then
    echo -e "Running task denoising...\n"
    
fi

########################################################

########################################################
# Denoise rest data with motion regression and aCompCor:
# NOTE: This is an alternative to ICA-FIX, and is supported by Ciric et al., 2017

if [ -z "$restRestDenoising" ]; then
    echo -e "Skipping rest denoising.\n"
elif [ $restRestDenoising = true ]; then
    echo -e "Running rest denoising...\n"
    
fi

########################################################

########################################################
# Parcellate surface data (dense vertices) using various popular regional atlases: 

if [ -z "$runParcellateData" ]; then
    echo -e "Skipping data parcellation.\n"
elif [ $runParcellateData = true ]; then
    echo -e "Running data parcellation...\n"
    
fi

########################################################

########################################################
# Task GLM: 
# NOTE: this is required for contrasts and condition-wise task-FC

if [ -z "$runTaskGLM" ]; then
    echo -e "Skipping task GLM.\n"
elif [ $runTaskGLM = true ]; then
    echo -e "Running task GLM...\n"
    
fi

########################################################

########################################################
# Perform some common task contrasts:
# For Stroop: high vs low conflict conditions 
# For Hammer: amygdala responses to fear emotion conditions vs others. 

if [ -z "$runTaskContrasts" ]; then
    echo -e "Skipping task contrasts.\n"
elif [ $runTaskContrasts = true ]; then
    echo -e "Running task contrasts...\n"
    
fi

########################################################

########################################################
# Estimate rest-FC for each functional run. 

if [ -z "$runRestFC" ]; then
    echo -e "Skipping rest-FC estimation.\n"
elif [ $runRestFC = true ]; then
    echo -e "Running rest-FC estimation...\n"
    
    #if [ fcMethod = "pearson" ]; then
    
    #elif [ fcMethod = "multiple_regression" ]; then
    
    #fi 
fi

########################################################

########################################################
# Estimate task-FC for each functional state (i.e., "task general"). 

if [ -z "$runTaskFCGeneral" ]; then
    echo -e "Skipping task-FC (general) estimation.\n"
elif [ $runTaskFCGeneral = true ]; then
    echo -e "Running task-FC (general estimation...\n"
    
fi

########################################################

########################################################
# Etimate task-FC for each condition within each functional state (i.e., "by condition" or "condition-wise").

if [ -z "$runTaskFCByCond" ]; then
    echo -e "Skipping task-FC (by condition) estimation.\n"
elif [ $runTaskFCByCond = true ]; then
    echo -e "Running task-FC (by condition) estimation...\n"
    
fi

########################################################

########################################################
# Run common network diagnostics on rest-FC graphs

if [ -z "$runRestNetMetrics" ]; then
    echo -e "Skipping network diagnostics for rest-FC.\n"
elif [ $runRestNetMetrics = true ]; then
    echo -e "Running network diagnostics for rest-FC...\n"
    
fi

########################################################

########################################################
# Run common network diagnostics on task-FC (general) graphs

if [ -z "$runTaskNetMetricsGeneral" ]; then
    echo -e "Skipping network diagnostics for task-FC (general).\n"
elif [ $runTaskNetMetricsGeneral = true ]; then
    echo -e "Running network diagnostics for task-FC (general)...\n"
    
fi

########################################################

########################################################
# Run common network diagnostics on task-FC (by condition) graphs

if [ -z "$runTaskNetMetricsByCond" ]; then
    echo -e "Skipping network diagnostics for task-FC (by condition).\n"
elif [ $runTaskNetMetricsByCond = true ]; then
    echo -e "Running network diagnostics for task-FC (by condition)...\n"
    
fi

########################################################