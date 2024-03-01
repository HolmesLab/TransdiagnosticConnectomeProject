# C. Cocuzza, 2023. For TCP data release: HCP preprocessing. 
# Purpose: we'll be doing different variants of ICA-FIX; some files get overwritten.
# This will copy those files into newly named directories while HCP preprocessing is running so they are secure. 
# This script is very specific to the TCP dataset and Yale compute cluster, but could be modified if need be.

import os
import numpy as np
import nibabel as nib

hcpReRunDir = '/gpfs/milgram/project/holmes/PsychConnectome/MRI_Data/fmri_analysis/derivatives/hcp/'

runStrs_Rest = np.asarray(['task-restAP_run-01','task-restAP_run-02','task-restPA_run-01','task-restPA_run-02'])
runStrs_Task = np.asarray(['task-stroopAP_run-01','task-stroopPA_run-01'])
runStrs_Hammer = np.asarray(['task-hammerAP_run-01'])
runStrs_All = np.concatenate((runStrs_Rest,runStrs_Task,runStrs_Hammer))

subjIDs_All_NDA = ['NDAR_INVCW125BLA','NDAR_INVRB271ZFF','NDAR_INVDC524THW','NDAR_INVKH965NN0','NDAR_INVGN082RP7',
                   'NDAR_INVBZ622PEX','NDAR_INVEP476HJ3','NDAR_INVFY729CMQ','NDAR_INVWL810FRT','NDAR_INVED812LMR',
                   'NDAR_INVWT248DFY','NDAR_INVCA042YER','NDAR_INVXV404VJL','NDAR_INVEA806MCW','NDAR_INVZC781XW2',
                   'NDAR_INVJP751NXV','NDAR_INVGG504ENV','NDAR_INVBL062HTE','NDAR_INVXH435XG7','NDAR_INVVC008EZL',
                   'NDAR_INVTR903THR','NDAR_INVAM061NXD','NDAR_INVJT886CG5','NDAR_INVFW143KVU','NDAR_INVGH969TWR',
                   'NDAR_INVWN600UP5','NDAR_INVWB541TEM','NDAR_INVFX289XV7','NDAR_INVAG900RVD','NDAR_INVJX155XLR',
                   'NDAR_INVAG388HJL','NDAR_INVXE784YJ5','NDAR_INVYK619FTF','NDAR_INVXM223BAP','NDAR_INVMZ789RWY',
                   'NDAR_INVZW239ZXZ','NDAR_INVJY908YB9','NDAR_INVZC713KY8','NDAR_INVXZ023ZLG','NDAR_INVPG851GUA',
                   'NDAR_INVUA181LXU','NDAR_INVDM785DVB','NDAR_INVBD216MCC','NDAR_INVGT021UPR','NDAR_INVEC746UWL',
                   'NDAR_INVCX685EVQ','NDAR_INVRW134NUR','NDAR_INVAH529JMM','NDAR_INVAP729WCD','NDAR_INVZF290GFY',
                   'NDAR_INVVK074AWR','NDAR_INVDU085XVZ','NDAR_INVWE937RD6','NDAR_INVYA281VEM','NDAR_INVFW876XT7',
                   'NDAR_INVZY232VM1','NDAR_INVPE364JB5','NDAR_INVZH090MNG','NDAR_INVLZ686XNX','NDAR_INVJR138MBQ',
                   'NDAR_INVJT215VYQ','NDAR_INVJA418ZRD','NDAR_INVVV366BKJ','NDAR_INVBL128ZXR','NDAR_INVBH217XFZ',
                   'NDAR_INVZV968GA8','NDAR_INVDP288XND','NDAR_INVEK685MY0','NDAR_INVUX111AA3','NDAR_INVPF283TAQ',
                   'NDAR_INVFW820XN0','NDAR_INVEK183ZLE','NDAR_INVYZ203GF8','NDAR_INVHZ510TB2','NDAR_INVVF051GV0',
                   'NDAR_INVWG867JHJ','NDAR_INVNE865PBN','NDAR_INVZT152JCX','NDAR_INVLL260KC0','NDAR_INVGT486MAN',
                   'NDAR_INVAZ218MB7','NDAR_INVVZ816AVQ','NDAR_INVCW577CWF','NDAR_INVWM327ZZN','NDAR_INVRR054KAM',
                   'NDAR_INVFU389BX1','NDAR_INVXR625UBQ','NDAR_INVKZ413VTU','NDAR_INVEG178LHD','NDAR_INVBY805EE5',
                   'NDAR_INVMH676UAR','NDAR_INVZR981ALE','NDAR_INVCX643TCM','NDAR_INVZB896FPZ','NDAR_INVWZ534JVA',
                   'NDAR_INVDT499KZL','NDAR_INVVD461TM8','NDAR_INVLK689LJ2','NDAR_INVZU840GFR','NDAR_INVWD109LR7',
                   'NDAR_INVUT195DEQ','NDAR_INVAG023WG3','NDAR_INVTC494BH2','NDAR_INVEN039PVQ','NDAR_INVPZ987BMX',
                   'NDAR_INVLK466LC2','NDAR_INVWF881BPQ','NDAR_INVZW252GAV','NDAR_INVZF221XAB','NDAR_INVVH854UEQ',
                   'NDAR_INVTT359WEC','NDAR_INVAL101MH2','NDAR_INVDN485GPF','NDAR_INVPF766MJ2','NDAR_INVBH315KUM',
                   'NDAR_INVKD900ED7','NDAR_INVPU175NP8','NDAR_INVKZ112BTB','NDAR_INVDK220VPQ','NDAR_INVLC145NV2',
                   'NDAR_INVYE059KWM','NDAR_INVPD575FK1','NDAR_INVPE293RXE','NDAR_INVCL131GYQ','NDAR_INVGU013UHX',
                   'NDAR_INVZK672XPE','NDAR_INVPJ213YAX','NDAR_INVFH503ZWA','NDAR_INVMV972LBE','NDAR_INVTT812VKB',
                   'NDAR_INVWA310HH4','NDAR_INVMZ631XR9','NDAR_INVFT463JPQ','NDAR_INVTA573RU2','NDAR_INVHV402VH9',
                   'NDAR_INVJP343BJ6','NDAR_INVHB925HEK','NDAR_INVBB020WYD','NDAR_INVYT858CBN','NDAR_INVDW733XXB',
                   'NDAR_INVPF308MTF','NDAR_INVEV975LY3','NDAR_INVRZ105MC1','NDAR_INVKV870NBK','NDAR_INVGB371PPV',
                   'NDAR_INVBN249GWM','NDAR_INVXJ707NAE','NDAR_INVWD467AR0','NDAR_INVAN576KX1','NDAR_INVLT949NAG',
                   'NDAR_INVCV410NUH','NDAR_INVTY904UNB','NDAR_INVLK739LPV','NDAR_INVUV598MXY','NDAR_INVTF281GWR',
                   'NDAR_INVRF914JT6','NDAR_INVGK662YZW','NDAR_INVXD089VAD','NDAR_INVHY331CLY','NDAR_INVGW978HUP',
                   'NDAR_INVHG032NYJ','NDAR_INVGR746CR0','NDAR_INVDV232BEQ','NDAR_INVXP963GZ5','NDAR_INVGB107TDU',
                   'NDAR_INVTR059ATR','NDAR_INVWJ708RM0','NDAR_INVRC807HPA','NDAR_INVLD269XMU','NDAR_INVKX727WL8',
                   'NDAR_INVUY799LKJ','NDAR_INVZX212UNE','NDAR_INVWM533NJC','NDAR_INVUR466KN5','NDAR_INVPB396GT2',
                   'NDAR_INVKH279ZDZ','NDAR_INVJK969JZ8','NDAR_INVCK288RP2','NDAR_INVWU297KRB','NDAR_INVVP179WTP',
                   'NDAR_INVUZ656BRT','NDAR_INVJV338PGX','NDAR_INVRF868XAA','NDAR_INVYR744ZAU','NDAR_INVUX642KUY',
                   'NDAR_INVWD338PY2','NDAR_INVDD155BRR','NDAR_INVMJ687EBC','NDAR_INVXA261ZAL','NDAR_INVEY681MZ7',
                   'NDAR_INVHW100CDA','NDAR_INVDG233EBR','NDAR_INVJT253NWQ','NDAR_INVKH356XFP','NDAR_INVFE128JJV',
                   'NDAR_INVGR029VCQ','NDAR_INVUY536RET','NDAR_INVPG675JPX','NDAR_INVGM287EF8','NDAR_INVXZ387TC1',
                   'NDAR_INVJC140HGJ','NDAR_INVCM621YRY','NDAR_INVRX371YHK','NDAR_INVAT097DFG','NDAR_INVBL733HBP',
                   'NDAR_INVHR360FAK','NDAR_INVAR463UNP','NDAR_INVHA329EL1','NDAR_INVKZ712GTY','NDAR_INVEF266GBV',
                   'NDAR_INVWR872ZDB','NDAR_INVZU586UPF','NDAR_INVZY305TZ5','NDAR_INVCE244AGN','NDAR_INVZB382MHL',
                   'NDAR_INVAK834VNU','NDAR_INVVT280VDN','NDAR_INVGZ602BF8','NDAR_INVTH522AEV','NDAR_INVGN063ZRV',
                   'NDAR_INVZF605GZ8','NDAR_INVLJ841ZFK','NDAR_INVKF855DZG','NDAR_INVVU614ZKP','NDAR_INVEJ537VGZ',
                   'NDAR_INVFJ172LJ5','NDAR_INVHT721HFR','NDAR_INVBU789GV0','NDAR_INVTV991YAD','NDAR_INVWJ892FLH',
                   'NDAR_INVRB157VE8','NDAR_INVND653BE6','NDAR_INVDZ608PPY','NDAR_INVAG339WHH','NDAR_INVKW897YWP',
                   'NDAR_INVCP169JDZ','NDAR_INVBM990HJT','NDAR_INVPT961JTN','NDAR_INVZL449UYG','NDAR_INVTU813PDR',
                   'NDAR_INVZF426RL4','NDAR_INVKC627BAV','NDAR_INVEY033HCZ','NDAR_INVKP945BWF','NDAR_INVNB949AXM',
                   'NDAR_INVBE389YGF']

def file_cleanup(subjIx):
    subjID = subjIDs_All_NDA[subjIx]
    
    # RSYNC 
    print(f"Copying files from ./MNINonLinear to ./MNINonLinear_AfterSingleRunICAFIX for: {subjID}...\n")

    # MNINonLinear main directory: 
    dirHere_MNINonLinear = hcpReRunDir + subjID + '/MNINonLinear'
    dirHere_MNINonLinear_New = dirHere_MNINonLinear + '_AfterSingleRunICAFIX'

    if not os.path.exists(dirHere_MNINonLinear_New):
        bashCommand_MKDIR = 'mkdir ' + dirHere_MNINonLinear_New
        os.system(bashCommand_MKDIR)

    # First rsync over everything in MNINonLinear:
    bashCommand_RSYNC_MNI = 'rsync --partial --progress -av ' + dirHere_MNINonLinear + '/ ' +  dirHere_MNINonLinear_New
    os.system(bashCommand_RSYNC_MNI)

    # Then rsync T1w directory (does not need to be tidied too much b/c relatively small) 
    dirHere_T1w = hcpReRunDir + subjID + '/T1w'
    dirHere_T1w_New = dirHere_T1w + '_AfterSingleRunICAFIX'

    if not os.path.exists(dirHere_T1w_New):
        bashCommand_MKDIR = 'mkdir ' + dirHere_T1w_New
        os.system(bashCommand_MKDIR)

    bashCommand_RSYNC_T1 = 'rsync --partial --progress -av ' + dirHere_T1w + '/ ' +  dirHere_T1w_New
    os.system(bashCommand_RSYNC_T1)
    
    # TRIM
    print(f"Trimming files from ./MNINonLinear to ./MNINonLinear_AfterSingleRunICAFIX for: {subjID}...\n")

    filesNotChanged = ['aparc.a2009s+aseg.nii.gz','aparc+aseg.nii.gz','BiasField.nii.gz','brainmask_fs.2.dil2x.nii.gz','brainmask_fs.2.nii.gz',
                       'brainmask_fs.nii.gz',subjID+'.aparc.164k_fs_LR.dlabel.nii',subjID+'.aparc.a2009s.164k_fs_LR.dlabel.nii',
                       subjID+'.ArealDistortion_FS.164k_fs_LR.dscalar.nii',subjID+'.ArealDistortion_MSMSulc.164k_fs_LR.dscalar.nii',
                       subjID+'.corrThickness.164k_fs_LR.dscalar.nii',subjID+'.curvature.164k_fs_LR.dscalar.nii',
                       subjID+'.EdgeDistortion_FS.164k_fs_LR.dscalar.nii', subjID+'.EdgeDistortion_MSMSulc.164k_fs_LR.dscalar.nii',
                       subjID+'.L.aparc.164k_fs_LR.label.gii',subjID+'.L.aparc.a2009s.164k_fs_LR.label.gii',
                       subjID+'.L.ArealDistortion_FS.164k_fs_LR.shape.gii',subjID+'.L.ArealDistortion_MSMSulc.164k_fs_LR.shape.gii',
                       subjID+'.L.atlasroi.164k_fs_LR.shape.gii',subjID+'.L.corrThickness.164k_fs_LR.shape.gii',subjID+'.L.curvature.164k_fs_LR.shape.gii',
                       subjID+'.L.EdgeDistortion_FS.164k_fs_LR.shape.gii',subjID+'.L.EdgeDistortion_MSMSulc.164k_fs_LR.shape.gii',
                       subjID+'.L.MyelinMap.164k_fs_LR.func.gii',subjID+'.L.MyelinMap_BC.164k_fs_LR.func.gii',subjID+'.L.RefMyelinMap.164k_fs_LR.func.gii',
                       subjID+'.L.refsulc.164k_fs_LR.shape.gii',subjID+'.L.SmoothedMyelinMap.164k_fs_LR.func.gii',
                       subjID+'.L.SmoothedMyelinMap_BC.164k_fs_LR.func.gii',subjID+'.L.StrainJ_FS.164k_fs_LR.shape.gii',
                       subjID+'.L.StrainJ_MSMSulc.164k_fs_LR.shape.gii',subjID+'.L.StrainR_FS.164k_fs_LR.shape.gii',
                       subjID+'.L.StrainR_MSMSulc.164k_fs_LR.shape.gii',subjID+'.L.sulc.164k_fs_LR.shape.gii',subjID+'.L.thickness.164k_fs_LR.shape.gii',
                       subjID+'.MyelinMap.164k_fs_LR.dscalar.nii',subjID+'.MyelinMap_BC.164k_fs_LR.dscalar.nii',
                       subjID+'.R.aparc.164k_fs_LR.label.gii',subjID+'.R.aparc.a2009s.164k_fs_LR.label.gii',
                       subjID+'.R.ArealDistortion_FS.164k_fs_LR.shape.gii',subjID+'.R.ArealDistortion_MSMSulc.164k_fs_LR.shape.gii',
                       subjID+'.R.atlasroi.164k_fs_LR.shape.gii',subjID+'.R.corrThickness.164k_fs_LR.shape.gii',
                       subjID+'.R.curvature.164k_fs_LR.shape.gii',subjID+'.R.EdgeDistortion_FS.164k_fs_LR.shape.gii',
                       subjID+'.R.EdgeDistortion_MSMSulc.164k_fs_LR.shape.gii',subjID+'.R.MyelinMap.164k_fs_LR.func.gii',
                       subjID+'.R.MyelinMap_BC.164k_fs_LR.func.gii',subjID+'.R.RefMyelinMap.164k_fs_LR.func.gii',
                       subjID+'.R.refsulc.164k_fs_LR.shape.gii',subjID+'.R.SmoothedMyelinMap.164k_fs_LR.func.gii',
                       subjID+'.R.SmoothedMyelinMap_BC.164k_fs_LR.func.gii',subjID+'.R.StrainJ_FS.164k_fs_LR.shape.gii',
                       subjID+'.R.StrainJ_MSMSulc.164k_fs_LR.shape.gii',subjID+'.R.StrainR_FS.164k_fs_LR.shape.gii',
                       subjID+'.R.StrainR_MSMSulc.164k_fs_LR.shape.gii',subjID+'.R.sulc.164k_fs_LR.shape.gii',
                       subjID+'.R.thickness.164k_fs_LR.shape.gii',subjID+'.SmoothedMyelinMap.164k_fs_LR.dscalar.nii',
                       subjID+'.SmoothedMyelinMap_BC.164k_fs_LR.dscalar.nii',subjID+'.StrainJ_FS.164k_fs_LR.dscalar.nii',
                       subjID+'.StrainJ_MSMSulc.164k_fs_LR.dscalar.nii',subjID+'.StrainR_FS.164k_fs_LR.dscalar.nii',
                       subjID+'.StrainR_MSMSulc.164k_fs_LR.dscalar.nii',subjID+'.sulc.164k_fs_LR.dscalar.nii',
                       subjID+'.thickness.164k_fs_LR.dscalar.nii','ribbon.nii.gz','T1w.nii.gz','T1w_restore.2.nii.gz','T1w_restore_brain.nii.gz',
                       'T1w_restore.nii.gz','T2w.nii.gz','T2w_restore.2.nii.gz','T2w_restore_brain.nii.gz','T2w_restore.nii.gz','wmparc.nii.gz']

    # MNINonLinear main directory: 
    dirHere_MNINonLinear = hcpReRunDir + subjID + '/MNINonLinear'
    dirHere_MNINonLinear_New = dirHere_MNINonLinear + '_AfterSingleRunICAFIX'

    if not os.path.exists(dirHere_MNINonLinear_New):
        print(f"New MNINonLinear directory does not exist for {subjID}, please re-run above cell first.")

    # Remove files that do not get overwritten in main /MNINonLinar directory:
    for fileIx in range(len(filesNotChanged)):
        fullPathHere = dirHere_MNINonLinear_New + '/' + filesNotChanged[fileIx]
        if not os.path.exists(fullPathHere):
            print(f"The following file does not exist for {subjID}: {filesNotChanged[fileIx]}, please check.")
        elif os.path.exists(fullPathHere):
            bashCommand_RM_MNI = 'rm ' + fullPathHere
            os.system(bashCommand_RM_MNI)

    # Then remove files do not get overwritten in various ./Results/<func>/ directories:
    for funcRun in range(runStrs_All.shape[0]):
        thisFuncStr = runStrs_All[funcRun] + '_bold'
        dirHere_MNINonLinear_New_RESULTS_FUNC = dirHere_MNINonLinear_New + '/Results/' + thisFuncStr + '/'

        filesNotChanged = ['brainmask_fs.2.nii.gz','Movement_AbsoluteRMS_mean.txt','Movement_AbsoluteRMS.txt','Movement_Regressors_dt.txt',
                           'Movement_Regressors.txt','Movement_RelativeRMS_mean.txt','Movement_RelativeRMS.txt',
                           thisFuncStr+'_Atlas.dtseries.nii',thisFuncStr+'_Atlas_hp2000_clean.dtseries.nii',thisFuncStr+'_Atlas_hp2000_clean_vn.dscalar.nii',
                           thisFuncStr+'_Atlas_hp2000_clean_vn.dtseries.nii',thisFuncStr+'_Atlas_hp2000.dtseries.nii',thisFuncStr+'_Atlas_mean.dscalar.nii',
                           thisFuncStr+'_Atlas_MSMAll_hp2000_clean.dtseries.nii',thisFuncStr+'_Atlas_MSMAll_hp2000_clean_vn.dscalar.nii',
                           thisFuncStr+'_Atlas_nonzero.stats.txt',thisFuncStr+'_dropouts.nii.gz',thisFuncStr+'_finalmask.nii.gz',thisFuncStr+'_finalmask.stats.txt',
                           thisFuncStr+'_fovmask.nii.gz',thisFuncStr+'_hp2000_clean.nii.gz',thisFuncStr+'_hp2000_clean_vn.nii.gz',thisFuncStr+'_hp2000.nii.gz',
                           thisFuncStr+'_Jacobian.nii.gz',thisFuncStr+'.L.native.func.gii',thisFuncStr+'.nii.gz',thisFuncStr+'_PhaseOne_gdc_dc.nii.gz',
                           thisFuncStr+'_PhaseTwo_gdc_dc.nii.gz',thisFuncStr+'_pseudo_transmit_field.nii.gz',thisFuncStr+'_pseudo_transmit_raw.nii.gz',
                           thisFuncStr+'.R.native.func.gii',thisFuncStr+'_SBRef.nii.gz',thisFuncStr+'_SBRef_nomask.nii.gz',thisFuncStr+'_sebased_bias.nii.gz',
                           thisFuncStr+'_sebased_bias.nii.gz_dilated.nii.gz',thisFuncStr+'_sebased_reference.nii.gz']

        for fileIx in range(len(filesNotChanged)):
            fullPathHere = dirHere_MNINonLinear_New_RESULTS_FUNC + filesNotChanged[fileIx]
            if not os.path.exists(fullPathHere):
                print(f"The following file does not exist for {subjID}: {filesNotChanged[fileIx]}, please check.")
            elif os.path.exists(fullPathHere):
                bashCommand_RM_MNI_RESULTS_FUNC = 'rm ' + fullPathHere
                os.system(bashCommand_RM_MNI_RESULTS_FUNC)