function [frequencies, presentation_order, myorderedfrequencies] = generateFreqArray(stim_params,randomizeCheckBox)
%#%#%# Max and min frequency needs to be defined via GUI args
% Generate a frequency array with 1/3 octave steps between min and max frequencies
% If randomizeCheckBox == 1: Starts with lowest frequency, then randomizes the rest ensuring no two adjacent frequencies are more than 2 octaves apart
% If randomizeCheckBox == 0: Uses sequential order without randomization or smallest-first rule

frequencies = stim_params.freqRange;

if randomizeCheckBox == 1
    % Apply randomization with smallest frequency first
    % Find the index of the lowest frequency
    [~, min_index] = min(frequencies);
    % Create presentation order starting with lowest frequency
    presentation_order = zeros(1, length(frequencies));
    used_indices = false(1, length(frequencies));
    presentation_order(1) = min_index;
    used_indices(min_index) = true;
    % Build order step by step, ensuring max 2 octave difference
    for step = 2:length(frequencies)
        current_freq = frequencies(presentation_order(step-1));
        
        % Find all unused frequencies within 2 octaves
        valid_indices = [];
        for i = 1:length(frequencies)
            if ~used_indices(i)
                freq_ratio = max(frequencies(i)/current_freq, current_freq/frequencies(i));
                if freq_ratio <= 8  % 2 octaves = ratio of 4
                    valid_indices = [valid_indices, i];
                end
            end
        end
        
        % If no valid frequencies within 2 octaves, use closest available
        if isempty(valid_indices)
            unused_indices = find(~used_indices);
            [~, closest_idx] = min(abs(frequencies(unused_indices) - current_freq));
            next_index = unused_indices(closest_idx);
        else
            % Randomly select from valid options
            next_index = valid_indices(randi(length(valid_indices)));
        end
        
        presentation_order(step) = next_index;
        used_indices(next_index) = true;
    end
else
    % No randomization - use sequential order
    presentation_order = 1:length(frequencies);
end

myorderedfrequencies = frequencies(presentation_order);
end