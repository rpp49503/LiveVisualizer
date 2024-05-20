function MA_raw_tt = LoadMA_Visualizer(root,device_name,yn_recent,buffer)
% This function is used in the live visualizer script to load in just the
% raw data for the MA350.
%%
% Modify path to MA350 ambient data folder, depending on desired device.
if device_name == "UGA"
    root = strrep(root,"MultiPAS-IV","UGA_MA350_0334"); % Change folder path from PAS to TDCRD
elseif device_name == "WCU"
    root = strrep(root,"MultiPAS-IV","WCU_MA350_0268"); % Change folder path from PAS to TDCRD
else
    error('Specify which MA350 device to load as')
end

% Search folder for csv files
file_list = dir(fullfile(root,'*.csv')); % Search directory of folder elements
datenums = extractfield(file_list,'datenum'); % extract datenumbers from file list
% Statement changes loop iteration number for loading below
if yn_recent == 1
    [~,i] = max(datenums);
else
    i = 1:length(file_list);
end

% Create cell of data tables from folder
ma_cell{length(i),1} = zeros(length(i),1);
for k = i
    fnm_ma = strjoin({file_list(k).folder,file_list(k).name},buffer);
    opt = detectImportOptions(fnm_ma,"VariableNamingRule","modify");
    ma_cell{k,1} = readtable(fnm_ma,opt);
    ma_cell{k,1} = removevars(ma_cell{k,1},"DateLocal_yyyy_MM_dd_");
end

if yn_recent == 1
    MA_raw_tt = ma_cell{i};
else
    MA_raw_tt = vertcat(ma_cell{:}); % Concatenate tables
end

dates = datetime(MA_raw_tt.Date_TimeLocal,"TimeZone",'America/New_York',"Format","yyyy-MM-dd HH:mm:ss"); % Convert MA datetime to match PAS
MA_raw_tt = table2timetable(MA_raw_tt,"RowTimes",dates); 

% MA_raw_tt = rmmissing(MA_raw_tt);
% MA_raw_tt = sortrows(MA_raw_tt);

w = warning('query','last'); % Turn off warning for variablenames property.
id = w.identifier;
warning('off',id)

end