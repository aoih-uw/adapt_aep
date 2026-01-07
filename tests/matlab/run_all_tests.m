function results = run_all_tests()
    % Add src to path
    srcPath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'src');
    addpath(genpath(srcPath));
    
    % This automatically finds ALL test files in tests/ and subfolders
    suite = testsuite('tests');
    results = run(suite);
    
    % Clean up
    rmpath(genpath(srcPath));
end