clearvars
addpath(genpath('\\wsl.localhost\ubuntu\home\aoih\adapt_aep\src\matlab'))

% Set data location
cd 'F:\2026\Research\May Midshipman\2026_06_02\porichthys_notatus_16_20260602\benzo'
subjid_vec = {16};
stim_freq = 110;
stim_amp = [];
file_type = 'raw_data';

% Setup filename
if isempty(stim_freq), stim_freq = '*'; else stim_freq = sprintf('%dHz', stim_freq); end
if isempty(stim_amp),    stim_amp    = '*'; else stim_amp    = sprintf('%ddBSPL',stim_amp);    end
if isempty(file_type), file_type = '*'; end

for isubj = 1:length(subjid_vec)
    % Get file names
    subjid = subjid_vec{isubj};
    if isempty(subjid),    subjid    = '*'; else subjid    = num2str(subjid);    end

    files = dir(sprintf('*%s_%s_%s_%s*', subjid, stim_freq, stim_amp, file_type));
    my_names{isubj} = {files.name};

    % Load in files
    for iname = 1:length(my_names{isubj})
        current_file = my_names{isubj}{iname};
        fprintf('Loading file for subject %s, %d/%d\n', subjid, iname, length(my_names{isubj}))
        S = load(current_file);
        ex = S.ex_save;
        cur_amp = ex.info.stimulus.amplitude_spl;
        cur_freq = ex.info.stimulus.frequency_hz;
        my_amp(iname,isubj) = cur_amp;
        my_freq(iname,isubj) = cur_freq;
        my_fs(iname,isubj) = ex.ds_fs;
        freq_2f(iname,isubj) = 2*cur_freq;
        grand_ex_save{iname,isubj} = ex;
        subjid_list{isubj} = subjid;
    end
end