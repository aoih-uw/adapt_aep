function [exp_params,stim_params,rec_params,adapt_params] = setupvars(args)
% Set up the basic variables that will be used in this experiment

exp_params = args.exp_params;
% Add this to GUI


stim_params = args.stim_params;
     % add onramp off ramp parameter to GUI
     % add prestim_duration param to stim params (equal to the duration of the
     % response window we are using to calculate the fft and ITPC)
     % Add option for defining prestim and stim duration and make them the
     % same length
     % set minimum amplitude? stim_params.minAmplitude
     % Maximum amplitude stim_params.maxAmplitude

     rec_params = args.rec_params;
    % AEP_scalefact ?

     adapt_params = args.adapt_params; 
    % add a adapt_params to GUI
    % adaptive_params = struct(...
    % 'fft_block_size', 10, ...          % Trials per FFT block
    % 'spectro_block_size', 30, ...      % Additional trials before next spectro
    % 'can_start_spectro', 100, ...      % Min trials before first spectro
    % 'amplitude_step', 3, ...           % dB step for amplitude adjustment
    % 'permutation_count', 1000, ...     % Number of permutations
    % 'permutation_N_pval_min', 5, ...   % Min p-values before trendline
    % 'max_stim_presentation', 500, ... % Max stimulus presentations for each stimulus type
    % 'alpha_total', 0.05, ...           % overall two-sided family wise-level
    % );
    