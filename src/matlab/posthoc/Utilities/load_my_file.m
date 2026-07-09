clearvars
addpath(genpath('\\wsl.localhost\ubuntu\home\aoih\adapt_aep\src\matlab'))

% Set data location
base_dir = 'F:\2026\Research\July Midshipman';
cd(base_dir)
subjid_vec = {23};
file_type = 'mixed_stimuli';
stim_freq = 100;
stim_amp = [];

% Setup filename
if isempty(stim_freq), stim_freq = '*'; else stim_freq = sprintf('%dHz', stim_freq); end
if isempty(stim_amp),    stim_amp    = '*'; else stim_amp    = sprintf('%ddBSPL',stim_amp);    end
if isempty(file_type), file_type = '*'; end

for isubj = 1:length(subjid_vec)
    % Get file names
    subjid = subjid_vec{isubj};
    subject_folder = sprintf('*_%d*', subjid);
    current_folder = dir(subject_folder);
    my_path = sprintf('%s/%s/%s', base_dir,current_folder.name, file_type);
    cd(my_path)
    if isempty(subjid),    subjid    = '*'; else subjid    = num2str(subjid);    end
    files = dir(sprintf('*%s_%s_*_%s_%s*', subjid, stim_freq, stim_amp, file_type));
    if isempty(files)
        fprintf('No files found')
    else
    my_names{isubj} = {files.name};
    end

    % Load in files
    for iname = 1:length(my_names{isubj})
        current_file = my_names{isubj}{iname};
        fprintf('Loading %s for subject %s, %d/%d\n',current_file, subjid, iname, length(my_names{isubj}))
        S = load(current_file);
        ex = S.ex_save;
        cur_amp = ex.info.stimulus.amplitude_spl;
        cur_freq = ex.info.stimulus.frequency_hz;
        my_amp(iname,isubj) = cur_amp;
        my_freq(iname,isubj) = cur_freq;
        my_fs(iname,isubj) = ex.info.recording.sampling_rate_hz;
        freq_2f(iname,isubj) = 2*cur_freq;
        grand_ex_save{iname,isubj} = ex;
        subjid_list{isubj} = subjid;
    end
end