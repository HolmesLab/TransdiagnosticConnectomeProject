% Carrisa V. Cocuzza, PhD. 2023 Yale University. 2024 Rutgers University.

% Adapting code from Linden Parkes, PhD. and Sidhant Chopra, PhD.

% This script was used for the Transdiagnostic Connectome Project (TCP).
% Data release manuscript forthcoming in 2024: Chopra*, Cocuzza*, Lawhead
% et al. "The Transdiagnostic Connectome Project Dataset: a richly 
% phenotyped open dataset for advancing the study of brain-behavior 
% relationships in psychiatry"

% Goals of this script:

% 1) Estimate framewise displacement (FD) for every participant and 
% functional run in the TCP dataset. Also look at participants grouped by 
% collection site (Yale and McLean).

% 2) Use FD threshold that was validated in the literature to identify 
% poorly-controlled motion artificats. NOTE: input data here -- motion 
% estimates -- are based on running HCP processing pipelines v4.7. See
% here: https://github.com/Washington-University/HCPpipelines
% NOTE: This can be used as an exclusion criteria depending on the research
% question, etc. 

% Other notes and refernces: 

% This script uses the Jenkinson method from: Parkes, L., Fulcher, B., 
% Yücel, M., & Fornito, A. (2018). An evaluation of the efficacy, 
% reliability, and sensitivity of motion correction strategies for 
% resting-state functional MRI. NeuroImage, 171, 415–436. 
% https://doi.org/10.1016/j.neuroimage.2017.12.073

% NOTE: bramila_framewiseDisplacement.m is included in GitHub as well. This
% is a popular method by Power et al. 2014. We compared both approaches and
% found similar results; the method used below was found to be more robust
% but outside researchers can feel free to compare and contrast for their
% own research questions. 

% NOTE: if using any of these methods in your own research, please cite
% original methods paper(s) and make sure any shared code has original 
% authors credited.

% Outside scripts called (created by L. Parkes): 
% GetFDJenk_multiband.m
% GetTMat.m 
% GetSpikeRegressors.m

%clear all; 
%clc;

%% PATHS & VARBIABLES: machine- and project-specific 
baseDir = '/Users/carrisacocuzza/temp_files_during_maintenance/hcp/movement_regressors_TCP/';
hcpDir = '/MNINonLinear/Results/';
addpath /Users/carrisacocuzza/Downloads/;
addpath /Users/carrisacocuzza/Downloads/lindo_motionexclude/;

% The below is a folder containing reference vectors of strings (subject IDs) 
% for which subjects have each functional run, per collection site. This
% will be uploaded to GitHub (and info is also available as part of dataset
% release), but likely need to change path to your machine's info. 
subjID_Ref_Dir = '/Users/carrisacocuzza/temp_files_during_maintenance/hcp/subj_ID_Indexing_Reference_Vectors_Per_Run/';

% Functional run info
runStrs_All = ["task-restAP_run-01_bold";...
    "task-restAP_run-02_bold";...
    "task-restPA_run-01_bold";...
    "task-restPA_run-02_bold";...
    "task-stroopAP_run-01_bold";...
    "task-stroopPA_run-01_bold";...
    "task-hammerAP_run-01_bold"];
trsAll = [488;488;488;488;510;510;493];

numRuns = size(runStrs_All,1);
disp(append('Number of functional runs: ',string(numRuns)));

% Participant info 
subjIDs_All = ["NDAR_INVCW125BLA","NDAR_INVRB271ZFF","NDAR_INVDC524THW","NDAR_INVKH965NN0",...
    "NDAR_INVGN082RP7","NDAR_INVBZ622PEX","NDAR_INVEP476HJ3","NDAR_INVFY729CMQ",...
    "NDAR_INVWL810FRT","NDAR_INVED812LMR","NDAR_INVWT248DFY","NDAR_INVCA042YER",...
    "NDAR_INVXV404VJL","NDAR_INVEA806MCW","NDAR_INVZC781XW2","NDAR_INVJP751NXV",...
    "NDAR_INVGG504ENV","NDAR_INVBL062HTE","NDAR_INVXH435XG7","NDAR_INVVC008EZL",...
    "NDAR_INVTR903THR","NDAR_INVAM061NXD","NDAR_INVJT886CG5","NDAR_INVFW143KVU",...
    "NDAR_INVGH969TWR","NDAR_INVWN600UP5","NDAR_INVWB541TEM","NDAR_INVFX289XV7",...
    "NDAR_INVAG900RVD","NDAR_INVJX155XLR","NDAR_INVAG388HJL","NDAR_INVXE784YJ5",...
    "NDAR_INVYK619FTF","NDAR_INVXM223BAP","NDAR_INVMZ789RWY","NDAR_INVZW239ZXZ",...
    "NDAR_INVJY908YB9","NDAR_INVZC713KY8","NDAR_INVXZ023ZLG","NDAR_INVPG851GUA",...
    "NDAR_INVUA181LXU","NDAR_INVDM785DVB","NDAR_INVBD216MCC","NDAR_INVGT021UPR",...
    "NDAR_INVEC746UWL","NDAR_INVCX685EVQ","NDAR_INVRW134NUR","NDAR_INVAH529JMM",...
    "NDAR_INVAP729WCD","NDAR_INVZF290GFY","NDAR_INVVK074AWR","NDAR_INVDU085XVZ",...
    "NDAR_INVWE937RD6","NDAR_INVYA281VEM","NDAR_INVFW876XT7","NDAR_INVZY232VM1",...
    "NDAR_INVPE364JB5","NDAR_INVZH090MNG","NDAR_INVLZ686XNX","NDAR_INVJR138MBQ",...
    "NDAR_INVJT215VYQ","NDAR_INVJA418ZRD","NDAR_INVVV366BKJ","NDAR_INVBL128ZXR",...
    "NDAR_INVBH217XFZ","NDAR_INVZV968GA8","NDAR_INVDP288XND","NDAR_INVEK685MY0",...
    "NDAR_INVUX111AA3","NDAR_INVPF283TAQ","NDAR_INVFW820XN0","NDAR_INVEK183ZLE",...
    "NDAR_INVYZ203GF8","NDAR_INVHZ510TB2","NDAR_INVVF051GV0","NDAR_INVWG867JHJ",...
    "NDAR_INVNE865PBN","NDAR_INVZT152JCX","NDAR_INVLL260KC0","NDAR_INVGT486MAN",...
    "NDAR_INVAZ218MB7","NDAR_INVVZ816AVQ","NDAR_INVCW577CWF","NDAR_INVWM327ZZN",...
    "NDAR_INVRR054KAM","NDAR_INVFU389BX1","NDAR_INVXR625UBQ","NDAR_INVKZ413VTU",...
    "NDAR_INVEG178LHD","NDAR_INVBY805EE5","NDAR_INVMH676UAR","NDAR_INVZR981ALE",...
    "NDAR_INVCX643TCM","NDAR_INVZB896FPZ","NDAR_INVWZ534JVA","NDAR_INVDT499KZL",...
    "NDAR_INVVD461TM8","NDAR_INVLK689LJ2","NDAR_INVZU840GFR","NDAR_INVWD109LR7",...
    "NDAR_INVUT195DEQ","NDAR_INVAG023WG3","NDAR_INVTC494BH2","NDAR_INVEN039PVQ",...
    "NDAR_INVPZ987BMX","NDAR_INVLK466LC2","NDAR_INVWF881BPQ","NDAR_INVZW252GAV",...
    "NDAR_INVZF221XAB","NDAR_INVVH854UEQ","NDAR_INVTT359WEC","NDAR_INVAL101MH2",...
    "NDAR_INVDN485GPF","NDAR_INVPF766MJ2","NDAR_INVBH315KUM","NDAR_INVKD900ED7",...
    "NDAR_INVPU175NP8","NDAR_INVKZ112BTB","NDAR_INVDK220VPQ","NDAR_INVLC145NV2",...
    "NDAR_INVYE059KWM","NDAR_INVPD575FK1","NDAR_INVPE293RXE","NDAR_INVCL131GYQ",...
    "NDAR_INVGU013UHX","NDAR_INVZK672XPE","NDAR_INVPJ213YAX","NDAR_INVFH503ZWA",...
    "NDAR_INVMV972LBE","NDAR_INVTT812VKB","NDAR_INVWA310HH4","NDAR_INVMZ631XR9",...
    "NDAR_INVFT463JPQ","NDAR_INVTA573RU2","NDAR_INVHV402VH9","NDAR_INVJP343BJ6",...
    "NDAR_INVHB925HEK","NDAR_INVYT858CBN","NDAR_INVDW733XXB",...
    "NDAR_INVPF308MTF","NDAR_INVEV975LY3","NDAR_INVRZ105MC1","NDAR_INVKV870NBK",...
    "NDAR_INVGB371PPV","NDAR_INVBN249GWM","NDAR_INVXJ707NAE","NDAR_INVWD467AR0",...
    "NDAR_INVAN576KX1","NDAR_INVLT949NAG","NDAR_INVCV410NUH",...
    "NDAR_INVLK739LPV","NDAR_INVUV598MXY","NDAR_INVTF281GWR","NDAR_INVRF914JT6",...
    "NDAR_INVGK662YZW","NDAR_INVXD089VAD","NDAR_INVHY331CLY",...
    "NDAR_INVHG032NYJ","NDAR_INVGR746CR0","NDAR_INVDV232BEQ","NDAR_INVXP963GZ5",...
    "NDAR_INVGB107TDU","NDAR_INVTR059ATR","NDAR_INVWJ708RM0","NDAR_INVRC807HPA",...
    "NDAR_INVLD269XMU","NDAR_INVKX727WL8","NDAR_INVUY799LKJ","NDAR_INVZX212UNE",...
    "NDAR_INVWM533NJC","NDAR_INVUR466KN5","NDAR_INVPB396GT2","NDAR_INVKH279ZDZ",...
    "NDAR_INVJK969JZ8","NDAR_INVCK288RP2","NDAR_INVWU297KRB","NDAR_INVVP179WTP",...
    "NDAR_INVUZ656BRT","NDAR_INVJV338PGX","NDAR_INVRF868XAA","NDAR_INVYR744ZAU",...
    "NDAR_INVUX642KUY","NDAR_INVWD338PY2","NDAR_INVDD155BRR","NDAR_INVMJ687EBC",...
    "NDAR_INVXA261ZAL","NDAR_INVEY681MZ7","NDAR_INVHW100CDA","NDAR_INVDG233EBR",...
    "NDAR_INVJT253NWQ","NDAR_INVKH356XFP","NDAR_INVFE128JJV","NDAR_INVGR029VCQ",...
    "NDAR_INVUY536RET","NDAR_INVPG675JPX","NDAR_INVGM287EF8","NDAR_INVXZ387TC1",...
    "NDAR_INVJC140HGJ","NDAR_INVCM621YRY","NDAR_INVRX371YHK","NDAR_INVAT097DFG",...
    "NDAR_INVBL733HBP","NDAR_INVAR463UNP","NDAR_INVHA329EL1",...
    "NDAR_INVKZ712GTY","NDAR_INVEF266GBV","NDAR_INVWR872ZDB","NDAR_INVZU586UPF",...
    "NDAR_INVZY305TZ5","NDAR_INVCE244AGN","NDAR_INVZB382MHL","NDAR_INVAK834VNU",...
    "NDAR_INVVT280VDN","NDAR_INVGZ602BF8","NDAR_INVTH522AEV","NDAR_INVGN063ZRV",...
    "NDAR_INVZF605GZ8","NDAR_INVKF855DZG","NDAR_INVVU614ZKP",...
    "NDAR_INVEJ537VGZ","NDAR_INVFJ172LJ5","NDAR_INVHT721HFR","NDAR_INVBU789GV0",...
    "NDAR_INVTV991YAD","NDAR_INVWJ892FLH","NDAR_INVRB157VE8","NDAR_INVND653BE6",...
    "NDAR_INVDZ608PPY","NDAR_INVAG339WHH","NDAR_INVKW897YWP","NDAR_INVCP169JDZ",...
    "NDAR_INVBM990HJT","NDAR_INVPT961JTN","NDAR_INVZL449UYG","NDAR_INVTU813PDR",...
    "NDAR_INVZF426RL4","NDAR_INVKC627BAV","NDAR_INVEY033HCZ","NDAR_INVKP945BWF",...
    "NDAR_INVNB949AXM","NDAR_INVBE389YGF"];

numSubjs = size(subjIDs_All,2);
disp(append('Number of subjects: ', string(numSubjs)));

% Whether or not to print out intermediate results / logs:
verbose = 0;

% Other variables 
TR = 0.8; % specific to TCP dataset 
k = 3; % see GetFDJenk_multiband.m for guidance
stopband = [0.2 0.5]; % see GetFDJenk_multiband.m for guidance
head = 80; % see GetFDJenk_multiband.m for guidance

% Adapting Linden_motion_exclude.m
fdThr = 0.25;
thresh = 4;

%% FD ESTIMATION: All participants 

% Compute FD and save out some helper/QA variables: 
fdJenk_All = cell(numSubjs,numRuns);
fdJenk_Mean_All = zeros(numSubjs,numRuns);
trMisMatch_Log = zeros(numSubjs,numRuns);
missingFile_Log = zeros(numSubjs,numRuns);
for runIxHere = 1:numRuns
    trsHere = trsAll(runIxHere);
    runStrHere = runStrs_All(runIxHere);
    for subjNum = 1:numSubjs
        subjID = subjIDs_All(subjNum);
        if verbose
            disp(append('PARTICIPANT ',string(subjNum), ' (',subjID,')...'));
        end
        dirHere = append(baseDir,subjID,hcpDir,'/',runStrs_All(runIxHere),'/');
        cd(dirHere);
        if isfile('Movement_Regressors.txt')
            dataRegs = importdata('Movement_Regressors.txt'); % regressors     
            dataRegs_DT = importdata('Movement_Regressors_dt.txt'); % regressors demeaned and detrended
            
            dataRegs_Struct = struct;
            dataRegs_Struct.motionparam = dataRegs(:,1:6);             
            dataRegs_DT_Struct = struct;
            dataRegs_DT_Struct.motionparam = dataRegs_DT(:,1:6); 

            %if size(dataRegs_Struct.motionparam,1)~=trsHere
            if size(dataRegs_Struct.motionparam,1)<60
                fdJenk_Mean_All(subjNum,runIxHere) = NaN;
                trMisMatch_Log(subjNum,runIxHere) = size(dataRegs_Struct.motionparam,1);           
            else
                mov_Temp = dataRegs_DT_Struct.motionparam;
                %mov_Temp = dataRegs_Struct.motionparam;
                %mov = zeros(trsHere,6);
                mov = zeros(size(mov_Temp,1),6);
                mov(:,1:3) = mov_Temp(:,4:6);
                mov(:,4:6) = mov_Temp(:,1:3);
                mov = deg2rad(mov);
                fdJenk = GetFDJenk_multiband(mov, TR, k, stopband, head);
                fdJenk_Mean = mean(fdJenk);
                fdJenk_Mean_All(subjNum,runIxHere) = fdJenk_Mean;
                fdJenk_All{subjNum,runIxHere} = fdJenk;
                if verbose
                    disp(append('JENKINSON: mean framewise displacement (',runStrHere,') = ',string(round(fdJenk_Mean,2)),' mm'));
                    disp(' ');
                end
            end
        else
            fdJenk_Mean_All(subjNum,runIxHere) = NaN;
            missingFile_Log(subjNum,runIxHere) = 1;
        end
    end
    clc;
end

% Print summary of core results
% NOTE: thresholds for printing have a +0.01 to see data on cusp
for runIxHere = 1:numRuns
    runStrHere = runStrs_All(runIxHere);
    nHere = numSubjs - sum(missingFile_Log(:,runIxHere));
    nShortTRsHere = size(find(trMisMatch_Log(:,runIxHere)~=0),1);
    subjIDsShortTRsHere = find(trMisMatch_Log(:,runIxHere)~=0);
    disp(' ');
    disp(append('The total number of participants with data for ', runStrHere,' = ',string(nHere)));
    disp(append('N=',string(nHere),' have the following mean FD values for ',runStrHere,' per Jenkinson: '));
    disp(append(string((sum(fdJenk_Mean_All(:,runIxHere)<=0.51)/nHere) * 100),'% have mean FD <= 0.5'));
    disp(append(string((sum(fdJenk_Mean_All(:,runIxHere)<=0.26)/nHere) * 100),'% have mean FD <= 0.25'));
    if nShortTRsHere>=1
        disp(append('*** NOTE: n=',string(nShortTRsHere),' were removed for having timeseries with < 60 TRs.'));
    end
end

% Adapting Linden_motion_exclude.m: 
exclude = zeros(numSubjs,numRuns);
mean_exclude = zeros(numSubjs,numRuns);
sum_exclude = zeros(numSubjs,numRuns);
spike_exclude = zeros(numSubjs,numRuns);
%exclude_Total = zeros(numSubjs,numRuns);
censoring_exclude = zeros(numSubjs,numRuns);
for runIxHere = 1:numRuns
    numVols = trsAll(runIxHere);
    for subjNum = 1:numSubjs
        fdJenk_Mean_Here = fdJenk_Mean_All(subjNum,runIxHere);
        fdJenk_Trace_Here = fdJenk_All{subjNum,runIxHere};

        % ------------------------------------------------------------------------------
        % Initial, gross movement exclusion
        % ------------------------------------------------------------------------------
	    % 1) Exclude on mean rms displacement
	    % Calculate whether subject has suprathreshold mean movement
	    % If the mean of displacement is greater than 0.55 mm (Sattethwaite), then exclude
	    if fdJenk_Mean_Here > 0.55
		    exclude(subjNum,runIxHere) = 1;
        elseif fdJenk_Mean_Here <= 0.55
		    exclude(subjNum,runIxHere) = 0;
        elseif isnan(fdJenk_Mean_Here) % NaN due to either missing data or short timeseries
            exclude(subjNum,runIxHere) = 1;
        end

        % ------------------------------------------------------------------------------
	    % Stringent, multi criteria exclusion
	    % ------------------------------------------------------------------------------
        % If the mean of displacement is greater than 0.2 mm (Ciric), then exclude
        % NOTE: in Parkes' paper, used 0.25 mm so using that here
	    if fdJenk_Mean_Here > 0.25
		    mean_exclude(subjNum,runIxHere) = 1;
        elseif fdJenk_Mean_Here <= 0.25
		    mean_exclude(subjNum,runIxHere) = 0;
        elseif isnan(fdJenk_Mean_Here) % NaN due to either missing data or short timeseries
            mean_exclude(subjNum,runIxHere) = 1;
	    end	
        
	    % Calculate whether subject has >20% suprathreshold spikes
	    fdJenkThrPerc = round(numVols * fdThr);

	    % If the number of volumes that exceed fdThr are greater than 20%, then exclude
	    if sum(fdJenk_Trace_Here > fdThr) > fdJenkThrPerc
		    sum_exclude(subjNum,runIxHere) = 1;
        elseif sum(fdJenk_Trace_Here > fdThr) <= fdJenkThrPerc
		    sum_exclude(subjNum,runIxHere) = 0;
        elseif size(fdJenk_Trace_Here,1) == 0
            sum_exclude(subjNum,runIxHere) = 1; % Empty due to either missing data or short timeseries
        end
        
        % 3) Exclude on large spikes (>5mm)
	    if any(fdJenk_Trace_Here > 5)
		    spike_exclude(subjNum,runIxHere) = 1;
        elseif size(fdJenk_Trace_Here,1) == 0
            spike_exclude(subjNum,runIxHere) = 1; % Empty due to either missing data or short timeseries
        else
		    spike_exclude(subjNum,runIxHere) = 0;
        end
         
         % If any of the above criteria is true of subject i, mark for exclusion
        %if exclude(subjNum,runIxHere) == 1 | mean_exclude(subjNum,runIxHere) == 1 | sum_exclude(subjNum,runIxHere) == 1 | spike_exclude(subjNum,runIxHere) == 1
        %    exclude_Total(subjNum,runIxHere) = 1;
        %else
        %    exclude_Total(subjNum,runIxHere) = 0;
        %end
        % NOTE: I've re-done the above in a different way outside of the loop below (see exclude_Total)
        
        % threshold for exclusion in minutes
	    spikereg = GetSpikeRegressors(fdJenk_Trace_Here,fdThr); % Spike regression exclusion
	    numCVols = numVols - size(spikereg,2); % number of volumes - number of spike regressors (columns)
	    NTime = (numCVols * TR)/60; % Compute length, in minutes, of time series data left after censoring
	    if NTime < thresh
		    censoring_exclude(subjNum,runIxHere) = 1;
	    else
		    censoring_exclude(subjNum,runIxHere) = 0;
        end
    end
end

exclude_Total_Init = exclude + mean_exclude + sum_exclude + spike_exclude;
exclude_Total = zeros(numSubjs,numRuns);
nonZeroIxs = find(exclude_Total_Init~=0);
exclude_Total(nonZeroIxs) = 1;

% Print results from more stringent spike regression 
for runIxHere = 1:numRuns
    disp(' ');
    runStrHere = runStrs_All(runIxHere);
    nMissing = sum(missingFile_Log(:,runIxHere));
    nHere = numSubjs - sum(missingFile_Log(:,runIxHere));
    numExcludedAll = sum(exclude_Total(:,runIxHere));
    disp(append(runStrHere,' (n=',string(nHere),'):'));
    disp(append('for 3 main criteria, n=',string(numExcludedAll),...
        ' (',string(round(((numExcludedAll-nMissing)/nHere)*100,2)),'%) excluded' ));

    totalExcludedIxs = find(exclude_Total(:,runIxHere)~=0);
    censoredExcludedIxs = find(censoring_exclude(:,runIxHere)~=0);
    vecSizes = [size(totalExcludedIxs,1),size(censoredExcludedIxs,1)];
    uniqueCensored = setdiff(censoredExcludedIxs,totalExcludedIxs);
    disp(append('for spike regression criteria, another n=',string(size(uniqueCensored,1)),' were excluded'));
end

% SAVE
cd(baseDir);
save("exclude_mask_0.55_all_subjs_all_runs.mat","exclude");
save("exclude_mask_0.2_all_subjs_all_runs.mat","mean_exclude");
save("exclude_mask_20_percent_trace_all_subjs_all_runs.mat","sum_exclude");
save("exclude_mask_large_spikes_all_subjs_all_runs.mat","spike_exclude");
save("exclude_mask_spike_regression_vol_censoring_all_subjs_all_runs.mat","censoring_exclude");
save("exclude_mask_stringent_total_all_subjs_all_runs.mat","exclude_Total");

save("fd_mm_Jenkinson_all_subjs_all_runs.mat","fdJenk_All");
save("fd_mm_Jenkinson_MEAN_all_subjs_all_runs.mat","fdJenk_Mean_All");
save("short_timeseries_log_all_subjs_all_runs.mat","trMisMatch_Log");
save("missing_run_log_all_subjs_all_runs.mat","missingFile_Log");

subjIDs_Save = char(subjIDs_All');
runStrs_Save = char(runStrs_All);
save("subjIDs_All.mat","subjIDs_Save");
save("runStrs_All.mat","runStrs_Save");

% Generating some arrays to copy and paste into CSVs for other analyses (FD-FC, etc.); 
% see /Users/carrisacocuzza/Google Drive/My Drive/Yale_Rutgers_Postdoc_Files/Holmes_Lab/Projects/DataRelease_TCP/TCP_FD/

% Rest AP run 1 
runIx = 1;
fdJenk_All_RestAP1 = zeros(numSubjs,trsAll(runIx));
for subjIx = 1:numSubjs
    traceHere = fdJenk_All{subjIx,runIx};
    if isempty(traceHere)
        traceHere = nan(trsAll(runIx),1);
    end
    [trTest,emptyDim] = size(traceHere);
    if trTest~=trsAll(runIx)
        traceHere_Init = traceHere;
        traceHere = nan(trsAll(runIx),1);
        traceHere(1:trTest,1) = traceHere_Init;
    end
    fdJenk_All_RestAP1(subjIx,:) = fdJenk_All{subjIx,runIx};
end

% Rest AP run 2 
runIx = 2;
fdJenk_All_RestAP2 = zeros(numSubjs,trsAll(runIx));
for subjIx = 1:numSubjs
    traceHere = fdJenk_All{subjIx,runIx};
    if isempty(traceHere)
        traceHere = nan(trsAll(runIx),1);
    end
    [trTest,emptyDim] = size(traceHere);
    if trTest~=trsAll(runIx)
        traceHere_Init = traceHere;
        traceHere = nan(trsAll(runIx),1);
        traceHere(1:trTest,1) = traceHere_Init;
    end
    fdJenk_All_RestAP2(subjIx,:) = traceHere;
end

% Rest PA run 1 
runIx = 3;
fdJenk_All_RestPA1 = zeros(numSubjs,trsAll(runIx));
for subjIx = 1:numSubjs
    traceHere = fdJenk_All{subjIx,runIx};
    if isempty(traceHere)
        traceHere = nan(trsAll(runIx),1);
    end
    [trTest,emptyDim] = size(traceHere);
    if trTest~=trsAll(runIx)
        traceHere_Init = traceHere;
        traceHere = nan(trsAll(runIx),1);
        traceHere(1:trTest,1) = traceHere_Init;
    end
    fdJenk_All_RestPA1(subjIx,:) = traceHere;
end

% Rest PA run 2
runIx = 4;
fdJenk_All_RestPA2 = zeros(numSubjs,trsAll(runIx));
for subjIx = 1:numSubjs
    traceHere = fdJenk_All{subjIx,runIx};
    if isempty(traceHere)
        traceHere = nan(trsAll(runIx),1);
    end
    [trTest,emptyDim] = size(traceHere);
    if trTest~=trsAll(runIx)
        traceHere_Init = traceHere;
        traceHere = nan(trsAll(runIx),1);
        traceHere(1:trTest,1) = traceHere_Init;
    end
    fdJenk_All_RestPA2(subjIx,:) = traceHere;
end

% Stroop AP 
runIx = 5;
fdJenk_All_StroopAP = zeros(numSubjs,trsAll(runIx));
for subjIx = 1:numSubjs
    traceHere = fdJenk_All{subjIx,runIx};
    if isempty(traceHere)
        traceHere = nan(trsAll(runIx),1);
    end
    [trTest,emptyDim] = size(traceHere);
    if trTest~=trsAll(runIx)
        traceHere_Init = traceHere;
        traceHere = nan(trsAll(runIx),1);
        traceHere(1:trTest,1) = traceHere_Init;
    end
    fdJenk_All_StroopAP(subjIx,:) = traceHere;
end

% Stroop PA
runIx = 6;
fdJenk_All_StroopPA = zeros(numSubjs,trsAll(runIx));
for subjIx = 1:numSubjs
    traceHere = fdJenk_All{subjIx,runIx};
    if isempty(traceHere)
        traceHere = nan(trsAll(runIx),1);
    end
    [trTest,emptyDim] = size(traceHere);
    if trTest~=trsAll(runIx)
        traceHere_Init = traceHere;
        traceHere = nan(trsAll(runIx),1);
        traceHere(1:trTest,1) = traceHere_Init;
    end
    fdJenk_All_StroopPA(subjIx,:) = traceHere;
end

% Hammer AP 
runIx = 7;
fdJenk_All_Hammer = zeros(numSubjs,trsAll(runIx));
for subjIx = 1:numSubjs
    traceHere = fdJenk_All{subjIx,runIx};
    if isempty(traceHere)
        traceHere = nan(trsAll(runIx),1);
    end
    [trTest,emptyDim] = size(traceHere);
    if trTest~=trsAll(runIx)
        traceHere_Init = traceHere;
        traceHere = nan(trsAll(runIx),1);
        traceHere(1:trTest,1) = traceHere_Init;
    end
    fdJenk_All_Hammer(subjIx,:) = traceHere;
end

%% Mask FD by site: extracting McLean participants 
% NOTE: given that FD was estimated per subject and run above, I'll just 
% extract the results that were generated above 

siteStrHere = 'McLean';
numSubjs_ThisSite = 104; 
subjStartIx_ThisSite = 138;

subjIDs_All_ThisSite = subjIDs_All(subjStartIx_ThisSite:end);

% First create mask: 
siteMaskArr = zeros(numSubjs_ThisSite,numRuns);
for runIxHere = 1:numRuns
    runStrHere_Init = runStrs_All(runIxHere);
    runStrHere_Split = split(runStrHere_Init,"_bold");
    runStrHere = runStrHere_Split(1);

    fileName = append(subjID_Ref_Dir,'subjID_Indexing_Ref_Vec_NDA_',siteStrHere,'_',runStrHere,'.mat');    
    subjIDs_NDA_BySiteAndRun = load(fileName).subjIDs_NDA_BySite;
    
    [numSubjsHere,numChars] = size(subjIDs_NDA_BySiteAndRun);
    for subjIx = 1:numSubjsHere
        subjIDHere = subjIDs_NDA_BySiteAndRun(subjIx,:);
        subjIx_Orig = find(contains(subjIDs_All_ThisSite,subjIDHere));
        if subjIDs_All_ThisSite(subjIx_Orig) ~= subjIDHere
            disp(append('**** WARNING: subject IDs dont match for',runStrHere,'. Expected subject ',subjIDHere,' but got index for ',subjIDs_All_ThisSite(subjIx_Orig)));
        end
        siteMaskArr(subjIx_Orig,runIxHere) = 1;
    end
end

%% Mask FD by site: extracting Yale participants 
% NOTE: given that FD was estimated per subject and run above, I'll just 
% extract the results that were generated above 

siteStrHere = 'Yale';
numSubjs_ThisSite = 137; 
subjStartIx_ThisSite = 1;

subjIDs_All_ThisSite = subjIDs_All(subjStartIx_ThisSite:end);

% First create mask: 
siteMaskArr = zeros(numSubjs_ThisSite,numRuns);
for runIxHere = 1:numRuns
    runStrHere_Init = runStrs_All(runIxHere);
    runStrHere_Split = split(runStrHere_Init,"_bold");
    runStrHere = runStrHere_Split(1);

    fileName = append(subjID_Ref_Dir,'subjID_Indexing_Ref_Vec_NDA_',siteStrHere,'_',runStrHere,'.mat');    
    subjIDs_NDA_BySiteAndRun = load(fileName).subjIDs_NDA_BySite;
    
    [numSubjsHere,numChars] = size(subjIDs_NDA_BySiteAndRun);
    for subjIx = 1:numSubjsHere
        subjIDHere = subjIDs_NDA_BySiteAndRun(subjIx,:);
        subjIx_Orig = find(contains(subjIDs_All_ThisSite,subjIDHere));
        if subjIDs_All_ThisSite(subjIx_Orig) ~= subjIDHere
            disp(append('**** WARNING: subject IDs dont match for',runStrHere,'. Expected subject ',subjIDHere,' but got index for ',subjIDs_All_ThisSite(subjIx_Orig)));
        end
        siteMaskArr(subjIx_Orig,runIxHere) = 1;
    end
end

% NOTE: from here I did the rest in jupyterlab (just visualizing the results; Fig S2)
% EDIT TO ADD: I also did Welch's t-tests for DX vs. HC and McLean vs. Yale in python (scipy)


