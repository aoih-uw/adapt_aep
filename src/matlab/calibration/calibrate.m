function varargout = calibrate(calibration_data)
% CALIBRATE MATLAB code for calibrate.fig
%      CALIBRATE, by itself, creates a new CALIBRATE or raises the existing
%      singleton*.
%
%      H = CALIBRATE returns the handle to a new CALIBRATE or the handle to
%      the existing singleton*.
%
%      CALIBRATE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CALIBRATE.M with the given input arguments.
%
%      CALIBRATE('Property','Value',...) creates a new CALIBRATE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before calibrate_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to calibrate_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help calibrate

% Last Modified by GUIDE v2.5 12-Jun-2015 13:32:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @calibrate_OpeningFcn, ...
                   'gui_OutputFcn',  @calibrate_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before calibrate is made visible.
function calibrate_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to calibrate (see VARARGIN)

% Choose default command line output for calibrate
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes calibrate wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = calibrate_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

movegui(hObject,'northwest');
% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in butt_calibrate_now.
function butt_calibrate_now_Callback(hObject, eventdata, handles)
global calibration_data

% Make sure check calibration is disabled since we will be getting new correction vals
set(handles.butt_go_check_calibration,'Enable','off');

% Fill disp fields in the GUI... bit different if we're using clicks
if calibration_data.useclicks
    set(handles.disp_frequency_range,'String','Using clicks...');
    set(handles.disp_stimulus_duration,'String','1 ms biphasic pulse...');
    set(handles.disp_target_level,'String',num2str(calibration_data.target_level));
    set(handles.disp_uncorrected_levels,'String','Waiting...');
    set(handles.disp_correction_factors,'String','Waiting...');
    set(handles.disp_corrected_levels,'String','-');
else
    freq_str = sprintf('%.0f, ', calibration_data.frequency_range);
    freq_str = freq_str(1:end-2); % remove trailing comma and space
    set(handles.disp_frequency_range,'String',freq_str);
    set(handles.disp_stimulus_duration,'String',num2str(calibration_data.stimulus_duration));
    set(handles.disp_target_level,'String',num2str(calibration_data.target_level));
    set(handles.disp_uncorrected_levels,'String','Waiting...');
    set(handles.disp_correction_factors,'String','Waiting...');
    set(handles.disp_corrected_levels,'String','-');
end

% Let user know we are calibrating
fprintf('\nCalibrating ...\n');

% Format data plot axes
cax = handles.calibration_data_ax; tax = handles.disp_tone_ax;
axes(cax); cla; hold on;
if length(calibration_data.frequency_range)== 1
    myxlim = [min(calibration_data.frequency_range)-1 max(calibration_data.frequency_range)+1];
    set(gca,'ytick',calibration_data.target_level,'xtick',calibration_data.frequency_range,...
        'xlim',myxlim,'ylim',[80 150],'ytick',80:10:150,'fontsize',8,'fontweight','bold');
    xlabel('Frequency (Hz)','Fontweight','bold','Fontsize',10);  
elseif calibration_data.useclicks
%     myxlim = [calibration_data.frequency_range(1)-1 calibration_data.frequency_range(1)+1];
    % hard code axis... only 1 data point, so we will set limit at [0 2]
    myxlim = [0 2];
    set(gca,'ytick',calibration_data.target_level,'xtick',1,'xticklabel','Click',...
        'xlim',myxlim,'ylim',[80 150],'ytick',80:10:150,'fontsize',8,'fontweight','bold');
else
    myxlim = [min(calibration_data.frequency_range) max(calibration_data.frequency_range)];
    set(gca,'ytick',calibration_data.target_level,'xtick',calibration_data.frequency_range,...
        'xlim',myxlim,'ylim',[80 150],'ytick',80:10:150,'fontsize',8,'fontweight','bold');
    xlabel('Frequency (Hz)','Fontweight','bold','Fontsize',10);  
end
line(myxlim,[calibration_data.target_level calibration_data.target_level],'linestyle','--','color','k');
ylabel('Level (dB SPL Re: 1 \muPa)','Fontweight','bold','Fontsize',10);

% Format running signal plot axis
axes(tax); cla; hold on;
if strcmp(calibration_data.experiment,'Stereo AM');
    line([0 calibration_data.stimulus_duration],[0 0],'linestyle','--','color','k');
    set(gca,'xlim',[0 calibration_data.stimulus_duration],'xtick',0:0.1:calibration_data.stimulus_duration,...
        'fontsize',8,'fontweight','bold');
else
    line([0 1],[0 0],'linestyle','--','color','k');
    set(gca,'xlim',[0 1],'xtick',0:0.1:1,...
        'fontsize',8,'fontweight','bold');
end
ylabel('Voltage (0.1V/Pa)','Fontweight','bold','Fontsize',10);
xlabel('Time (s)','Fontweight','bold','Fontsize',10);  

%% Call main calibration function without correction factors (not yet determined), or intentionally being redetermined...
calibration_data.correction_factors = [];
if strcmp(calibration_data.experiment,'Stereo AM');
    cal_data = calibration_main_2ch(cax,tax,calibration_data);
else
    cal_data = calibration_main(cax,tax,calibration_data);
end

%% Update GUI 
% With calibration data ... round so that display is clean.
set(handles.disp_uncorrected_levels,'String',num2str(ceil(cal_data.uncorrected_levels)));
set(handles.disp_correction_factors,'String',num2str(ceil(cal_data.correction_factors)));

%% Save calibration_data 
%(redundant with calibration_main, but that's ok)
calibration_data.uncorrected_levels = cal_data.uncorrected_levels;
calibration_data.correction_factors = cal_data.correction_factors;
calibration_data.correction_factors_sf = cal_data.correction_factors_sf;
calibration_data.meansigs = cal_data.meansigs;
fprintf('\nInitial calibration complete.\nNow click CHECK CALIBRATION to verify corrections.\n');
msgbox('Calibration complete. You must click CHECK CALIBRATION to verify calibration, or click CALIBRATE again to start over','Check calibration!','warn');
set(handles.butt_go_check_calibration,'Enable','on');
set(handles.butt_go_check_calibration','Backgroundcolor','g');

%% Check calibration: butt_go_check_calibration
function butt_go_check_calibration_Callback(hObject, eventdata, handles)
global calibration_data
global ghandles

set(handles.disp_corrected_levels,'String','Waiting...');
fprintf('\nChecking calibration ...\n');

% Plot axes formatting
cax = handles.calibration_data_ax; tax = handles.disp_tone_ax;
axes(cax); cla; hold on;
myxlim = [min(calibration_data.frequency_range)-1 max(calibration_data.frequency_range)+1];
set(gca,'ytick',calibration_data.target_level,'xtick',calibration_data.frequency_range,...
    'xlim',myxlim,'ylim',[80 150],'ytick',80:10:150,'fontsize',8,'fontweight','bold');
ylabel('Level (dB SPL Re: 1 uPa)','Fontweight','bold','Fontsize',10);
xlabel('Frequency (Hz)','Fontweight','bold','Fontsize',10);   
line(myxlim,[calibration_data.target_level calibration_data.target_level],'linestyle','--','color','k');

% Format running signal plot axis
axes(tax); cla; hold on;
if strcmp(calibration_data.experiment,'Stereo AM');
    line([0 calibration_data.stimulus_duration],[0 0],'linestyle','--','color','k');
    set(gca,'xlim',[0 calibration_data.stimulus_duration],'xtick',0:0.1:calibration_data.stimulus_duration,...
        'fontsize',8,'fontweight','bold');
else
    line([0 1],[0 0],'linestyle','--','color','k');
    set(gca,'xlim',[0 1],'xtick',0:0.1:1,...
        'fontsize',8,'fontweight','bold');
end
ylabel('Voltage (0.1V/Pa)','Fontweight','bold','Fontsize',10);
xlabel('Time (s)','Fontweight','bold','Fontsize',10);  

% Call main calibration function again
% correction factors etc now known...
if strcmp(calibration_data.experiment,'Stereo AM');
    cal_data = calibration_main_2ch(cax,tax,calibration_data);
else
    cal_data = calibration_main(cax,tax,calibration_data);
end
cal_data.fishID = ghandles.edit_fish_ID.Value;

% Update GUI field 
set(handles.disp_corrected_levels,'String',num2str(ceil(cal_data.corrected_levels)));

% Save into calibration_data
calibration_data.corrected_levels = cal_data.corrected_levels;
calibration_data.meansigs_corrected = cal_data.meansigs_corrected;
calibration_data.HCP = cal_data.HCP;
% Check for deviation from target level...

% How much deviation will we tolerate?
devtol = 5; % in dB
if max(calibration_data.corrected_levels - calibration_data.target_level) > devtol
    warndlg('Calibration not successful; levels have shifted. Check equipment and try again','Calibration check failed...');
    set(handles.butt_go_check_calibration,'BackgroundColor','r');
    set(handles.butt_go_check_calibration,'Enable','off');    
    success = 0;
else
    success = 1;
end

%% If successful, inform user and enable experiment start button.
if success
    set(ghandles.butt_go_calibrate,'Enable','off');
    set(ghandles.butt_go_calibrate,'Text','SUCCESS!');
    set(ghandles.butt_go,'Enable','on');
    set(ghandles.butt_go,'BackgroundColor','g');
    
    % save calibration to .mat file
    cwd=pwd;
    cd('C:\Users\AEP\Desktop\Experiments\adaptiveAEP_2025\calibration\calibrationData');
    % get timestamp
    c = clock;
    datecode = sprintf('%.2d%.2d%.2d',rem(c(1),100),c(2),c(3),c(4),c(5));
    savestr = sprintf('Calibration_%s_%s.mat',cal_data.fishID,datecode);
    cal_data = calibration_data;
    save(savestr,'cal_data','-v7.3');
    msgbox('Calibration was successful. Close calibration window to begin AEP experiment.','Success!');
    fprintf('\nCalibration successful. Saved data to %s\n',savestr);
    cd(cwd);
end

%% Load calibration file: butt_go_load_calibration_Callback.
function butt_go_load_calibration_Callback(hObject, eventdata, handles)
global calibration_data
global ghandles

% Navigate to signal_calibration files
script_dir = fileparts(mfilename('fullpath'));
cal_path = fullfile(script_dir, '..', '..', 'data', 'signal_calibration');

% Open file dialog in that directory
[fname, pathname] = uigetfile(fullfile(cal_path, '*.mat'), 'Select a calibration file');

if ~isequal(fname, 0)
    load(fullfile(pathname, fname));
    calibration_data = cal_data;
end

%% Update GUI
freq_str = sprintf('%.0f, ', ceil(calibration_data.frequency_range));
freq_str = freq_str(1:end-2); % remove trailing comma and space
set(handles.disp_frequency_range,'String',freq_str);
set(handles.disp_target_level,'String',num2str(ceil(calibration_data.target_level)));
set(handles.disp_uncorrected_levels,'String',num2str(ceil(calibration_data.uncorrected_levels)));
set(handles.disp_correction_factors,'String',num2str(ceil(calibration_data.correction_factors)));
set(handles.disp_corrected_levels,'String',num2str(ceil(calibration_data.corrected_levels)));

% Format data plots
myax = handles.calibration_data_ax;
axes(myax); cla; hold on;
myxlim = [min(calibration_data.frequency_range-5) max(calibration_data.frequency_range)+5];
set(gca,'ytick',calibration_data.target_level,'xtick',calibration_data.frequency_range,...
    'xlim',myxlim,'ylim',[80 150],'ytick',50:10:150,'fontsize',8,'fontweight','bold');
ylabel('Level (dB SPL Re: 1 uPa)','Fontweight','bold','Fontsize',10);
xlabel('Frequency (Hz)','Fontweight','bold','Fontsize',10);   
line(myxlim,[calibration_data.target_level calibration_data.target_level],'linestyle','--','color','k');  

axes(handles.disp_tone_ax); cla; hold on;
text(0.2,0.5,'Data loaded from previous calibration....','units','normalized','color','k');

plot(calibration_data.frequency_range,calibration_data.uncorrected_levels,'ro-','markersize',6,'markerfacecolor','r','linewidth',1.5);
plot(calibration_data.frequency_range,calibration_data.corrected_levels,'go-','markersize',6,'markerfacecolor','g','linewidth',1.5);

% Inform user that previous calibration was loaded, prompt to double-check
msgbox('Previous calibration loaded successfully. Make sure you have loaded the correct file, then close the calibration window to begin the experiment. ','Success!');
% set(ghandles.butt_go_calibrate,'Enable','off');
set(ghandles.butt_go_calibrate,'Text','SUCCESS!');
set(ghandles.butt_go,'Enable','on');
set(ghandles.butt_go,'BackgroundColor','g');
    
fprintf('\nLoaded previous calibration file, %s\n Be sure this is the correct file.\n',fname);
