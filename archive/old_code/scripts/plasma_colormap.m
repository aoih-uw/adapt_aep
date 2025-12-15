

function cmap = plasma_colormap(n)
% PLASMA_COLORMAP Custom implementation of the plasma colormap
%   Returns an n-by-3 matrix containing the plasma colormap
%   If plasma is available as a built-in or from an add-on, it will use that,
%   otherwise it falls back to this custom implementation

% First try to use built-in or add-on plasma if available
try
    cmap = plasma(n);
    return;
catch
    % If that fails, use this custom implementation
end

% Define a simplified version of the plasma colormap
% These are key points from the plasma colormap
plasma_data = [
    0.050383, 0.029803, 0.527975;  % Dark purple
    0.254180, 0.013594, 0.615419;  % Purple
    0.417642, 0.000564, 0.654741;  % Medium purple
    0.562738, 0.028699, 0.646821;  % Light purple
    0.700389, 0.100441, 0.584207;  % Dark magenta
    0.816405, 0.198656, 0.489460;  % Magenta
    0.902325, 0.328552, 0.379806;  % Dark pink
    0.957873, 0.487552, 0.261660;  % Pink
    0.988491, 0.662018, 0.165693;  % Orange
    0.986755, 0.841528, 0.109473   % Yellow
];

% Use interpolation if we need a different size
x_in = linspace(0, 1, size(plasma_data, 1));
x_out = linspace(0, 1, n);
cmap = zeros(n, 3);

% Interpolate each color channel
for i = 1:3
    cmap(:, i) = interp1(x_in, plasma_data(:, i), x_out, 'pchip');
end

% Ensure the colormap is within [0,1] bounds
cmap = max(0, min(1, cmap));
end