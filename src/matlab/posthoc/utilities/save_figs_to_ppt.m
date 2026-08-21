function save_figs_to_ppt(meta, outdir)
%SAVE_FIGS_TO_PPT Save all open figures as high-res PNGs and build a PPTX deck.
%   save_figs_to_ppt(meta)          -> writes into current folder
%   save_figs_to_ppt(meta, outdir)  -> writes into outdir
%
%   Windows only. Requires PowerPoint (uses COM automation).

if nargin < 2, outdir = pwd; end
if ~isfolder(outdir), mkdir(outdir); end
outdir = char(java.io.File(outdir).getCanonicalPath);

subjid = meta.subjid;
if isnumeric(subjid), subjid = num2str(subjid); else, subjid = char(subjid); end

expdate = meta.experiment_date;
if isnumeric(expdate), expdate = datestr(expdate); else, expdate = char(string(expdate)); end

if isfield(meta,'stim_freqs'), freqs = meta.stim_freqs; else, freqs = meta.stim_freq; end
if isfield(meta,'data_path'), datapath = char(meta.data_path); else, datapath = 'n/a'; end

% ---- Calling script provenance ----
st = dbstack;
if numel(st) > 1, scriptname = st(2).name; else, scriptname = 'base workspace'; end
scriptfile = which(scriptname);
if isempty(scriptfile)
    stamp = 'unknown';
else
    [gs, hash] = system(sprintf('git -C "%s" rev-parse --short HEAD', fileparts(scriptfile)));
    d = dir(scriptfile);
    if gs == 0, stamp = ['git ' strtrim(hash)]; else, stamp = ['modified ' d.date]; end
end

figs = findobj(groot,'Type','figure');
[~,si] = sort([figs.Number]);
figs = figs(si);

app = actxserver('PowerPoint.Application');
app.Visible = 1;
pres = app.Presentations.Add;
W = pres.PageSetup.SlideWidth;
H = pres.PageSetup.SlideHeight;

slides  = pres.Slides;
layouts = pres.SlideMaster.CustomLayouts;   % 1 = Title Slide, 7 = Blank

% ---- Title slide ----
lines = {sprintf('Experiment date: %s', expdate), ...
         sprintf('Tested frequencies: %s Hz', num2str(freqs(:).'))};
for i = 1:numel(freqs)
    a = meta.amp_vecs{i}(:).';
    d = unique(diff(a));
    if isscalar(d)
        astr = sprintf('%g:%g:%g', a(1), d, a(end));
    else
        astr = num2str(a);
    end
    lines{end+1} = sprintf('Tested amplitudes @ %g Hz: %s dB', freqs(i), astr); %#ok<AGROW>
end
lines{end+1} = sprintf('Source data: %s', datapath);
lines{end+1} = sprintf('MATLAB R%s', version('-release'));

s = slides.AddSlide(1, layouts.Item(1));
t = s.Shapes.Item(1).TextFrame.TextRange;
t.Text = sprintf('Subject %s', subjid);
t.Font.Name = 'Inter';
b = s.Shapes.Item(2).TextFrame.TextRange;
b.Text = strjoin(lines, char(13));
b.Font.Name = 'Inter';
b.Font.Size = 16;

% ---- One slide per figure ----
for i = 1:numel(figs)
    png = fullfile(outdir, sprintf('fig%02d.png', i));
    exportgraphics(figs(i), png, 'Resolution', 300, 'BackgroundColor', 'white');

    info  = imfinfo(png);
    scale = min((W-40)/info.Width, (H-40)/info.Height);
    w = info.Width*scale;
    h = info.Height*scale;

    s = slides.AddSlide(slides.Count+1, layouts.Item(7));
    s.Shapes.AddPicture(png, 0, -1, (W-w)/2, (H-h)/2, w, h);
end

pptfile = fullfile(outdir, sprintf('%s_figures_%s.pptx', subjid, datestr(now,'yyyymmdd')));
if isfile(pptfile), delete(pptfile); end
pres.SaveAs(pptfile);
pres.Close;
app.Quit;
delete(app);
fprintf('Saved %d figures and deck to %s\n', numel(figs), outdir);