function [SMPS_raw_tt,Diams] = LoadSMPS_Visualizer(root,root_start,yn_recent,buffer)
% This function loads in data from the SMPS in the corresponding monthly
% folder for the live visualizer script

warning('off','MATLAB:table:ModifiedAndSavedVarnames')
root_smps = strrep(root,"MultiPAS-IV","SMPS"); % Change path from PAS to CRD folder
file_list = dir(fullfile(root_smps,'*.txt')); % Get directory of folder elements
datenums = extractfield(file_list,'datenum'); % extract datenumbers from file list
% Statement changes loop iteration number for loading below
if yn_recent == 1
    [~,i] = max(datenums);
else
    i = 1:length(file_list);
end

% Create cell of data tables from folder
smps_cell{length(i),1} = zeros(length(i),1);
for k = i
    fnm_smps = strjoin({file_list(k).folder,file_list(k).name},buffer);
    opts = detectImportOptions(fnm_smps,'VariableNamesLine',16); % Load file info
%     opts.SelectedVariableNames = {'Date','StartTime','Median_nm_','TotalConc____cm__'};
    opts.DataLines = [17 inf]; % Specify which rows of data to read
    opts.VariableTypes(2) = {'datetime'};
    smps_cell{k,1} = readtable(fnm_smps,opts);
end

if yn_recent == 1
    tbl = smps_cell{i};
else
    tbl = vertcat(smps_cell{:}); % Concatenate tables
end

% Reformat timetable for export
dt = tbl.Date + tbl.StartTime;
dt.Format="yyyy-MM-dd HH:mm:ss";
SMPS_raw_tt = table2timetable(tbl,'RowTimes',dt);
SMPS_raw_tt = removevars(SMPS_raw_tt,{'Date','StartTime','Sample_','DiameterMidpoint'});
load(root_start + buffer + 'MATLAB' + buffer + 'SMPS' + buffer + 'Diameter_midpoints.mat',"Diams") % Load variable containing all diameters in nm
SMPS_raw_tt.Properties.VariableNames(1:107) = string(Diams); % Change variables names to diameter values in nm

end

