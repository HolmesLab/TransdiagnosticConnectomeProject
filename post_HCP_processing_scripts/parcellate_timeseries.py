# C. Cocuzza, 2023
# Python code to flexibly parcellate HCP-style fMRI timeseries data: vertices (dense) --> regions 

# Inspiration: I previously wrote a shell script 'parcellate_Shaefer_CND.sh' using the HCP workbench command 'wb_command -cifti-parcellate'. 
# This tool appears to require the input atlas and the input dense timeseries to be in very specific formats, which are not always available openly.
# Instead, I extracted the labels as numpy arrays (and verified with a few methods, including fieldtrip in MATLAB and hcp-utils in python), and hand-coded 
# the parcellation procedure (default: taking the mean; other methods supported below). 
# I think this is more flexible (but loses some cifti functionality, like header/structure info); below is a draft (which can be improved). 

# NOTE: this is generally for cortical parcellations; the only atlas that can handle subcortical as well is the CABNP (https://github.com/ColeLab/ColeAnticevicNetPartition),
# so there are special checks here for that atlas, but most uses will return parcellated cortices only. 

# TO DO: 
# Allow for csv/txt label files
# Allow for .mat label files and arrays 
# Allow for h5 / pandas? 

################################################
# IMPORTS
import numpy as np
import nibabel as nib # See here for install info if need be: https://nipy.org/nibabel/installation.html
import hcp_utils as hcp # See here for install info if need be: https://pypi.org/project/hcp-utils/

################################################
# Set some common (given HCP conventions) variables 
numVertsCort = 64984
numVertsAll = 91282
numVertsList = [numVertsCort,numVertsAll]

numVertsCort_Dropped = 59412 

blankArr_HCP = np.ones((numVertsCort_Dropped))
blankArr_HCP_Filled = hcp.cortex_data(blankArr_HCP, fill=0)

droppedVertsCort_HCP = np.where(blankArr_HCP_Filled==0)[0]
numVertsDropped_HCP = droppedVertsCort_HCP.shape[0] # should be 5572

################################################
# Define flexible parcellation function
def parcellate_timeseries(inputAtlasLabels_File,
                          inputTimeseries_File,
                          dropOutVals=np.nan,
                          saveOutput=True,
                          outputTimeseries_Path='',
                          subjID_Str='',
                          funcRun_Str='',
                          atlasSave_Str='Atlas',
                          parcellationMethod='mean',
                          verbose=True):
    '''
    INPUTS:
    
        inputAtlasLabels_File    : full path and file name for parcellation atlas label file (where labels are integers 
                                   or the special float NaN). Preferred: a .npy file, where NaN is used for dropout regions, 
                                   however, you can set 'dropOutVals' (see below) to 0. Cifti dlabels are also supported, 
                                   but make sure they are accurate. Labels can either be a vector of size 64984 (cortex) 
                                   or 91282 (cortex & subcortex). It's preferred to start labels at 1 and go to max parcel 
                                   number (e.g., 360 in Glasser parcellation); even though python convention starts at 0, 
                                   this allows some files to use 0 as the label to ignore (see dropOutVals below).
    
        inputTimeseries_File     : A string with the full path and file name for the input dense timeseries. NOTE: Can either 
                                   be a .npy array or .dtseries.nii; timeseries data should be in vertex x TR format (but a 
                                   check is included to flip dimensions if need be, as long as one of them is either 64984 or
                                   91282.
    
        dropOutVals              : Default is NaN. The label values that indicate drop out / unlabeled / missing / etc. vertices 
                                   that the given atlas would like to ignore. 0 is another option.
    
        saveOutput               : Default is True. Set to False if you just want to return the parcellated timeseries but don't 
                                   want to save it.
    
        outputTimeseries_Path    : Optional; A string with the full path only to save the resulting parcellated timeseries as a 
                                   numpy array. NOTE: File name is set as: 
                                   '<subjID_Str>_<funcRun_Str>_Parcellated_Timeseries_<atlasSave_Str>.npy' 
                                   and only saved when saveOutput is set to True (default).
    
        subjID_Str               : Optional (used with saveOutput=True); A string with the participant ID to be used for saving 
                                   the output parcellated timeseries. NOTE: if saveOutput=True and this is not set, there will 
                                   just be an empty space in the file name, so it's good to set it to something.
    
        funcRun_Str              : Optional (used with saveOutput=True); A string with the functional run ID (ex: 'rest_run_1', 
                                   'task_Stroop', etc.) to be used for saving the output parcellated timeseries. NOTE: if 
                                   saveOutput=True and this is not set, there will just be an empty space in the file name, so 
                                   it's good to set it to something.
    
        atlasSave_Str            : Optional (used with saveOutput=True); A string with a "tag" for the atlas to be used for 
                                   saving the output parcellated timeseries, for example: 'Schaefer_400'. NOTE: if 
                                   saveOutput=True and this is not set, it will save with '_Atlas' in the file name. Given this 
                                   is the last string used to generate the file name, this can also be used to designate 
                                   alternate pipelines, ex: atlasSave_Str = 'Schaefer_400_Original' and atlasSave_Str = 
                                   'Schaefer_400_Denoised'.
    
        parcellationMethod       : Optional (default is mean); a string to set the method to compute region values from 
                                   braindordinates. Options supported: 'mean' (default), 'max', 'min', 'sum', 'stdev'; NOTE: 
                                   can add more (see: 
                                   https://www.humanconnectome.org/software/workbench-command/-cifti-parcellate); 
                                   NOTE: currently supports exact string usage (i.e., will not support 'MEAN', must be 'mean'), 
                                   but will fix in future.
    
        verbose                  : Optional; default is True to return prints of all steps of the function (useful for 
                                   debugging).
    
    OUTPUT:
    
        outputTimeseries         : returned regions x TRs array. NOTE: this is also saved by default as npy array, see 
                                   saveOutput in the input section above.
    
    '''
    
    if verbose:
        print(f"Running parellate_timeseries with verbose prints, set verbose=False if you'd like to silence prints.")
        
    ################################################################################################
    # Load data: 
    
    # Check the extension of atlas file as either dlabel.nii or .npy; note that there may be better ways to do this 
    # Load the atlas label file and perform some checks on dimensions, etc. 
    if inputAtlasLabels_File.endswith('.dlabel.nii'):
        atlasLabels = np.squeeze(nib.load(inputAtlasLabels_File).get_fdata()).astype(int).copy()
        if verbose:
            print(f"Loading atlas file {inputAtlasLabels_File}...")
        
    elif inputAtlasLabels_File.endswith('.npy'):
        atlasLabels = np.load(inputAtlasLabels_File).copy()
        if verbose:
            print(f"Loading atlas file {inputAtlasLabels_File}...")
        
    ################################################################################################
    # Atlas labels and number of vertices included (should be either 64K or 91K): 
    atlasLabels = np.asarray(atlasLabels) # just in case it's a list 
    numAtlasLabelVerts = atlasLabels.shape[0]
    if verbose:
        print(f"Non-masked number of atlas labels = {numAtlasLabelVerts}...")
    
    ################################################################################################
    # Dimensions of atlas labels 
    if atlasLabels.ndim > 1: 
        if verbose:
            print(f"The atlas label file has > 1 dimension (number of dimensions = {atlasLabels.ndim}), please check that it contains only a 1D vector and re-run.")
            
    elif atlasLabels.ndim == 1: 
        if verbose:
            print(f"Atlas label vector has proper number of dimensions: {atlasLabels.ndim}...")
            
        ################################################################################################
        # Drop out values are either 0 or NaN; ignore these 
        if np.isnan(dropOutVals):
            numAtlasLabelVerts_Masked = atlasLabels[~np.isnan(atlasLabels)].shape[0]
        elif dropOutVals==0:
            numAtlasLabelVerts_Masked = atlasLabels[atlasLabels!=0].shape[0]
        if verbose:
            print(f"Masked (i.e., ignoring unlabeled/dropout vertices) number of atlas labels = {numAtlasLabelVerts_Masked}...")
        
        ################################################################################################
        # Check that atlas label vector is not empty now that we've corrected for drop outs 
        if numAtlasLabelVerts==0: 
            if verbose:
                print(f"The atlas label vector is empty, please check and re-run.")
            checkVerts = False
            
        ################################################################################################
        # Check that number of vertices in atlas label vector is one of the standards (set at top of script; can be modified if need be)
        elif not numAtlasLabelVerts in numVertsList:
            if not numAtlasLabelVerts_Masked in numVertsList:
                if verbose:
                    print(f"The atlas label vector has {numAtlasLabelVerts_Masked} labels, expected either {numVertsCort} or {numVertsAll}. Please check and re-run.")
                checkVerts = False
            else:
                checkVerts = True
        
        else:
            checkVerts = True
        
        ################################################################################################
        # If all the checks were passed, then continue on to a few more checks, then parcellation...
        if checkVerts:
            if verbose:
                print(f"Masking atlas...")
                
            ################################################################################################
            # Mask NaNs or 0s; NOTE: could alt. use pandas / other methods to ignore NaNs or 0s
            if np.isnan(dropOutVals):
                atlasLabels_Masked = np.unique(atlasLabels[~np.isnan(atlasLabels)])
                numAtlasLabels = np.max(atlasLabels_Masked)

            if dropOutVals==0:
                atlasLabels_Masked = np.unique(atlasLabels[atlasLabels!=0])
                #numAtlasLabels = np.max(atlasLabels_Masked)-1
                numAtlasLabels = np.max(atlasLabels_Masked)
                
            ################################################################################################
            # Check that atlas labels include all consecutive numbers from 1 through max label
            if numAtlasLabels==atlasLabels_Masked.shape[0]:
                checkMax = True
                
            if numAtlasLabels!=atlasLabels_Masked.shape[0]:
                if verbose:
                    print(f"Number of atlas labels {int(atlasLabels_Masked.shape[0])} not equal to max atlas label {int(numAtlasLabels)}, performing some checks...")
                    
                # Catch if subcortical labels are also included (I think just CABNP, but maybe others too?); 
                # this might be 2 sets of labels non-consecutive with each other, so check that each set has consecutive labels 
                if numAtlasLabelVerts>numVertsCort:
                    if verbose:
                        print(f"This atlas appears to include subcortical labels (given labels for {numAtlasLabelVerts} vertices), performing checks...")
                    if numAtlasLabelVerts==numVertsAll:
                        labels_Cort = atlasLabels[:numVertsCort_Dropped].copy()
                        labels_SubCort = atlasLabels[numVertsCort_Dropped:].copy()
                    else:
                        labels_Cort = atlasLabels[:numVertsCort].copy()
                        labels_SubCort = atlasLabels[numVertsCort:].copy()                            

                    if np.isnan(dropOutVals):
                        labels_Cort_Masked = np.unique(labels_Cort[~np.isnan(labels_Cort)])
                        labels_SubCort_Masked = np.unique(labels_SubCort[~np.isnan(labels_SubCort)])
                        numAtlasLabels_Cort = np.max(labels_Cort_Masked)
                        numAtlasLabels_SubCort = np.max(labels_SubCort_Masked)

                    elif dropOutVals==0:
                        labels_Cort_Masked = np.unique(labels_Cort[labels_Cort!=0])
                        labels_SubCort_Masked = np.unique(labels_SubCort[labels_SubCort!=0])
                        #numAtlasLabels_Cort = np.max(labels_Cort_Masked)-1
                        #numAtlasLabels_SubCort = np.max(labels_SubCort_Masked)-1
                        numAtlasLabels_Cort = np.max(labels_Cort_Masked)
                        numAtlasLabels_SubCort = np.max(labels_SubCort_Masked)

                    if numAtlasLabels_Cort!=labels_Cort_Masked.shape[0] and numAtlasLabels_SubCort!=labels_SubCort_Masked.shape[0]:
                        if verbose:
                            print(f"The atlas labels may not be consecutive, or there is otherwise a mismatch, please check and re-run.")
                        checkMax = False
                    else: 
                        checkMax = True

                elif numAtlasLabels==numVertsCort:
                    if verbose:
                        print(f"The atlas labels may not be consecutive, or there is otherwise a mismatch, please check and re-run.")
                    checkMax = False
                    
            ################################################################################################
            # If the atlas labels passed the extra checks above, continue with parcellation...
            if checkMax:
                if verbose:
                    print(f"Now checking input dense timeseries file...")
                    
                ################################################################################################
                # Now load the dense timeseries and peform some checks 
                if inputTimeseries_File.endswith('.nii'):
                    inputTimeseries = np.squeeze(nib.load(inputTimeseries_File).get_fdata()).astype(int).copy()
                    if verbose:
                        print(f"Loading dense timeseries {inputTimeseries_File}...")

                elif inputTimeseries_File.endswith('.npy'):
                    inputTimeseries = np.load(inputTimeseries_File).copy()
                    if verbose:
                        print(f"Loading dense timeseries {inputTimeseries_File}...")

                inputTimeseries = np.asarray(inputTimeseries)
                colShape = inputTimeseries.shape[1]
                
                ################################################################################################
                # If not vertices x TRs, flip: 
                if colShape==numVertsCort or colShape==numVertsAll:
                    inputTimeseries = inputTimeseries.T.copy()

                numVertsInput = inputTimeseries.shape[0]
                numTRs = inputTimeseries.shape[1]
                if verbose:
                    print(f"Dense timeseries data in shape: {numVertsInput} vertices x {numTRs} TRs...")

                if not numVertsInput in numVertsList:
                    if verbose:
                        print(f"The input dense timeseries has {numVertsInput} vertices (1st row dim), expected {numVertsCort} or {numVertsAll}, please check and re-run.")
                        
                ################################################################################################
                # If the timeseries file has the right shape, perform a few more checks ... 
                else:
                    # Check drop outs  
                    if np.isnan(dropOutVals):
                        dropOutIxs = np.where(np.isnan(atlasLabels))[0].copy()

                    elif dropOutVals==0: 
                        dropOutIxs = np.where(atlasLabels==0)[0].copy()

                    if not np.array_equal(dropOutIxs,droppedVertsCort_HCP):
                        if verbose:
                            print(f"The dropout/unlabeled indices do not match HCP conventions; still running with chosen atlas info, but please check.")
                            
                    ################################################################################################
                    # ALL CHECKS PASSED, PERFORM PARCELLATION: 
                    numRegions = atlasLabels_Masked.shape[0]
                    if verbose:
                        print(f"Number of regions in label list = {numRegions}...")

                    if np.isnan(dropOutVals):
                        atlasLabels_Masked_AllVerts = atlasLabels[~np.isnan(atlasLabels)]
                    if dropOutVals==0:
                        atlasLabels_Masked_AllVerts = atlasLabels[atlasLabels!=0]

                    if verbose:
                        print(f"Combining brainordinates by taking the {parcellationMethod} of vertices with a given region label...")      

                    outputTimeseries = np.zeros((int(numRegions),int(numTRs)))

                    for regionNum in range(int(numRegions)): 
                        regionLabelHere = int(atlasLabels_Masked[regionNum])
                        if numAtlasLabelVerts > numVertsAll:
                            regionIndicesHere = np.where(atlasLabels_Masked_AllVerts==regionLabelHere)[0].copy()
                        else:
                            # Find vertices belonging to a given parcel (region) in this atlas
                            regionIndicesHere = np.where(atlasLabels==regionLabelHere)[0].copy()
                                
                        ################################################################################################
                        # Aggregate vertices in given parcel based on method chosen; taking the mean is most common 
                        if parcellationMethod=='mean':    
                            outputTimeseries[regionNum,:] = np.nanmean(inputTimeseries[regionIndicesHere,:],axis=0).copy()

                        elif parcellationMethod=='min':
                            outputTimeseries[regionNum,:] = np.nanmin(inputTimeseries[regionIndicesHere,:],axis=0).copy()               

                        elif parcellationMethod=='max':
                            outputTimeseries[regionNum,:] = np.nanmax(inputTimeseries[regionIndicesHere,:],axis=0).copy()

                        elif parcellationMethod=='sum':
                            outputTimeseries[regionNum,:] = np.nansum(inputTimeseries[regionIndicesHere,:],axis=0).copy()

                        elif parcellationMethod=='stdev':
                            outputTimeseries[regionNum,:] = np.nanstd(inputTimeseries[regionIndicesHere,:],axis=0).copy()
                            
                    ################################################################################################
                    # Save parcellated timeseries and return
                    if saveOutput:
                        outFileName = subjID_Str + '_' + funcRun_Str + '_Parcellated_Timeseries_' + atlasSave_Str + '.npy'

                        if verbose:
                            print(f"Saving parcellated timeseries to: {outputTimeseries_Path + outFileName}...")
                        np.save(outputTimeseries_Path + outFileName,outputTimeseries)

                    return outputTimeseries