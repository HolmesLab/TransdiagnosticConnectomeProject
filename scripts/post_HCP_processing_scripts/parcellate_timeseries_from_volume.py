# C. Cocuzza, 2023 
# Function is similar to parcellate_timeseries.py, but uses volumetric functional data. 
# Requires having a volumetric atlas; currently best supported by Schaefer/Yeo atlases. 

import numpy as np
import nibabel as nib

def parcellate_timeseries(inputAtlasLabels_File,
                          inputTimeseries_File,
                          dropOutVals=np.nan,
                          saveOutput=True,
                          outputTimeseries_Path='',
                          subjID_Str='',
                          funcRun_Str='',
                          atlasSave_Str='Atlas_From_Vol',
                          parcellationMethod='mean',
                          verbose=True):
    
    '''
    INPUTS:
        inputAtlasLabels_File : A string: full path to atlas label file (3D for volumetric/voxel data). 
                                Should be either .nii.gz or .npy. Here, dropout values should match 
                                the dropOutVals variable below, and all other data should be integers 
                                corresponding to region numbers.
        inputTimeseries_File  : A string: full path to input 4D timeseries file. X/Y/Z dimensions 
                                need to match atlas label file. Should be either .nii.gz or .npy.
                                Dimensions: x, y, z, TRs.
        dropOutVals           : Either 0 or np.nan; default is np.nan.
                                NOTE: if using np.nan, start the labels at 1 (not 0 for python indexing).
        saveOutput            : Optional. A boolean: whether or not to save output.
        outputTimeseries_Path : Optional. A string: full path to save output (parcellated data) 
                                (required with above boolean).
        subjID_St             : Optional. A string: participant ID; should match project files.
        funcRun_Str           : Optional. A string: functional run name. should match project files.
        atlasSave_Str         : Optional. A string with a "tag" for the atlas to be used for 
                                saving the output parcellated timeseries, for example: 'Schaefer_400'. 
                                NOTE: if saveOutput=True and this is not set, it will save with 
                                '_Atlas_From_Vol' in the file name. Given this is the last string used to 
                                generate the file name, this can also be used to designate alternate 
                                pipelines, ex: atlasSave_Str = 'Schaefer_400_Original' and 
                                atlasSave_Str = 'Schaefer_400_Denoised'.
        parcellationMethod    : Optional. A string: a string to set the method to compute region values from 
                                braindordinates. Options supported: 'mean' (default), 'max', 'min', 'sum', 
                                'stdev'; NOTE: can add more (see: 
                                https://www.humanconnectome.org/software/workbench-command/-cifti-parcellate); 
                                NOTE: currently supports exact string usage (i.e., will not support 'MEAN', 
                                must be 'mean'), but will fix in future. Default is mean.
        verbose               : Optional. default is True to return prints of all steps of the function 
                                (useful for debugging).
                                
    OUTPUT:
        dataHere_Parcels      : returned regions x TRs array. NOTE: this is also saved by default as npy array, see 
                                saveOutput in the input section above.                                
    
    '''
    
    if verbose:
        print(f"Running parellate_timeseries with verbose prints, set verbose=False if you'd like to silence prints.")
        
    ################################################################################################
    # Load atlas: 
    
    # Check the extension of atlas file as either dlabel.nii or .npy; note that there may be better ways to do this 
    # Load the atlas label file and perform some checks on dimensions, etc. 
    if inputAtlasLabels_File.endswith('.nii.gz'):
        atlasLabels = nib.load(inputAtlasLabels_File).get_fdata().astype(int).copy()
        if verbose:
            print(f"Loading atlas file {inputAtlasLabels_File}...")
        
    elif inputAtlasLabels_File.endswith('.npy'):
        atlasLabels = np.load(inputAtlasLabels_File).copy()
        if verbose:
            print(f"Loading atlas file {inputAtlasLabels_File}...")
            
    if verbose:
        print(f"Atlas shape: {atlasLabels.shape}\n")

    ################################################################################################
    # Load data:
    if inputTimeseries_File.endswith('.nii.gz'):
        dataHere = nib.load(inputTimeseries_File).get_fdata().astype(int).copy()
        if verbose:
            print(f"Loading volumetric timeseries file {inputTimeseries_File}...")
        
    elif inputTimeseries_File.endswith('.npy'):
        dataHere = np.load(inputTimeseries_File).copy()
        if verbose:
            print(f"Loading volumetric timeseries file {inputTimeseries_File}...")
            
    ################################################################################################
    # Perform checks on data 
    numVoxX,numVoxY,numVoxZ = atlasLabels.shape
    numVoxX_Data,numVoxY_Data,numVoxZ_Data,numTRs = dataHere.shape
            
    checkDims = np.zeros((3))
    if numVoxX != numVoxX_Data:
        checkDims[0] = 1
    if numVoxY != numVoxY_Data:
        checkDims[1] = 1
    if numVoxZ != numVoxZ_Data:
        checkDims[2] = 1
                
    if np.sum(checkDims)!=0:
        print(f"Participant {subjIDHere} (py index {subjIxHere}): one or more data dimensions does not match atlas, please check and re-run.")
        goodToRun = False 
    elif np.sum(checkDims)==0:
        goodToRun = True
                
    ################################################################################################
    # PARCELLATE:
    if goodToRun:
        
        numRegions = np.unique(atlasLabels)[-1]
        
        dataHere_Parcels = np.zeros((numRegions,numTRs))
        for regionIx in range(numRegions):
            r,c,d = np.where(atlasLabels==(regionIx+1))
            
            ################################################################################################
            # Aggregate vertices in given parcel based on method chosen; taking the mean is most common 
            if parcellationMethod=='mean':    
                dataHere_Parcels[regionIx,:] = np.nanmean(dataHere[r,c,d,:],axis=0).copy()

            elif parcellationMethod=='min':
                dataHere_Parcels[regionIx,:] = np.nanmin(dataHere[r,c,d,:],axis=0).copy()

            elif parcellationMethod=='max':
                dataHere_Parcels[regionIx,:] = np.nanmax(dataHere[r,c,d,:],axis=0).copy()

            elif parcellationMethod=='sum':
                dataHere_Parcels[regionIx,:] = np.nansum(dataHere[r,c,d,:],axis=0).copy()

            elif parcellationMethod=='stdev':
                dataHere_Parcels[regionIx,:] = np.nanstd(dataHere[r,c,d,:],axis=0).copy()
                
        ################################################################################################
        # Save parcellated timeseries and return
        if saveOutput:
            outFileName = subjID_Str + '_' + funcRun_Str + '_Parcellated_Timeseries_' + atlasSave_Str + '.npy'

            if verbose:
                print(f"Saving parcellated timeseries to: {outputTimeseries_Path + outFileName}...")
            np.save(outputTimeseries_Path + outFileName,dataHere_Parcels)

        return dataHere_Parcels
        
################################################################################################
# NOTES:
# Other checks that can be added: 
# 1) Check that region numbers (labels) are consecutive 
