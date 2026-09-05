function plot_logBF(cumu, amp_vec, my_chans, my_chans_name, cur_freq)
up = log(20); lo = -log(10);
for ichan = 1:length(my_chans)
    figure;
    tiledlayout(5,4,'Padding','tight','TileSpacing','tight');
    for iamp = 1:length(amp_vec)
        nexttile; hold on;
        n      = cumu.n(:,iamp,ichan);
        lb_on  = cumu.logBF_ON(:,iamp,ichan);
        lb_off = cumu.logBF_OFF(:,iamp,ichan);

        plot(n, lb_off, '-', 'Color', [.7 .7 .7]);
        plot(n, lb_on,  '-', 'Color', tableau_10('blue'));
        yline(up, '--', 'Color', tableau_10('green'));
        yline(lo, '--', 'Color', tableau_10('red'));

        k = find(lb_on > up, 1);
        if ~isempty(k), scatter(n(k), lb_on(k), 50, tableau_10('green'), 'filled'); end
        k = find(lb_on < lo, 1);
        if ~isempty(k), scatter(n(k), lb_on(k), 50, tableau_10('red'), 'filled'); end

        title(sprintf('%d dB', amp_vec(iamp)));
        xlabel('N trials in average'); ylabel('log BF');
    end
    sgtitle(sprintf('%d Hz; Channel: %s', cur_freq, my_chans_name{ichan}));
end