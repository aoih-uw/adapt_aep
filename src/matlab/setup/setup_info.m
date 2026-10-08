function ex = setup_info(ex, app)
my_time = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyy-MM-dd HH:mm:ss');
% Setup random seed
rng('shuffle');
rng_state = rng;

% Setup file directories
src_root  = fileparts(fileparts(mfilename('fullpath')));   % .../src/matlab
repo_root = fileparts(fileparts(src_root));                % .../adapt_aep

% Experiment information
ex.info.experiment = struct( ...
    'path_root',            src_root, ...
    'save_root',            fullfile(repo_root, 'data', 'aep'), ...
    'facility_name',         'Sisneros Laboratory', ...
    'experimenter_name',     'Aoi Hunsaker', ...
    'exp_date',              datestr(my_time, 'yyyymmdd'), ...
    'exp_time_start',        NaT, ...
    'exp_time_end',          NaT, ...
    'total_time_elapsed',    NaT, ...
    'timer_dur_min',         NaN, ... % Minutes
    'exp_duration',          NaN, ...
    'exp_type',              NaN, ...
    'test_tag',              NaN, ...
    'drug_name',             'Anesthetic: Benzocaine sulfate; Paralytic: Cisatracurium besylate; Analgesic: Bupivicaine', ...
    'drug_delivery_method',  'Anesthetic: Bath; Paralytic: Intramuscular injection; Analgesic: Intramuscular injection', ...      % bath / injection / none
    'drug_concentration',    'Anesthetic: 0.025%, 1 ml of 10% solution of benzocaine in ethynol per 400 ml of water bath; Paralytic: 30 mg kg−1; Analgesic: 1 mg/kg  ', ...
    'target_water_temp_C',    13, ...
    'water_temp_tol_C',       1, ...
    'water_salinity',         27, ...
    'water_depth',            'From sediment to surface of water = 20 cm; From sediment to bottom of headholder = 10 cm', ...
    'fish_placement',         'Head placed in center of tank in xyz plane relative to the speaker and volume of water. Efforts made to keep body as horizontal and neutrally bouyant as possible.', ...
    'tank_dimensions',        'X liter circular tank (X mm inside diameter)', ...
    'tank_material',          'High density polyethelene', ...
    'tank_isolation_method',  'Floating table', ...
    'response_feature',       'double_frequency_response', ...
    'random_seed',            rng_state.Seed, ...
    'notes',                  [] ...
    );

% Animal information1
ex.info.animal = struct( ...
    'species_name',          'porichthys_notatus', ...
    'subject_ID',            NaN, ... % In app
    'sex',                   NaN, ... % In app
    'developmental_stage',   'adult', ...
    'source',                'hand collection at Seal Rock Beach Quilcene WA', ...
    'collection_date',       '2026-07', ...
    'housing',               'Indoor holding tanks', ...
    'diet',                  'Mixed diet shrimp and squid', ...
    'acclimation_period',    'Minimum 1 week', ...
    'IACUC_protocol_ID',     'University of Washington Animal Care and Use Committee', ...
    'collection_permit',     'Washington State Scientific Collection Permit from Department of Fish and Wildlife', ...
    'filename_root',         NaN ...
    );

% Channel parameters
ex.info.electrodes = struct( ...
    'reference_location',    'tail', ...
    'ground_location',       'in water', ...
    'electrode_type',        'Subdermal, differential measurment, stainless steel, 27 gauge, 13 mm, Rochester Electromedical Inc.; Coral Springs, FL, USA', ...
    'electrode_depth',       '3mm, 5mm, 5mm, 3mm' ...
    );
if ex.test_accel
    ex.info.electrodes.names = {'Subcranial'};
    ex.info.electrodes.n_channels = 1;
    ex.info.electrodes.analysis_channel = 'Subcranial';
else
    ex.info.electrodes.names = {'Forebrain','Subcranial','Subcutaneous','EKG'};
    ex.info.electrodes.n_channels = numel(ex.info.electrodes.names);
    ex.info.electrodes.analysis_channel = 'Subcranial';
end

%% Recording parameters
ex.info.DAC.sampling_rate_hz = 44100; % (highest presented stimulus)*(nyquist)*(signal quality)
ex.info.DAC.latency_samples = NaN;
ex.info.DAC.expected_latency_samples = 2118;

% Thermometer
ex.info.thermometer.port = "COM5";

% Fireface Digital to Analog Converter (DAC)
ex.info.DAC.model_serial = 'USB D/A Converter, Fireface UCX, RME, Frankfurt, Germany';
ex.info.DAC.conversion_factor = 5.1045; % Previously 1/0.2044;  Multiply by this factor to recover true voltage value
ex.info.DAC.output_channels = [1 4];
ex.info.DAC.output_channel_names = {'Underwater Speaker', 'Loopback'};
ex.info.DAC.input_channels = [3:8];

% Assign DAC inputs
% Currently in accelerometer test mode, it only supports measurement from 1 electrode, 
% and it is assigned as the last channel the DAC can take
if ex.test_accel
    ex.info.DAC.input_channel_names = {'Hydrophone', 'Loopback', 'X', 'Y', 'Z', 'Ch1'};
else
    ex.info.DAC.input_channel_names = {'Hydrophone', 'Loopback', 'Ch1', 'Ch2','Ch3','Ch4'};
end

% Hydrophone
ex.info.hydrophone.model = 'Type 8103, Bruel & Kjaer, Nærum, Denmark, Serial #: ';
ex.info.hydrophone.gain_mV_per_Pa = 3.16; % 3.16 mV/Pa

% Amplifiers
ex.info.bio_amp.model_serial = 'BMA-400, CWE Inc. Ardmore, PA, USA';
ex.info.bio_amp.gain = 10000;
ex.info.speaker_amp.model = 'Power amplifier, Crown D75-A, Harman, Northridge, CA, USA';

% Accelerometer parameters
% Sensitivity @ 100 Hz, last calibrated 6/08/2007
ex.info.accel.model_number = '356A32';
ex.info.accel.serial_number = '72226';
ex.info.accel.name = 'ICP Triaxial Accelerometer Manufacturer PCB Piezotronics';
ex.info.accel.amp_gain = 100; % Divide signal by amplifier gain
ex.info.accel.chan_order = {'X', 'Y', 'Z'};
ex.info.accel.mV_per_g = [101.7 98.4 108.1]; % Divide signal by sensitivity factor
ex.info.accel.mV_per_m_per_s_sqrd = [10.37 10.03 11.02]; % Divide signal by sensitivity factor

% Speaker parameters
ex.info.speaker = struct( ...
    'model',                        'Clark Synthesis Aquasonic Diluvio AQ339 ', ...
    'max_frequency_limit',                  2000, ...
    'min_frequency_limit',                  30, ...
    'speaker_distance_from_head',            '12 cm', ...
    'speaker_orientation',                  'centered under fish' ...
    );

% Trial Count testing parameters
ex.info.trials = struct( ...
    'trials_per_block',                    10, ... % Must be an even number of equal number of stimulus +/- polarities in block
    'max_trials',                          NaN, ... % Set in GUI
    'max_block',                           NaN, ...
    'max_block_health',                    NaN ...
    );

% Signal preprocessing parameters
ex.info.signal_quality = struct( ...
    'filter_type',                       'butterworth', ...
    'pass_band_hz',                       35, ...
    'mad_to_std',                         1.4826, ...% to convert mad to a std like value
    'rejection_threshold_sd',             100 ...
    );

%% Experiment type specific info
if strcmp(app.DropDown_test_mode.Value,'Mixed freqs')
    % Assign values
    ex.info.mixed.stim_freqs        = [55 100 410];
    ex.info.mixed.max_trials        = [260 260 260]; % These all must be the same value
    ex.info.mixed.test_amplitudes   = {83:3:140, 95:3:140, 116:3:140};
    ex.info.mixed.stim_name         = {'ONOFF'};
    ex.info.mixed.N_trials_per_file = 200;

    % Preallocate test schedule
    test_schedule = [];
    tpb = ex.info.trials.trials_per_block; % n trials per batch
    for ifreq = 1:size(ex.info.mixed.stim_freqs,2)
        cur_amp_vec = ex.info.mixed.test_amplitudes{ifreq};
        total_trials = sum(ex.info.mixed.max_trials(ifreq)*size(cur_amp_vec,2));
        if mod(total_trials,tpb) == 0
            total_batches = total_trials/tpb;
            test_schedule = [test_schedule; zeros(total_batches, 4)]; % rows = total_N_batches columns: freq stim_type, stim_amp, N_trials_needed
        else
            error('Non-integer batch count!')
        end
    end

    % Fill out test schedule
    my_idx = 1;
    for ifreq = 1:size(ex.info.mixed.stim_freqs,2)
        cur_trial_needed_per_amp = ex.info.mixed.max_trials(ifreq); % ex. 1030 trials
        if mod(cur_trial_needed_per_amp,tpb) == 0
            cur_batches_needed_per_amp = cur_trial_needed_per_amp/tpb; % ex. 103 batches
        else
            error('Non integer batch count!')
        end
        cur_amp_vec = ex.info.mixed.test_amplitudes{ifreq};
        for iamp = 1:size(cur_amp_vec,2)
            cur_amp = cur_amp_vec(iamp);
            cur_batch_params = [ex.info.mixed.stim_freqs(ifreq) 1 cur_amp cur_trial_needed_per_amp]; % freq, stim_type, stim amp, n trials needed
            cur_batch_repmat = repmat(cur_batch_params, cur_batches_needed_per_amp, 1); % All batches needed for this amplitude and stimulus
            test_schedule(my_idx:my_idx+size(cur_batch_repmat,1)-1,:) = cur_batch_repmat;
            my_idx = my_idx + size(cur_batch_repmat,1);
        end
    end

    % Randomize the testing order and save to ex.info.mixed.test_schedule
    rand_idx = randperm(size(test_schedule,1));
    test_schedule_rand = test_schedule(rand_idx,:);
    [uniq_vals,~,uniq_idx] = unique(test_schedule_rand,'rows');
    test_schedule_rand = [test_schedule_rand uniq_idx];
    % Setup completed 100% tracking column
    test_schedule_rand = [test_schedule_rand zeros(size(test_schedule_rand,1),1)];
    ex.info.mixed.test_schedule = test_schedule_rand;
    ex.info.mixed.uniq_stimuli = uniq_vals;
    ex.info.mixed.N_unique_stimuli = size(uniq_vals,1);
    ex.info.mixed.trial_counter = zeros(size(uniq_vals,1),1);

elseif strcmp(app.DropDown_test_mode.Value,'Adaptive')
    % Signal analysis parameters
    ex.info.analysis = struct( ... % These values will be updated by prepare_next_amplitude when new amplitude is selected
        'n_bootstrap',         5000, ... % See if I need to reduce this...
        'min_trials_for_analysis',             30, ...
        'mad_criteria',            1, ... % How many mad above median in order to do boostrapping
        'peak_mult',           5 ... % immediately confirm response if 2f diff peak is 5x the height of the largest peaks
        );
end

ex.info.colors = {tableau_10('red'), tableau_10('blue'), tableau_10('orange'), tableau_10('teal'), tableau_10('purple'),tableau_10('yellow')};