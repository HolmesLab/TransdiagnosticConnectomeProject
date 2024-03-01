    export filesToRenameAndSave=( ${runName}_hp2000.ica/filtered_func_data.ica/stats/stats.log 
                                  ${runName}_hp2000.ica/.fix_2b_predict.log 
                                  ${runName}_hp2000.ica/.fix.log
                                  ${runName}_hp2000.ica/filtered_func_data.ica/eigenvalues_percent
                                  ${runName}_hp2000.ica/.fix
                                  ${runName}_hp2000.ica/fix/.version
                                  ${runName}_hp2000.ica/mc/prefiltered_func_data_mcf.par
                                  ${runName}_hp2000_clean.nii.gz
                                  ${runName}_hp2000.ica/mc/prefiltered_func_data_mcf_conf_hp_clean.nii.gz
                                  ${runName}_hp2000.ica/mc/prefiltered_func_data_mcf_conf.nii.gz
                                  ${runName}_Atlas_hp2000_clean.dtseries.nii
    )

    export filesToRenameAndSave_AfterMR=( Movement_Regressors_demean.txt
                                          Movement_Regressors_hp2000_clean.txt
                                          ${runName}_Atlas_hp2000_clean.README.txt
                                          ${runName}_Atlas_hp2000_vn.dscalar.nii
                                          ${runName}_dims.txt
                                          ${runName}_hp2000_vn.nii.gz
                                          ${runName}_mean.nii.gz
    )

    export filesToRenameAndSave_AfterSR=(${runName}_Atlas_hp2000.dtseries.nii
                                         ${runName}_hp2000.nii.gz
    )
    
    for fileName in "${filesToRenameAndSave[@]}" ; do
        cp ${datadir}${subj}/MNINonLinear/Results/${runName}/${fileName} ${datadir}${subj}/MNINonLinear/Results/${runName}/${fileName}${addStr}
    done 

    if [ "$fixType" == "SR" ]; then
        for fileName in "${filesToRenameAndSave_AfterSR[@]}" ; do
            cp ${datadir}${subj}/MNINonLinear/Results/${runName}/${fileName} ${datadir}${subj}/MNINonLinear/Results/${runName}/${fileName}${addStr}
        done 
    elif [ "$fixType" == "MR" ]; then
        for fileName in "${filesToRenameAndSave_AfterMR[@]}" ; do
            cp ${datadir}${subj}/MNINonLinear/Results/${runName}/${fileName} ${datadir}${subj}/MNINonLinear/Results/${runName}/${fileName}${addStr}
        done 
    fi 
done