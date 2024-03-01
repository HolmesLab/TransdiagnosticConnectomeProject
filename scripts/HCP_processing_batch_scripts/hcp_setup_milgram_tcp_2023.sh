#!/bin/bash 
# Modified by Ravi Mill for CPRO2_learning 03/16/18. Modified by Carrisa Cocuzza 2023 for Yale HPC (Milgram cluster) and TCP dataset. 
# NOTE: This script must be SOURCED to correctly setup the environment prior to running any of the other HCP scripts contained here

# Change this: this is the base directory for SCRIPTS (not data). See hcp_main_milgram_tcp_2023.sh for more on data directories, etc.
basedir=/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/

# Set up FSL (if not already done so in the running environment)
# Correct the FSLDIR setting below for your setup
#export FSLDIR=${basedir}/HCP_v2_prereqs/fsl
export FSLDIR=/gpfs/milgram/apps/hpc.rhel7/software/FSL/6.0.5-centos7_64/
. ${FSLDIR}/etc/fslconf/fsl.sh

# Let FreeSurfer know what version of FSL to use
# FreeSurfer uses FSL_DIR instead of FSLDIR to determine the FSL version
export FSL_DIR="${FSLDIR}"

# Set up FreeSurfer (if not already done so in the running environment)
# Correct the FREESURFER_HOME setting for your setup
#export FREESURFER_HOME=${basedir}/HCP_v2_prereqs/freesurfer
#export FREESURFER_HOME=/gpfs/milgram/apps/hpc.rhel7/software/FreeSurfer/7.3.2-centos7_x86_64/
export FREESURFER_HOME=/gpfs/milgram/apps/hpc.rhel7/software/FreeSurfer/6.0.0/
source ${FREESURFER_HOME}/SetUpFreeSurfer.sh > /dev/null 2>&1

# Set up specific environment variables for the HCP Pipeline
#export HCPPIPEDIR=${basedir}/HCP_v2_prereqs/HCP_Pipelines_v3_25_1
export HCPPIPEDIR=${basedir}/HCP_v2_prereqs/HCPpipelines-4.7.0/
#export CARET7DIR=${basedir}/HCP_v2_prereqs/workbench/bin_rh_linux64/
export CARET7DIR=/gpfs/milgram/apps/hpc.rhel7/software/ConnectomeWorkbench/1.4.2/bin_rh_linux64/
export MSMBINDIR=${basedir}/HCP_v2_prereqs/MSMbinaries/ecr05/MSM_HOCR_v2/Centos/
export MSMCONFIGDIR=${HCPPIPEDIR}/MSMConfig/

# RM edit
#*FSL_FIXDIR is essential for FIX; MATLAB_COMPILER_RUNTIME is optional (need for running matlab scripts as 'compiled' binaries; running as interpreted for now, but specify anyway)
#*Also make sure you modify the settings.sh file in FSL_FIXDIR appropriately
#*Note that certain scripts in the fixdir have been modified by RM so that it runs smoothly on different systems (e.g. addpath to cifti toolboxes for matlab functions)

#export MATLAB_COMPILER_RUNTIME=${basedir}/HCP_v2_prereqs/MATLAB_Compiler_Runtime/v83
export MATLAB_COMPILER_RUNTIME=${basedir}/HCP_v2_prereqs/MATLAB_Compiler_Runtime_2017b_v93

#export FSL_FIXDIR=${basedir}/HCP_v2_prereqs/fix1.065
#export FSL_FIXDIR=${HCPPIPEDIR}/ICAFIX
export FSL_FIXDIR=${basedir}/HCP_v2_prereqs/fix-1.06.15

#also need to add basedir for fixica to work (in settings.sh)
export FSL_FIX_basedir=${basedir}

export HCPPIPEDIR_Templates=${HCPPIPEDIR}/global/templates
export HCPPIPEDIR_Bin=${HCPPIPEDIR}/global/binaries
export HCPPIPEDIR_Config=${HCPPIPEDIR}/global/config

export HCPPIPEDIR_PreFS=${HCPPIPEDIR}/PreFreeSurfer/scripts
export HCPPIPEDIR_FS=${HCPPIPEDIR}/FreeSurfer/scripts
export HCPPIPEDIR_PostFS=${HCPPIPEDIR}/PostFreeSurfer/scripts
export HCPPIPEDIR_fMRISurf=${HCPPIPEDIR}/fMRISurface/scripts
export HCPPIPEDIR_fMRIVol=${HCPPIPEDIR}/fMRIVolume/scripts
export HCPPIPEDIR_tfMRI=${HCPPIPEDIR}/tfMRI/scripts
export HCPPIPEDIR_dMRI=${HCPPIPEDIR}/DiffusionPreprocessing/scripts
export HCPPIPEDIR_dMRITract=${HCPPIPEDIR}/DiffusionTractography/scripts
export HCPPIPEDIR_Global=${HCPPIPEDIR}/global/scripts
export HCPPIPEDIR_tfMRIAnalysis=${HCPPIPEDIR}/TaskfMRIAnalysis/scripts

#*RM edit - adding export path for global/matlab scripts - these contain ciftisave/open etc that are required for FIXICA to run correctly
export HCPPIPEDIR_global_matlab=${HCPPIPEDIR}/global/matlab
export FSL_FIX_GIFTI=${HCPPIPEDIR}/global/matlab/gifti-1.6
export HCPCIFTIRWDIR=${HCPPIPEDIR}/global/matlab/cifti-matlab

#try to reduce strangeness from locale and other environment settings
export LC_ALL=C
export LANGUAGE=C
#POSIXLY_CORRECT currently gets set by many versions of fsl_sub, unfortunately, but at least don't pass it in if the user has it set in their usual environment
unset POSIXLY_CORRECT

# R? 
export R_DIR=/gpfs/milgram/apps/hpc.rhel7/software/R