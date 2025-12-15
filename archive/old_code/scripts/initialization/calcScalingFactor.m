function [rec_params, ampgain, Vscale, gain_ch1, gain_ch2, gain_ch3, gain_ch4]= calcScalingFactor(rec_params)
%% Calculate the scaling factor used to convert electrode signals from digital to analog units (microVolt)
ampgain = rec_params.bioamp_gain;
rec_params.AEP_scalefact = (1/.2044) ./ ampgain;

% Channel-specific correction factors if needed
gain_ch1 = ampgain;
gain_ch2 = ampgain;
gain_ch3 = ampgain;
gain_ch4 = ampgain;

% Voltage scale factor
Vscale = 5.124;