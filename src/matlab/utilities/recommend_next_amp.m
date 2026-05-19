function next_test_amp = recommend_next_amp(ex)
tested_amps = ex.model.amplitude_vec_sorted;
next_test_amp = [];

if any(isnan(tested_amps))
    % Skip need to test at least one frequency first
else
    % Remove the noise_floor data point
    find_80 = find(tested_amps <= 80);
    if ~isempty(find_80)
        tested_amps(find_80) = [];
    end

    if length(tested_amps) == 1
        next_test_amp = tested_amps-30; % Go 30 dB down

        % If after going down 30 db and still find a response, then go down
        % another 10... and then another 10 until you don't find anything
    else
        my_diff = diff(tested_amps);

        % Find the idx of the two highest tested frequencies with the largest gap
        next_test_amp_idx = find(my_diff > 7, 1, 'last'); % 7 dB search first
        if isempty(next_test_amp_idx)
            next_test_amp_idx = find(my_diff > 5, 1, 'last'); % Then narrow down to 5 dB search
            if isempty(next_test_amp_idx)
                next_test_amp_idx = find(my_diff > 3, 1, 'last'); % Then narrow down to 3 dB search
            end
        end

        if ~isempty(next_test_amp_idx)
            lower_amp = tested_amps(next_test_amp_idx);
            higher_amp = tested_amps(next_test_amp_idx+1);
            next_test_amp = round((higher_amp+lower_amp)/2);
        end

    end
end