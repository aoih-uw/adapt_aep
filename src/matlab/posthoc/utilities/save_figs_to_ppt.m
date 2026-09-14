function save_figs_to_ppt(varargin)
%SAVE_FIGS_TO_PPT Save all open figures as high-res PNGs and build a PPTX deck.
%   save_figs_to_ppt()
%   save_figs_to_ppt(outdir)
%   save_figs_to_ppt(outdir, titlestr)
%   save_figs_to_ppt(meta)
%   save_figs_to_ppt(meta, outdir)
%   save_figs_to_ppt(meta, outdir, titlestr)
%
%   Struct arg = meta; 1st string = outdir (use '' for current folder);
%   2nd string = title-slide heading. Title slide is made if either is given.
%   Windows only. Requires PowerPoint (uses COM automation).
meta = []; outdir = pwd; titlestr = ''; strs = {};
for k = 1:numel(varargin)
    a = varargin{k};
    if isstruct(a), meta = a;
    elseif ischar(a) || isstring(a), strs{end+1} = char(a); %#ok<AGROW>
    end
end
if numel(strs) >= 1 && ~isempty(strs{1}), outdir = strs{1}; end
if numel(strs) >= 2, titlestr = strs{2}; end
if ~isfolder(outdir), mkdir(outdir); end
outdir = char(java.io.File(outdir).getCanonicalPath);

figs = findobj(groot,'Type','figure');
if isempty(figs), fprintf('No open figures.\n'); return; end
[~,si] = sort([figs.Number]);
figs = figs(si);

app = actxserver('PowerPoint.Application');
app.Visible = 1;
pres = app.Presentations.Add;
W = pres.PageSetup.SlideWidth;
H = pres.PageSetup.SlideHeight;
slides  = pres.Slides;
layouts = pres.SlideMaster.CustomLayouts;   % 1 = Title Slide, 7 = Blank

% ---- Title slide (only if meta or titlestr given) ----
subjid = '';
if ~isempty(meta) && isfield(meta,'subjid')
    subjid = meta.subjid;
    if isnumeric(subjid), subjid = num2str(subjid); else, subjid = char(subjid); end
end
if ~isempty(meta) || ~isempty(titlestr)
    lines = {};
    if ~isempty(meta)
        if isfield(meta,'experiment_date')
            ed = meta.experiment_date;
            if isnumeric(ed), ed = datestr(ed); else, ed = char(string(ed)); end
            lines{end+1} = sprintf('Experiment date: %s', ed);
        end
        freqs = [];
        if isfield(meta,'stim_freqs'), freqs = meta.stim_freqs;
        elseif isfield(meta,'stim_freq'), freqs = meta.stim_freq; end
        if ~isempty(freqs)
            lines{end+1} = sprintf('Tested frequencies: %s Hz', num2str(freqs(:).'));
        end
        if ~isempty(freqs) && isfield(meta,'amp_vecs')
            for i = 1:numel(freqs)
                a = meta.amp_vecs{i}(:).';
                d = unique(diff(a));
                if isscalar(d), astr = sprintf('%g:%g:%g', a(1), d, a(end));
                else, astr = num2str(a); end
                lines{end+1} = sprintf('Tested amplitudes @ %g Hz: %s dB', freqs(i), astr); %#ok<AGROW>
            end
        end
        if isfield(meta,'data_path')
            lines{end+1} = sprintf('Source data: %s', char(meta.data_path));
        end
    end
    lines{end+1} = sprintf('MATLAB R%s', version('-release'));

    if ~isempty(titlestr), heading = titlestr;
    elseif ~isempty(subjid), heading = sprintf('Subject %s', subjid);
    else, heading = 'Figures';
    end
    s = slides.AddSlide(1, layouts.Item(1));
    t = s.Shapes.Item(1).TextFrame.TextRange;
    t.Text = heading;
    t.Font.Name = 'Inter';
    b = s.Shapes.Item(2).TextFrame.TextRange;
    b.Text = strjoin(lines, char(13));
    b.Font.Name = 'Inter';
    b.Font.Size = 16;
end

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

if ~isempty(titlestr), base = titlestr;
elseif ~isempty(subjid), base = subjid;
else, base = 'figures';
end
base = regexprep(base, '[\\/:*?"<>|]', '_');
pptfile = fullfile(outdir, sprintf('%s_%s.pptx', base, datestr(now,'yyyymmdd')));
if isfile(pptfile), delete(pptfile); end
pres.SaveAs(pptfile);
pres.Close;
app.Quit;
delete(app);
fprintf('Saved %d figures and deck to %s\n', numel(figs), pptfile);