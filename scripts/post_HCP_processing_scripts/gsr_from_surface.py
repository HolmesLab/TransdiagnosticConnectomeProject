# Carrisa V. Cocuzza, 2023. Yale University. Holmes Lab.

################################################
# A function to run global signal regression on surface timeseries. 
# Requires create_masks_HCP.sh to have been run; see post_hcp_main.sh 

# NOTES:
# In the transdiagnostic connectome project, we did not use derivatives of the global signal as extra regressors, but this can be done here if deemed necessary by the user. 
# It's likely with HCP-style ICA-FIX, these added regressors are not needed and would contribute to loss of temporal degrees of freedom. 

# Here are some useful resources: 

# Ciric, R., Wolf, D. H., Power, J. D., Roalf, D. R., Baum, G. L., Ruparel, K., Shinohara, R. T., Elliott, M. A., Eickhoff, S. B., Davatzikos, C., Gur, R. C., Gur, R. E., Bassett, D. S., & Satterthwaite, T. D. (2017). Benchmarking of participant-level confound regression strategies for the control of motion artifact in studies of functional connectivity. NeuroImage, 154, 174–187. https://doi.org/10.1016/j.neuroimage.2017.03.020

# Lindquist, M. A., Geuter, S., Wager, T. D., & Caffo, B. S. (2019). Modular preprocessing pipelines can reintroduce artifacts into fMRI data. Human Brain Mapping, 40(8), 2358–2376. https://doi.org/10.1002/hbm.24528

# Parkes, L., Fulcher, B., Yücel, M., & Fornito, A. (2018). An evaluation of the efficacy, reliability, and sensitivity of motion correction strategies for resting-state functional MRI. NeuroImage, 171, 415–436. https://doi.org/10.1016/j.neuroimage.2017.12.073

# Burgess, G. C., Kandala, S., Nolan, D., Laumann, T. O., Power, J. D., Adeyemo, B., Harms, M. P., Petersen, S. E., & Barch, D. M. (2016). Evaluation of Denoising Strategies to Address Motion-Correlated Artifacts in Resting-State Functional Magnetic Resonance Imaging Data from the Human Connectome Project. Brain Connectivity, 6(9), 669–680. https://doi.org/10.1089/brain.2016.0435

################################################
# Import python tools
import numpy as np
import os
import sys
import nibabel as nib
from scipy import signal
import hcp_utils as hcp

# Note: this can be improved/modified: 
sys.path.insert(0, '/gpfs/milgram/project/holmes/cvc23/ClinicalNetDynamics/docs/scripts/post_hcp_processing/')
import regression

################################################
# Define variables 
numCortVerts = 64984 # HCP convention

################################################
# Main function
def gsr_from_surface(subjID,
                     functionalRunStr,
                     globalMaskFile,
                     timeSeriesSurfaceFile,
                     timeSeriesVolumeFile,
                     outputSavePath,
                     extraSaveStr='',
                     useDerivatives=False,
                     verbose=True):
    '''
    INPUTS:
        subjID                : A string. The participant ID used throughout project's directories.
        functionalRunStr      : A string. The functional run being processed. Should match project's directories. 
        globalMaskFile        : A string. The full path (directory and file) to the global mask file. Likely .nii.gz.
        timeSeriesSurfaceFile : A string. The full path (directory and file) to the surface time series file you'd 
                                like to run GSR on. Likely .dtseries.nii.
                                Dimensions: time x space (HCP standard = TRs x vertices/grayordinates).
        timeSeriesVolumeFile  : A string. The full path (directory and file) to the volumetric time series file that 
                                best matches <timeSeriesSurfaceFile>. Likely .nii.gz. In HCP conventions, the surface 
                                file may be <functionalRunStr>_Atlas_MSMAll_hp2000_clean.dtseries.nii and the 
                                volumetric file would be <functionalRunStr>_hp2000_clean.nii.gz.
                                Dimensions: space x space x space x time (HCP standard = X x Y x Z x TRs).
                                NOTE: x/y/z need to match <globalMaskFile>. Common for 2 mm = 91 x 109 x 91.
        outputSavePath        : A string. The full path (directory) for saving the final result to. 
        extraSaveStr          : Optional. A string. Added string with info to append to your saved result. 
        useDerivatives        : Optional. Boolean. Whether or not to use derivatives of global signal in regression.
        verbose               : Optional. Boolean. Whether or not to print some extra info; useful for debugging. 
    
    OUTPUT:
        - saves residualized timeseries as: /<outputSavePath>/<functionalRunStr><extraSaveStr>'_GSR_From_Surface.npy'
        - also saves residualized timeseries with HCP-style surface adjustment as: /<outputSavePath>/<functionalRunStr><extraSaveStr>'_GSR_From_Surface_SurfAdj.npy'
    '''
    #############################################
    # LOAD DATA 
    globalMask = nib.load(globalMaskFile).get_fdata().copy()
    if verbose:
        print(f"Global mask dimensions: {globalMask.shape}")

    fMRI4d = nib.load(timeSeriesVolumeFile).get_fdata().copy()
    if verbose:
        print(f"Functional data volumetric dimensions ({functionalRunStr}): {fMRI4d.shape}")

    # NOTE: assumes HCP dtseries convention of flipping dimensions; can add catch for this though if needed 
    funcData = nib.load(timeSeriesSurfaceFile).get_fdata().T.copy()
    if verbose:
        print(f"Functional data surface dimensions ({functionalRunStr}): {funcData.shape}")

    #############################################
    # Set up global signal mask 
    globalMask = np.asarray(globalMask,dtype=bool) # binary --> boolean 
    globaldata = fMRI4d[globalMask].copy() # mask
    globaldata = signal.detrend(globaldata,axis=1,type='constant') # detrend constant 
    globaldata = signal.detrend(globaldata,axis=1,type='linear') # detrend linear 
    global_signal1d = np.nanmean(globaldata,axis=0) # get mean of masked voxels 

    #############################################
    # Create derivative time series (with backward differentiation, consistent with 1d_tool.py -derivative option)
    if useDerivatives:
        global_signal1d_deriv = np.zeros(global_signal1d.shape)
        global_signal1d_deriv[1:] = global_signal1d[1:] - global_signal1d[:-1]

    #############################################
    # Set up regressors
    if useDerivatives:
        globalRegressors = np.vstack((global_signal1d,global_signal1d_deriv))
    elif not useDerivatives:
        globalRegressors = np.zeros((1,global_signal1d.shape[0]))
        globalRegressors[0,:] = global_signal1d.copy()
        
    #############################################
    # Run regression 
    betas, resid = regression.regression(funcData.T, globalRegressors.T, constant=True)
    betas = betas.T.copy()
    residual_ts = resid.T.copy()

    #############################################
    # SAVE 
    saveFileHere = outputSavePath + '/' + functionalRunStr + extraSaveStr + '_GSR_From_Surface.npy'
    np.save(saveFileHere,residual_ts)

    #############################################
    # Adjust for HCP surface space and save (to be able to use Homotopic cortical parcellations)
    #residual_ts_SurfAdj = np.zeros_like(residual_ts)
    residual_ts_SurfAdj = np.zeros((numCortVerts,residual_ts.shape[1]))
    for timePointIx in range(residual_ts.shape[1]):
        #residual_ts_SurfAdj[:numCortVerts,timePointIx] = hcp.cortex_data(residual_ts[:numCortVerts,:][:,timePointIx]).copy()
        #residual_ts_SurfAdj[numCortVerts:,timePointIx] = residual_ts[numCortVerts:,:][:,timePointIx].copy()
        residual_ts_SurfAdj[:,timePointIx] = hcp.cortex_data(residual_ts[:numCortVerts,:][:,timePointIx]).copy()

    saveFileHere_Adj = outputSavePath + '/' + functionalRunStr + extraSaveStr + '_GSR_From_Surface_SurfAdj.npy'
    np.save(saveFileHere_Adj,residual_ts_SurfAdj)