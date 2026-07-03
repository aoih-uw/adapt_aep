function safe_ylim(ax, lo, hi)
% Robust ylim: tolerate NaN/Inf/empty/degenerate bounds without erroring.
    if isempty(lo) || isempty(hi) || ~isfinite(lo) || ~isfinite(hi)
        ylim(ax, 'auto');            % nothing valid to bound yet
        return
    end
    if hi <= lo                      % single point / flat data
        pad = max(abs(hi) * 0.05, eps);
        lo = lo - pad;
        hi = hi + pad;
    end
    ylim(ax, [lo, hi]);
end