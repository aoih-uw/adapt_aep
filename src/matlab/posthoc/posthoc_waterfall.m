% Function posthoc_waterfall
amp_vec = 95:3:140;
stim_type_vec = {'trim', 'ONOFF'};
my_chans = [2,3,4]; % 2 = 2mm, 3 = 4mm, 4 = subcut
target_freq_range =  3; % for fft bin finding calculations
isubj = 1;

% Loop through freq_vec and ON_fft_vals
for itype = 1:length(stim_type_vec)
    for ichan = 1:length(my_chans)
        for iamp = 1:length(amp_vec)
            cur_freq_vec = squeeze(freq_vec(:,:,iamp, itype, ichan));
            cur_fft_vals  = squeeze(ON_fft_vals(:,:,iamp, itype, ichan));
            
            % Remove appended Nans
            cur_freq_vec(isnan(cur_freq_vec)) = [];
            cur_fft_vals(isnan(cur_fft_vals)) = [];
        end
    end
end