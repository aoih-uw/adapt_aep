function ex = select_next_dialog(ex)

fprintf('\n========================================\n');
fprintf('  Set Stimulus Amplitude\n');
fprintf('========================================\n');
fprintf('  Valid range: %g - %g dB SPL\n', ex.info.speaker.min_amplitude_limit, ex.info.speaker.max_amplitude_limit);
while true
    try
        val = str2double(input('Enter amplitude (dB SPL): ', 's'));
    catch
        fprintf('Invalid input. Please enter a valid number.\n');
        continue;
    end
    if ~isnan(val)
        if val < ex.info.speaker.min_amplitude_limit || val > ex.info.speaker.max_amplitude_limit
            fprintf('Amplitude out of range. Please enter a value between %g and %g dB SPL.\n', ...
                ex.info.speaker.min_amplitude_limit, ex.info.speaker.max_amplitude_limit);
        else
            ex.info.stimulus.amplitude_spl = val;
            break;
        end
    else
        fprintf('Invalid input. Please enter a valid number.\n');
    end
end
end