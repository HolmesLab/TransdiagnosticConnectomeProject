# C. Cocuzza, 2023

import os
import numpy as np
import nibabel as nib


def variance_normalize(timeseriesFile,savePath,saveFile):
    '''
    timeseriesFile: entire path with filename; either .nii.gz (4D) or .dtseries.nii (2D)
    savePath:       entire path to save (make sure to close with /) 
    saveFile:       file name to save, use extra string like "_vn" if need be 
    '''
    
    dataHere = nib.load(timeseriesFile).get_fdata().copy()
    nDims = dataHere.ndim
    
    if nDims==4:
        dataHereVN = (dataHere - np.nanmean(dataHere,axis=3)[:,:,:,None]) / np.nanstd(dataHere,axis=3)[:,:,:,None]
        dataHereAff = nib.load(timeseriesFile)
        dataHereNII = nib.Nifti1Image(dataHereVN, dataHereAff.affine)
        nib.save(dataHereNII, savePath + saveFile + '.nii.gz')
        #np.save(savePath + saveFile + '.npy',dataHereVN)
        
    elif nDims==3: 
        print(f"Timeseries file has 3 dimensions, expected either 4D volumetric or 2D surface, please check and re-run")
        
    elif nDims==2: 
        nRows,nCols = dataHere.shape
        if nRows<nCols: 
            dataHere = dataHere.T.copy()
            print(f"Original timeseries file has {nRows} x {nCols} dimensions. "+
                  f"Expected dimensions is vertices x TRs, where vertices are likely > TRs, "+
                  f"so transposing to be {nCols} x {nRows} dimensions, but please correct and rerun if need be")
        dataHereVN = (dataHere - np.nanmean(dataHere,axis=1)[:,None]) / np.nanstd(dataHere,axis=1)[:,None]
        np.save(savePath + saveFile + '.npy',dataHereVN)