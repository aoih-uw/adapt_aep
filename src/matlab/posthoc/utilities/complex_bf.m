function logBF = complex_bf(x, g)
%COMPLEX_BF  Sequential evidence for a response at 2f, in log Bayes factor units.
%
%   Answers "is there a response here?" AND "is there definitely no response
%   here?" from one number, so data collection can stop early either way.
%   A standard F-test or bootstrap CI can only answer the first question.
%
% INPUTS
%   x  Complex FFT values at 2f, one per trial. These are the dots on the
%      polar plot: distance from origin = amplitude, angle = phase.
%   g  Smallest response you insist on being able to rule out, expressed as
%      single-trial power SNR. See "CHOOSING g" below.
%
% OUTPUT
%   logBF  Natural log of the Bayes factor = log of how many times more
%          probable your data are if a response exists vs if it does not.
%            +3.0  ->  BF = 20   evidence for a response
%             0.0  ->  BF = 1    data cannot distinguish the two
%            -2.3  ->  BF = 0.1  evidence AGAINST a response
%
% THE IDEA
%   Two competing stories about the cloud of dots:
%     H0 (no response)  the cloud's true center is the origin; it only drifts
%                       off-center by chance.
%     H1 (response)     the cloud's true center is somewhere off the origin,
%                       out to a distance set by g.
%   Compute how probable your actual dots are under each story, and divide.
%
% WHY IT CAN CONCLUDE "NOTHING HERE"
%   Chance drift of the average shrinks as trials accumulate. With no
%   response the cloud center shrinks along with it and stays inside, so
%   H0 keeps winning by a wider margin. With a real response the center sits
%   at a fixed distance and the shrinking drift abandons it, so H1 takes over.
%   Which story is pulling ahead is visible long before either is certain.
%
% CHOOSING g
%   Trials needed to reach a "no response" verdict is roughly 27/g.
%   g = 0.25 -> ~110 trials.  g = 0.01 -> ~2700 trials.
%   Set g from your own data: compute R at an amplitude with an obvious
%   response and pick g somewhere below it. Too small and the "no response"
%   boundary is unreachable within your trial budget.
%
% ASSUMES
%   Circular complex Gaussian noise (real and imaginary parts have equal
%   variance and are uncorrelated). Check by eye on the polar scatter of
%   stim-OFF trials: the cloud should look round, not elliptical. If it is
%   visibly elliptical, use a Hotelling T-squared formulation instead.
%
% SAFE TO CHECK REPEATEDLY
%   Under H0 this behaves like a fair betting game starting at $1, so the
%   chance of it ever reaching $20 is at most 1 in 20 no matter how often
%   you look. Unlike a p-value, peeking after every trial does not inflate
%   the false positive rate. Search terms: mSPRT, safe testing, e-values,
%   anytime-valid inference.

n = numel(x);

% Cloud center. A response shifts every trial in the same direction so it
% moves the center; noise pushes each trial a different way and cancels here.
xbar = mean(x);

% Signal-to-noise ratio, built from two summaries of the same trials:
%   numerator   abs(xbar)^2      power in the average -> carries the signal
%   denominator sum(|x-xbar|^2)  scatter about the center -> pure noise,
%                                since a constant response subtracts out
% The leading n puts them on the same footing: the average has already had
% its noise reduced n-fold, the scatter has not.
%
% R reads as "how many times more power is in my average than noise alone
% would put there". This is the ASSR F-statistic unscaled: F = (n-1)*R.
% Critically, R stays FLAT as n grows when there is no response (numerator
% and n cancel), but GROWS with n when there is one. That difference in
% behavior over n is what the whole test rests on.
R = n*abs(xbar)^2 / sum(abs(x - xbar).^2);

% Evidence = how much the response stands out, minus the bar it must clear.
%
%   -log(1+g*n)  THE BAR. Depends only on n, never on the data. H1 is the
%                more flexible story (the center can be anywhere), so it
%                fits any cloud slightly better even when the cloud is pure
%                noise. Spreading a fixed amount of probability over a wider
%                region thins it everywhere, and that thinning is the cost.
%                It grows with n because H0's region shrinks as trials
%                accumulate while H1's stays fixed. It rising over time is
%                also exactly what makes repeated peeking safe.
%
%   the rest     HOW MUCH IT STANDS OUT. Grows with R. For weak and moderate
%                responses this is approximately the F-statistic, so the
%                whole line reduces to:  logBF ~= F - log(1+g*n).
%
% log1p(z) computes log(1+z) accurately for small z. Under H0, R is around
% 1/n, and plain log(1+R) would lose precision at that magnitude.
logBF = -log(1+g*n) + n*(log1p(R) - log1p(R/(1+g*n)));