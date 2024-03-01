# C. Cocuzza, 2023. A function to estimate functional connectivity. 

import numpy as np
import nibabel as nib
import numpy.ma as ma

def fcEstimation(inputDataFile,outputPath,subjID,extraSaveStr='',fcMethod='pearson',fillDiagVal='nan',fcForSepBlocks=False,flipDims=False,verbose=False):
    '''
    ######################################################
    INPUTS:
        inputDataFile  : REQUIRED. A string; full path and file name to input timeseries. Currently supported file types: '.nii.gz', '.dtseries.nii', '.ptseries.nii', '.npy'.
                                   IMPORTANT NOTE: data MUST have TRs / conditions as the last dimension (space x time, or space x space x space x time). HCP sometimes saves 
                                   dense timeseries as TRs x vertices, so this should be reformatted before inputting here.
                                   IMPORTANT NOTE: this assumes 1 participant's data is being entered (or perhaps an group average; not recommended).
        outputPath     : REQUIRED. A string; full output path to save results.
        subjID         : REQUIRED. A string; participant ID as used throughout study.
        extraSaveStr   : OPTIONAL. A string; suffix to specify things like: surface data, parcellation method, etc.
        fcMethod       : OPTIONAL. A string; currently supports either 'pearson' or 'multiple_regression' (case/spelling sensitive for now).
        fillDiagVal    : OPTIONAL. A string; currently supports either 'nan' or '0' (case/spelling sensitive for now). Sets self-connections to NaN or 0.
        fcForSepBlocks : OPTIONAL. Boolean; set to True if you want the last dimension to be treated as separate blocks/conditions/etc. and have FC estimation performed seperately for each. 
                                   IMPORTANT NOTE: MUST be used if data is 3D (nodes x TRs x blocks). 
        flipDims       : OPTIONAL. Boolean; only use for 2D data that is time x space, to put into space x time. 
        verbose        : OPTIONAL. If True, will print extra info.
        
    ######################################################
    OUTPUTS:
        Saves result as: ~/<outputPath>/"FC_<subjID>_<fcMethod>_<extraSaveStr>.npy"
    '''
    
    ################################################
    # LOAD data 
    if '.nii' in inputDataFile:
        dataHere = nib.load(inputDataFile).get_fdata().copy()
        goodToRun = True
        
    elif '.npy' in inputDataFile:
        dataHere = np.load(inputDataFile).copy()
        goodToRun = True
        
    else:
        print(f"ERROR: file type in <inputDataFile> is not a nifti or numpy array, please check and re-run; aborting.\n")
        goodToRun = False 
        
    if goodToRun:
        
        ################################################
        # Data management
        numDims = dataHere.ndim
        
        if numDims==4: # volumetric
            [numVox_X,numVox_Y,numVox_Z,numTRs] = dataHere.shape
            goodToRun2 = True
            if verbose:
                print(f"Timeseries dimensions: {numVox_X} x {numVox_Y} x {numVox_Z} x {numTRs}")
            
        elif numDims==2:
            if flipDims:
                dataHere = dataHere.T.copy()
            [numNodes,numTRs] = dataHere.shape
            goodToRun2 = True
            if verbose:
                print(f"Timeseries dimensions: {numNodes} x {numTRs}")
                
        elif numDims==3:
            if fcForSepBlocks:
                [numNodes,numTRs,numBlocks] = dataHere.shape
                goodToRun2 = True
                if verbose:
                    print(f"Timeseries dimensions: {numNodes} x {numTRs} x {numBlocks}")
            elif not fcForSepBlocks:
                print(f"WARNING: data in <inputDataFile> is 3D (and <fcForSepBlocks> was not set to True), suggesting a truncated/averaged volumetric timeseries file. Please check and re-run; aborting.")
                goodToRun2 = False
            
        else:
            print(f"ERROR: data in <inputDataFile> is neither 2D, 3D, or 4D, Please check and re-run; aborting.")
            goodToRun2 = False
                
        if goodToRun2:
            ################################################
            # Estimate FC 
            if fillDiagVal=='nan':
                fillDiagVal = np.nan
            if fillDiagVal=='0':
                fillDiagVal = 0
                
            if fcMethod=='pearson':
                
                # NOTE: in case NaN's are present in data, using numpy.ma and mask invalid skips them. Can also use pandas in future if need be.
                
                if numDims == 3:
                    if verbose:
                        print(f"Estimating FC with pearsons correlation over each block/condition (3D timeseries data)...")
                    fcArray = np.zeros((numNodes,numNodes,numBlocks))
                    for blockNum in range(numBlocks):
                        fcArray_ThisBlock = ma.corrcoef(ma.masked_invalid(dataHere[:,:,blockNum]),rowvar=True).copy() 
                        fcArray_ThisBlock = ma.getdata(fcArray_ThisBlock).copy()
                        np.fill_diagonal(fcArray_ThisBlock,fillDiagVal)
                        fcArray[:,:,blockNum] = fcArray_ThisBlock.copy()
                        
                elif numDims == 2:
                    if verbose:
                        print(f"Estimating FC with pearsons correlation on 2D timeseries data...")
                    fcArray = ma.corrcoef(ma.masked_invalid(dataHere),rowvar=True).copy() 
                    fcArray = ma.getdata(fcArray).copy()
                    np.fill_diagonal(fcArray,fillDiagVal)
                
            #elif fcMethod=='multiple_regression':
                
                
            ################################################
            # SAVE results 
            outputFileHere = outputPath + 'FC_' + subjID + '_' + fcMethod + extraSaveStr + '.npy'
            np.save(outputFileHere,fcArray)