function cal_data = calibration_main(main_ax,current_ax,calibration_data)
% function cal_data = calibration_main(varargin)
%
% This function is called by calibrate.m, the m-file associated with the
% 'CALIBRATE FOR AEP TESTING' GUI. It accepts three input arguments, namely
% (1) the handles to the two axes in the GUI, and (2) calibration_data,
% which is defined elsewhere in the directory as a global variable.

% Basically, we need to loop through frequencies if we are calibrating for
% tones, or determine click level if we are using a click. This version has
% been modified from an earlier, more primitve calibration program. Here
% we use 'playrec' and an external audio interface (Fireface UCX), so that
% Windows sound level settings, audio device detection, etc., will not 
% introduce any problems. 
%
% We also visualize the the recorded signals now, and calibrate with the
% stimulus duration that will be appplied in the experiment.
%
fs = 44100;
%% First, ascertain that the Fireface UCX is online. 
if playrec('isInitialised');
    playrec('reset');
end
mydevs = playrec('getDevices');
tmp = mydevs.name;
% Check to make sure that Fireface is online, that we are using ASIO, and that N chans in/out is correct
if tmp~='ASIO Fireface USB'
    if ~strfind(mydevs.name,'Fireface')
        errordlg('The Fireface is not recognized. Is it plugged in? Is it on?');
        error('The Fireface is not recognized. Check to make sure that it is plugged in and turned on')
    end
    if ~strfind(mydevs.name,'ASIO')
        errordlg('The Fireface is recognized, but it appears an older version of PlayRec was called. The program will not work properly. Check the file path and try again.');
        error('The Fireface is recognized, but it appears an older version of PlayRec was called. The program will not work properly. Check the file path and try again.');
    end
end

%% Initialize audio hardware
fprintf('Initializing audio hardware...\n');
playrec('init',fs,0,0,8,8);

% Allow time for audio hardware to fully initialize
pause(2); % 2-second delay for hardware initialization

% Test audio path with a brief silent signal to ensure readiness
test_signal = zeros(1, round(fs * 0.1)); % 100ms of silence
test_page = playrec('playrec', test_signal', 1, -1, 3);
playrec('block', test_page);
playrec('delPage', test_page);
fprintf('Audio hardware ready.\n');

%% Generate calibration stimuli... targets are imbedded in 1-s vectors of 0s, starting at 0.1s
if calibration_data.useclicks
    % Make a biphasic click with 500 microsecs per phase
    target(1).stim = [ones(1,ceil(fs*0.0005))*1 ones(1,ceil(fs*0.0005)).*-1];
    target(1).fullstim = zeros(1,fs);
    target(1).fullstim((fs*0.1)+1:(fs*0.1)+length(target(1).stim)) = target(1).stim;
    target(1).fulltrigstim = target(1).fullstim;
else
    winfact = 5; % 20% of stim is ramp on, 20% is ramp off (1/5)
    numcycle = 5; % 5 cycles total for each stimulus
    for ifreq=1:length(calibration_data.frequency_range)
        dur = 0.4;
        timebase = linspace(0,dur,fs*dur);
        winup_samps = ceil(fs*(dur/winfact)); % on and off ramps scale with stim
        windown_samps = ceil(fs*(dur/winfact)); % each is 20% of total dur
        winup = cos(linspace(-pi/2,0,winup_samps)).^2;
        windown = cos(linspace(0,pi/2,windown_samps)).^2;
        window = [winup ones(1,length(timebase)-(winup_samps+windown_samps)) windown];
        target(ifreq).stim = sin(2*pi*calibration_data.frequency_range(ifreq)*timebase).*window;
        target(ifreq).trigstim = [1 target(ifreq).stim(2:end)]; %force the first sample to be 1
        target(ifreq).fullstim = zeros(1,fs); target(ifreq).fulltrigstim=target(ifreq).fullstim; % align all signals to 1 second chunks
        target(ifreq).fullstim((fs*0.1)+1:(fs*0.1)+length(target(ifreq).stim)) = target(ifreq).stim;
        target(ifreq).fulltrigstim((fs*0.1)+1:(fs*0.1)+length(target(ifreq).stim)) = target(ifreq).trigstim;
    end
end

% SCALE AMPLITUDE of stimuli, depending on whether we are initializing or
% checking the calibration
for ifreq = 1:length(calibration_data.frequency_range);
    if isempty(calibration_data.correction_factors) % then  this is an initial calibration
        % We begin with an output voltage of 0.01 ... this gives us ~40 dB
        % of headroom via digital scaling (note that the FireFace output, in terms of analog
        % output voltage, is roughly 5 times the digitally specified value. Starting at a 
        % low value of 0.01 is OK, as the FireFace UCX is extremely low noise. The output drive 
        % to the speaker is of course ultimately dependent on the power amplifier settings, which 
        % should generally not be adjusted, but should also be compensated for during the calibration
        % process. 
        target(ifreq).fullstim = 0.01.*target(ifreq).fullstim; % start 40 dB down from fs, but ensure that 0.01 associated voltage is waaay below the max output of the speaker
    else
        % we started with an output of 0.01V, but we now need to apply a 
        % correction factor... correction factors are stored in dB, thus,
        % we need to determine voltage factor equivalent. For example, to
        % get a 6 dB increase in SPL, we would double the output voltage...
        % to get a 20 dB decrease, we would divide by 10. 
        corrfact(ifreq) = 10.^(calibration_data.correction_factors(ifreq)./20);
        target(ifreq).fullstim = corrfact(ifreq).*0.01.*target(ifreq).fullstim;
    end
end

%% Note about hydrophone input to the FireFace...
% As with the AEP recordings, input voltages are scaled by the FireFace. With 
% default settings, the scale factor is ~0.2044, i.e. to recover the voltage
% that would be read on the oscilloscope, the FireFace signal should be multiplied
% by 1/0.2044.

% During calibration, we want to target a level of 130 dB SPL. With the hydrophone 
% amplifier output set to 100 mV/Pa, this level is attained when the oscilloscope
% reads 316 mV peak (0.316 V) (i.e, 20*log10(3.16Pa/0.000001Pa) = 130 dB re: 1 uPa)...
% The equivalent reading on the FireFace should be 0.316 * 0.2044 = 0.0646. 
% For an arbitrary hydrophone input value, in order to recover the level at the 
% hydrophone, in Pa, from the input value on the FireFace, we must therefore multiply the 
% FireFace reading by 1/0.2044, then again by 10 (since we only get 0.1 V/Pa)
%
% We thus define a hydrophone correction factor, as follows:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Hydrophone correction factor%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  ADDED 6/13/2017   %%%%%%%%

convention = 'SPL';
switch convention
    case 'lab' % we are defining dB in terms of peak-to-peak amplitude
        HCP = (1/0.2044) * 10 * sqrt(2) * 2; % multiply acquired peak voltage by this level to get peak Pascals at the hydrophone.
    case 'peak' % we are defining dB in terms of peak amplitude... this is the convention for transients
         HCP = (1/0.2044) * 10 * sqrt(2);
    case 'SPL' % we are defining dB in terms of long-term/RMS amplitude... this is the conventional means of converting V to dB SPL
        HCP = (1/0.2044) * 10;
end

dur = ones(1,length(calibration_data.frequency_range)).*0.4;

        %% Now, present sigs and acquire data... for now, only the left speaker
for ifreq = 1:length(calibration_data.frequency_range)
    axes(current_ax);
    if ifreq>1
        delete(displot); delete(sl1); delete(sl2);
        clear displot sl1 sl2;
    end
    if calibration_data.useclicks
        title('Calibrating click...','fontsize',12,'fontweight','bold');
    else
        title(['Calibrating ' num2str(calibration_data.frequency_range(ifreq),'%d') ' Hz...'],'fontsize',12,'fontweight','bold');
    end
    if calibration_data.useclicks
        nrep = 50;
    else
        nrep = 10;
    end
    for irep = 1:nrep; %%% repeat each stimulus 10 times to get a decent estimate
        % Note - we are also going to record the output directly to get a
        % reliable estimate of the system latency so that we can appropriately window 
        % the recording for level calculation. 
        %%%% ADB edit 6/23 modified to capture accelerometer data on X,Y,Z
        calpage = playrec('playrec',[target(ifreq).fullstim' target(ifreq).fulltrigstim'],[1 4],-1,[3 4 5 6 7]);
        playrec('block',calpage);
        temprec = double(playrec('getRec',calpage))';
        calrec(ifreq).hydro(irep,:) = temprec(1,:);
        calrec(ifreq).trig(irep,:) = temprec(2,:);
        calrec(ifreq).AccelX(irep,:) = temprec(3,:);
        calrec(ifreq).AccelY(irep,:) = temprec(4,:);
        calrec(ifreq).AccelZ(irep,:) = temprec(5,:);
        playrec('delPage',calpage);
        % update time domain plot
        if irep == 1;
            if dur(ifreq)>0.8
                displot = plot(linspace(0,length(target(ifreq).fullstim)/fs,fs*(length(mean(calrec(ifreq).hydro,1)))/fs),mean(calrec(ifreq).hydro,1),'k');
            else
                displot = plot(linspace(0,1,fs),mean(calrec(ifreq).hydro,1),'k');
            end
        elseif irep > 1;
            set(displot,'YData',mean(calrec(ifreq).hydro,1));
        end
        drawnow;
    end
    % now use trigger data to window the recording (so that level
    % determination is based on sig region only)
    % find the first sample exceeding 0.5V.. this marks start of stim
    calrec(ifreq).latsamps = find(mean(calrec(ifreq).trig,1)>0.5,1,'first');
    % now calculate mean of hydrophone sig, filter, and window
    calrec(ifreq).mean = mean(calrec(ifreq).hydro,1);
    calrec(ifreq).meanX = mean(calrec(ifreq).AccelX,1);
    calrec(ifreq).meanY = mean(calrec(ifreq).AccelY,1);
    calrec(ifreq).meanZ = mean(calrec(ifreq).AccelZ,1);
    % if its a tone, use tone duration to define analysis window; if its a
    % click, use 10 ms period following click
    if calibration_data.useclicks
        calrec(ifreq).meanfilt = calrec(ifreq).mean;
        %%% Always use 10 ms window... stim is just a biphasic 1 ms click + ringing
        wintrim = ceil(fs*0.010);
        calrec(ifreq).meanfiltwin = calrec(ifreq).meanfilt(calrec(ifreq).latsamps:calrec(ifreq).latsamps+wintrim);
        calrec(ifreq).meanwin = calrec(ifreq).meanfiltwin;
        myylim = get(gca,'ylim');
        sl1 = line([(calrec(ifreq).latsamps)/fs (calrec(ifreq).latsamps)/fs],myylim,'color','r');
        sl2 = line([(calrec(ifreq).latsamps+wintrim)/fs (calrec(ifreq).latsamps+wintrim)/fs],myylim,'color','r');
    else
%         calrec(ifreq).meanfilt = bandpassfilter(calrec(ifreq).mean,calibration_data.frequency_range(ifreq),calibration_data.frequency_range(ifreq),4,fs);
        calrec(ifreq).meanfilt = bandpassfilter(calrec(ifreq).mean,calibration_data.frequency_range(ifreq),calibration_data.frequency_range(ifreq),4);
        calrec(ifreq).meanfiltX = bandpassfilter(calrec(ifreq).meanX,calibration_data.frequency_range(ifreq),calibration_data.frequency_range(ifreq),4);
        calrec(ifreq).meanfiltY = bandpassfilter(calrec(ifreq).meanY,calibration_data.frequency_range(ifreq),calibration_data.frequency_range(ifreq),4);
        calrec(ifreq).meanfiltZ = bandpassfilter(calrec(ifreq).meanZ,calibration_data.frequency_range(ifreq),calibration_data.frequency_range(ifreq),4);

        %%% Pick window from which to draw sig data... use trig, and cut off ramp portions of sig
        wintrim = ceil(length(target(ifreq).stim)/winfact);
        calrec(ifreq).meanfiltwin = calrec(ifreq).meanfilt(calrec(ifreq).latsamps+wintrim:calrec(ifreq).latsamps+length(target(ifreq).stim)-wintrim);
        calrec(ifreq).meanfiltwinX = calrec(ifreq).meanfiltX(calrec(ifreq).latsamps+wintrim:calrec(ifreq).latsamps+length(target(ifreq).stim)-wintrim);
        calrec(ifreq).meanfiltwinY = calrec(ifreq).meanfiltY(calrec(ifreq).latsamps+wintrim:calrec(ifreq).latsamps+length(target(ifreq).stim)-wintrim);
        calrec(ifreq).meanfiltwinZ = calrec(ifreq).meanfiltZ(calrec(ifreq).latsamps+wintrim:calrec(ifreq).latsamps+length(target(ifreq).stim)-wintrim);
        calrec(ifreq).meanwin = calrec(ifreq).mean(calrec(ifreq).latsamps+wintrim:calrec(ifreq).latsamps+length(target(ifreq).stim)-wintrim);
        calrec(ifreq).meanwinX = calrec(ifreq).meanX(calrec(ifreq).latsamps+wintrim:calrec(ifreq).latsamps+length(target(ifreq).stim)-wintrim);
        calrec(ifreq).meanwinY = calrec(ifreq).meanY(calrec(ifreq).latsamps+wintrim:calrec(ifreq).latsamps+length(target(ifreq).stim)-wintrim);
        calrec(ifreq).meanwinZ = calrec(ifreq).meanZ(calrec(ifreq).latsamps+wintrim:calrec(ifreq).latsamps+length(target(ifreq).stim)-wintrim);
        myylim = get(gca,'ylim');
        sl1 = line([(calrec(ifreq).latsamps+wintrim)/fs (calrec(ifreq).latsamps+wintrim)/fs],myylim,'color','r');
        sl2 = line([(calrec(ifreq).latsamps+length(target(ifreq).stim)-wintrim)/fs (calrec(ifreq).latsamps+length(target(ifreq).stim)-wintrim)/fs],myylim,'color','r');
    end
    % compute RMS
    myrms(ifreq) = rms(calrec(ifreq).meanwin);
    
    %%% Now apply conversion factor... which depends on which "flavor" of
    %%% dB we want to employ
    myPa(ifreq) = myrms(ifreq)*HCP;
    
    
    %%% FOR ACCELROMETER IT'S MORE COMPLICATED ... NEED TO COMPUTE VECTOR
    %%% SUM ACROSS ALL 3 AXES ... WHILE ACCOUNTING FOR SENSITIVITY DIFFS
  %  <axis>= FF corr  * 1/ V per g ; % volts per g in x
    acceleration_amp_factor = 100;
    xCP = ((1/0.2044) * (1 / 0.1017)) / acceleration_amp_factor;
    yCP = ((1/0.2044) * (1 / 0.0984)) / acceleration_amp_factor;
    zCP = ((1/0.2044) * (1 / 0.1081)) / acceleration_amp_factor;
    
    
    xCP_2 = ((1/0.2044) * (1 / 0.01037)) / acceleration_amp_factor;
    yCP_2 = ((1/0.2044) * (1 / 0.01003)) / acceleration_amp_factor;
    zCP_2 = ((1/0.2044) * (1 / 0.01102)) / acceleration_amp_factor;
    
    Accel_sum = sqrt( (calrec(ifreq).meanwinX.*xCP).^2 + (calrec(ifreq).meanwinX.*yCP).^2 + (calrec(ifreq).meanwinX.*zCP).^2);
    calrec(ifreq).Accel_sum = Accel_sum;
    Accel_sum_2 = sqrt( (calrec(ifreq).meanwinX.*xCP_2).^2 + (calrec(ifreq).meanwinX.*yCP_2).^2 + (calrec(ifreq).meanwinX.*zCP_2).^2);
    calrec(ifreq).Accel_sum_2 = Accel_sum_2;
    % express as g...
    total_g(ifreq) = rms(Accel_sum); 
    % or as meters per microsec
    total_ms2(ifreq) = rms(Accel_sum_2);
    clear Accel_sum Accel_sum_2;
    
    % reference to 1 micro g
    mydB_microg(ifreq) = 20*log10(total_g(ifreq)/0.000001);
    % reference to 1 micro m / s2
    mydB_ms2(ifreq) = 20*log10(total_ms2(ifreq)/0.000001);
    
    % 
    mydB(ifreq) = 20*log10(myPa(ifreq)/0.000001);
    % update plot in GUI
    axes(main_ax);
    if isempty(calibration_data.correction_factors)
        plot(calibration_data.frequency_range(ifreq),mydB(ifreq),'ro-','markersize',6,'markerfacecolor','r','linewidth',1.5);
    else
        plot(calibration_data.frequency_range(ifreq),mydB(ifreq),'go-','markersize',6,'markerfacecolor','g','linewidth',1.5);
    end
    drawnow;
    pause(2);
end

if isempty(calibration_data.correction_factors)
    % Observed dB values are uncorrected
    cal_data.uncorrected_levels = mydB;
    % Add accelerometer data
    cal_data.uncorrected_levels_Accel_g = mydB_microg;
    cal_data.uncorrected_levels_Accel_ms2 = mydB_ms2;
    % And computing correction factors is very easy ... 
    cal_data.correction_factors = calibration_data.target_level - mydB;
    % Also save version that will not be displayed, scaling factor
    cal_data.correction_factors_sf = 10.^(cal_data.correction_factors./20);
    cal_data.meansigs = calrec;
else
    % values are already corrected, and correction factors are already known.
    cal_data.corrected_levels = mydB;
    % Add accelerometer data
    cal_data.corrected_levels_Accel_g = mydB_microg;
    cal_data.corrected_levels_Accel_ms2 = mydB_ms2;
    cal_data.meansigs_corrected = calrec;
    % save hydrophone correction factor 
    cal_data.HCP = HCP;
end

% Anything else?
debug=1;
