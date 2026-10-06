function [sigs_g, sigs_m_per_s_sqrd] = convert_mV_to_accel(accel_sigs_mV, g_factor, m_per_s_sqrd_factor)
% % accel_sigs_mV must be 3 x n_samples (rows = X, Y, Z)
% accel_sigs_mV must already have DAC conversion and amplifier correction
% factors applied
% g_factor and m_per_s_sqrd_factor must have 3 values to represent the 3
% dimensions

% Force factors to be 3x1 vectors
g_factor = g_factor(:);
m_per_s_sqrd_factor = m_per_s_sqrd_factor(:);

% Convert to g
sigs_g = accel_sigs_mV./g_factor;

% Convert to m/s^2
sigs_m_per_s_sqrd = accel_sigs_mV./m_per_s_sqrd_factor;
