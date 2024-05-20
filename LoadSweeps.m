function [sweep_cells,sweep_vector] = LoadSweeps(root,yn_recent,buffer)
% This function loads in fequency sweep files for analysis in the data
% visualizer. Outputs are a table containing arrays of resonant frequencies
% for each PAS file in monthly folder, and an array with these cells
% concatenated for easier indexing.

file_list(:) = dir(fullfile(root,'**','pas.txt')); % compile file list
datenums = extractfield(file_list,'datenum'); % extract datenumbers from file list
% Statement changes loop iteration number for loading below
if yn_recent == 1
    [~,m] = max(datenums);
else
    m = 1:length(file_list);
end

ticker = 0; % Initialize position to save in cell
for n = m
        ticker = ticker+1; % Increase placeholder for final cell array
        root_s = strjoin({file_list(n).folder,'sweeps'},buffer); % Modify input path to sweep folder
        sweep_files = dir(fullfile(root_s,'*.txt')); % Directory of elements in sweep folder
        if isempty(sweep_files) 
            sweep_cells{ticker} = nan;
        else
            for i = 1:height(sweep_files) % Loop through sweep folder
                sweep_path = strjoin({sweep_files(i).folder,sweep_files(i).name},buffer); % Create path for each text file
                opt = detectImportOptions(sweep_path);
                opt.DataLines = [1,1]; % Only look at first line (resonant freq)
                freq = readmatrix(sweep_path,opt); % Load in resonant frequency
                sweep_freq(i) = freq(2); % Store frquency into array 
            end
            % varnames{ticker} = file_list(n).name; % Create variable names for each sweep folder
            sweep_cells{ticker} = sweep_freq'; % Store vectors into cell array
            sweep_freq = []; % Reset vector (error if not reset)
        end
end

% Create final vector/table
sweep_vector = vertcat(sweep_cells{:}); % Concatenate cell array into vector for second output
% sweep_cells = cell2table(sweep_cells,"VariableNames",varnames); % Format output into table containing frequency vectors

end