% save_svg
cur_d = cd;
dest_d = 'C:\Users\Aoi Hunsaker\Downloads';

cd(dest_d)
figs = findall(0, 'Type', 'figure');
for i = 1:numel(figs)
    print(figs(i), sprintf('figure_%d', i), '-dsvg');
end

cd(cur_d)