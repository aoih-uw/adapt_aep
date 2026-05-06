function [noise_floor_median, noise_floor_mad] = calculate_smallest_noise_floor(noise_floor,mad_criteria)
% Calculate noise_floor characteristics
noise_floor_medians = cellfun(@median, noise_floor);
noise_floor_mads = cellfun(@(x) mad(x,1), noise_floor);
thres_criterias = noise_floor_medians + noise_floor_mads*1.4826*mad_criteria;
[~,idx] = min(thres_criterias);
select_noise_floor = noise_floor{idx};
noise_floor_median = median(select_noise_floor);
noise_floor_mad = mad(select_noise_floor);