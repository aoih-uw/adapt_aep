function my_names = get_file_names(subjid, stim_freq, stim_amp, file_type)
if isempty(subjid),    subjid    = '*'; else subjid    = num2str(subjid);    end
if isempty(stim_freq), stim_freq = '*'; else stim_freq = sprintf('%dHz', stim_freq); end
if isempty(stim_amp),    stim_amp    = '*'; else stim_amp    = sprintf('%ddBSPL',stim_amp);    end
if isempty(file_type), file_type = '*'; end

files = dir(sprintf('*%s_%s_%s_%s*', subjid, stim_freq, stim_amp, file_type));
my_names = {files.name};
end