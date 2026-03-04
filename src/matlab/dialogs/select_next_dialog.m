function ex = select_next_dialog(ex)
[y, Fs] = audioread('step.mp3');
sound(y, Fs)

fprintf('\n========================================\n');
fprintf('  Set Stimulus Amplitude\n');
fprintf('========================================\n');

while true
    val = input('Enter amplitude (dB SPL): ');
    if ~isempty(val) && isnumeric(val) && isscalar(val) && ~isnan(val)
        ex.info.stimulus.amplitude_spl = val;
        break;
    else
        fprintf('Invalid input. Please enter a valid number.\n');
    end
end
end