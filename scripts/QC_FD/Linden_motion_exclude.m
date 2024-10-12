
projectdir = '~/kg98_scratch/Sid/GoC/scripts/'; 
%change ses as required
fileID = fopen([projectdir,'list.txt']); %file path to .txt file wth subj id 
ParticipantIDs = textscan(fileID,'%s');
ParticipantIDs = ParticipantIDs{1};

% compute numsubs
numSubs = length(ParticipantIDs);


% ------------------------------------------------------------------------------
% Containers
% ------------------------------------------------------------------------------
motionparams = cell(numSubs,1);

fdJenk = cell(numSubs,1);
fdJenk_mean = zeros(numSubs,1);

for i = 1:numSubs
    motionparams{i} = importdata(['~/kg98/kristina/GenofCog/datadir/derivatives/',subject,'/prepro.feat/mc/prefiltered_func_data_mcf.par']) ; % change to point to text file with 6 motion parameters.
    numVols = size(motionparams{i},1);
    % Get FD 
	fdJenk{i} = GetFDJenk_multiband(motionparams{i},0.8,3,[0.2 0.5], 80);% chage tr and/or defualt params 
    %fdJenk{i} = GetFDJenk(motionparams{i},80);
	
    % Calculate mean
	fdJenk_mean(i) = mean(fdJenk{i});
    
    % ------------------------------------------------------------------------------
    % Initial, gross movement exclusion
    % ------------------------------------------------------------------------------
	% 1) Exclude on mean rms displacement
	% Calculate whether subject has suprathreshold mean movement
	% If the mean of displacement is greater than 0.55 mm (Sattethwaite), then exclude
	if fdJenk_mean(i) > 0.55
		exclude(i,1) = 1;
	else
		exclude(i,1) = 0;
    end	

    % ------------------------------------------------------------------------------
	% Stringent, multi criteria exclusion
	% ------------------------------------------------------------------------------
    % If the mean of displacement is greater than 0.2 mm (Ciric), then exclude
	if fdJenk_mean(i) > 0.2 
		mean_exclude(i,1) = 1;
	else
		mean_exclude(i,1) = 0;
	end	
    
	% Calculate whether subject has >20% suprathreshold spikes
    fdThr = 0.20;
	fdJenkThrPerc = round(numVols * 0.20);
	% If the number of volumes that exceed fdThr are greater than %20, then exclude
	if sum(fdJenk{i} > fdThr) > fdJenkThrPerc
		sum_exclude(i,1) = 1;
	else
		sum_exclude(i,1) = 0;
    end
    
    % 3) Exclude on large spikes (>5mm)
	if any(fdJenk{i} > 5)
		spike_exclude(i,1) = 1;
	else
		spike_exclude(i,1) = 0;
    end
     
     % If any of the above criteria is true of subject i, mark for exclusion
    if mean_exclude(i,1) == 1 | sum_exclude(i,1) == 1 | spike_exclude(i,1) == 1
        exclude(i,2) = 1;
    else
        exclude(i,2) = 0;
    end
    
    % threshold for exclusion in minutes
	thresh = 4;
    TR = .754; 
	spikereg = GetSpikeRegressors(fdJenk{i},fdThr); % Spike regression exclusion
	numCVols = numVols - size(spikereg,2); % number of volumes - number of spike regressors (columns)
	NTime = (numCVols * TR)/60; % Compute length, in minutes, of time series data left after censoring
	if NTime < thresh;
		censoring_exclude(i,1) = 1;
	else
		censoring_exclude(i,1) = 0;
    end
    
    
end
    
T = table(ParticipantIDs, motionparams, fdJenk, fdJenk_mean, exclude, mean_exclude, sum_exclude, spike_exclude, censoring_exclude, exclude(:,1), exclude(:,2));
T.Properties.VariableNames = {'ParticipantIDs'  'motion_params' 'fdJenk'  'fdJenk_mean'  'exclude'  'mean_exclude'  'sum_exclude'  'spike_exclude'  'censoring_exclude'  'grossmvmt_exclude'  'stringent_exclude'};
    
