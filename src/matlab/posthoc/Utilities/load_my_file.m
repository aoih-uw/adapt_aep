function [ex, cur_freq, cur_amp, freq_2f] = load_my_file(current_file, iname, my_names)

fprintf('Loading file %d/%d\n', iname, length(my_names))
S = load(current_file);
ex = S.ex_save;
cur_amp = ex.info.stimulus.amplitude_spl;
cur_freq = ex.info.stimulus.frequency_hz;
