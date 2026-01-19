function varargout = mock_playrec(varargin)

persistent mock_data;
    switch varargin{1}
        case 'playrec'
            varargout{1} = 1;
            stimulus = varargin{2};
            input_channels = varargin{5};
            
            % Use separate function to generate mock data
            mock_data = generate_mock_playrec_data(stimulus, input_channels);
            
        case 'block'
        case 'getRec'
            varargout{1} = mock_data;
        case 'delPage'
            mock_data = [];
    end
end