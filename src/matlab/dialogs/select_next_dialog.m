function ex = select_next_dialog(ex)
% SELECT_NEXT_DIALOG  Prompt user to select the next stimulus amplitude.
%
% SYNTAX
%   ex = select_next_dialog(ex)
%
% DESCRIPTION
%   Presents a command-line prompt and validates numeric scalar input.
%   Loops until a valid dB SPL value is entered, then stores it in ex.
%
% INPUTS
%   ex  - struct  Experiment struct
%
% OUTPUTS
%   ex  - struct  Experiment struct with updated amplitude field
%
% MODIFIED FIELDS
%   ex.info.stimulus.amplitude_spl  - Stimulus amplitude in dB SPL
%
% CALLED BY
%   run_adapt_aep, pause_dialog
%
% SEE ALSO
%   make_decision_dialog, pause_dialog

[y, Fs] = audioread('step.mp3');
sound(y, Fs)

fprintf('\n========================================\n');
fprintf('  Set Stimulus Amplitude\n');
fprintf('========================================\n');

while true % Loops forever
    val = input('Enter amplitude (dB SPL): ');
    if ~isempty(val) && isnumeric(val) && isscalar(val) && ~isnan(val)
        ex.info.stimulus.amplitude_spl = val;
        break;
    else
        fprintf('Invalid input. Please enter a valid number.\n'); % Loop back at the top and ask again
    end
end
end