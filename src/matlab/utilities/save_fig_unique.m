function save_fig_unique(f, out_dir, name)
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
base = fullfile(out_dir, name);
n = 1; suf = '';
while exist([base suf '.fig'], 'file') || exist([base suf '.png'], 'file')
    n = n + 1;
    suf = ['_' num2str(n)];
end
savefig(f, [base suf '.fig']);
print(f, [base suf '.png'], '-dpng', '-r150');
close(f);
end