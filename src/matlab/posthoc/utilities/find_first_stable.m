function [resp_first, resp_stable, inconsist_count] = find_first_stable(cur_data, n_filled,max_trials,trials_per_block)
%% First response = find('first'); Stable response is find('last')
% Takes in vector of 0s and 1s indicating when a response was found
% Find the first resp_found
% Setup variables
resp_first = NaN; resp_stable = NaN; 

% Find first present response
first_resp = find(cur_data == 1,1,'first');
if isempty(n_filled)
    fprintf('There are NaNs in resp_found vectors\n') % all NaN
    % boot_first(ichan,iamp,ii,iii) = NaN;
elseif isempty(first_resp)            % No response at any point
    resp_first = max_trials;
else
    resp_first = first_resp*trials_per_block;
end

% Find the last stable resp_found batch
last_no_resp = find(cur_data == 0,1,'last');
if isempty(n_filled)                    % all NaN
    fprintf('There are NaNs in resp_found vectors\n') % all NaN
elseif isempty(last_no_resp)            % never a no-response
    resp_stable = trials_per_block;
elseif last_no_resp == n_filled         % final filled batch still no-response
    resp_stable = max_trials;
else
    resp_stable = (last_no_resp+1)*trials_per_block;
end

% Count N inconsistent decision
inconsist_count = any(diff(cur_data(:)) == -1);
end