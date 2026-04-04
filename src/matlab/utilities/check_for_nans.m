function check_for_nans(input_var,data_type)

if isempty(input_var)
    keyboard
end

switch data_type
    case 'signal'
        % Check if there is a whole row of NaNs
        if any(all(isnan(input_var),2))
            keyboard
        end
        % Check if there is a whole column of NaNs between 2 columns that
        % are not
        nan_cols = all(isnan(input_var),1);
        non_nan_idx = find(~nan_cols);
        % Is the first column of this matrix all NaNs?
        if nan_cols(1) == 1
            keyboard
        end
        % Are there any full colums of NaNs that are between two columns of
        % values?
        if ~isempty(non_nan_idx)
            sandwiched = nan_cols & (1:size(input_var,2)) > non_nan_idx(1) & ...
                         (1:size(input_var,2)) < non_nan_idx(end);
            if any(sandwiched)
                keyboard
            end
        end
case 'variable'
    if any(isnan(input_var))
        keyboard
    end
end