function [bootstat, lower_CI, upper_CI] = calculate_bootstrap(ex, selected_vector)
n_bootstrap = ex.info.analysis.n_bootstrap;
if iscell(selected_vector)
    selected_vector = selected_vector{:};
end
% Bootstrap!
fprintf('\nStarting bootstrap calculation...\n')
tic()
bootstat = bootstrp(n_bootstrap,@mean,selected_vector);
time_elapsed = toc();
fprintf('\nBootstrap calculation time: %.3f\n', time_elapsed);

%% Calculate 99% CI
lower_CI = prctile(bootstat, 0.5);
upper_CI = prctile(bootstat, 99.5);

end