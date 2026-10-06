function accel_dB = calc_accel_dB(sig_set,ex,accel_dB)
% sig_set must already have amplifier gain and DAC conversion and mV
% correction factors applied
% sig_set must be size n_channels x n_samples

% Convert to g and acceleration
[sigs_g, sigs_m_per_s_sqrd] = ...
    convert_mV_to_accel(sig_set,...
    ex.info.accel.mV_per_g,...
    ex.info.accel.mV_per_m_per_s_sqrd);

% Calculate sum across dimensions
sum_g = sqrt( ...
    (sigs_g(1,:).^2) + ...
    (sigs_g(2,:).^2) + ...
    (sigs_g(3,:).^2));

sum_m_per_s_sqrd = sqrt( ...
    (sigs_m_per_s_sqrd(1,:).^2) + ...
    (sigs_m_per_s_sqrd(2,:).^2) + ...
    (sigs_m_per_s_sqrd(3,:).^2));

% Calculate total RMS
g_rms = rms(sum_g);
sum_m_per_s_sqrd_rms = rms(sum_m_per_s_sqrd);

% Reference to 1 micro g and 1 micro m /s^2
accel_dB.all_dim.micro_g = 20*log10(g_rms/1e-6);
accel_dB.all_dim.micro_m_per_s_sqrd = 20*log10(sum_m_per_s_sqrd_rms/1e-6);

% Per dimension RMS
g_per_dim_rms = NaN(size(sigs_g,1),1);
m_per_s_sqrd_per_dim_rms = NaN(size(sigs_g,1),1);
for i = 1:size(sigs_g,1)
    g_per_dim_rms(i) = rms(sigs_g(i,:));
    m_per_s_sqrd_per_dim_rms(i) = rms(sigs_m_per_s_sqrd(i,:));
end

% Per dimension dB
accel_dB.per_dim.micro_g = 20*log10(g_per_dim_rms./1e-6);
accel_dB.per_dim.micro_m_per_s_sqrd = 20.*log10(m_per_s_sqrd_per_dim_rms./1e-6);