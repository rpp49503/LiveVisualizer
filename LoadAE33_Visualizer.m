function [AE33_TT,AE33_log,AE33_setup,Settings] = LoadAE33_Visualizer(root,Settings,buffer,yn_recent)
% This function performs all initial loading functions of raw, AE33 .DAT
% data and log files from monthly folder selected in
% MASTER_Ambient_Visualizer script.

% Loading files from modified PAS path
root_AE33 = strrep(root,"MultiPAS-IV","AE33");

%% Change loop parameters if only loading most recent data.
dfull = dir(root_AE33); % Find all files in folder
dxml = dir(fullfile(root_AE33,'*.XML')); % Directory for XML files
d = dir(fullfile(root_AE33,'*.dat')); % Find all .dat files
tick = 0; % Indexing for log directory entry
for n = 1:length(d) % Loop to store log files in separate directory
    if strcmp(d(n).name(1:8),'AE33_log') == 1
        tick = tick+1;
        dlog(tick) = d(n); % Store log in new directory
    else
        ddat(n) = d(n); % Store data entries in separate directory
    end
end

% Check that directories for each are not empty, if so, do not execute in
% recent file only loop.
if exist("ddat","var")
    Settings.e_dat = 1;
else
    Settings.e_dat = 0;
end
if exist("dlog","var")
    Settings.e_log = 1;
else
    Settings.e_log = 0;
end
if ~isempty(dxml)
    Settings.e_setup = 1;
else
    Settings.e_setup = 0;
end

% Statement changes loop iteration number for loading below
if yn_recent == 1

    if Settings.e_dat == 1
        [~,i] = max(extractfield(ddat,'datenum')); % Find largest datenumber, corresponding to most recent file
        file = string(d(i).folder) + buffer + string(d(i).name); % combine folder path and file name for full path.
        opts = detectImportOptions(file,'VariableNamesLine',6); % Get .DAT file info and specify where variable names are.
        opts.DataLines = [13,inf]; % Define what line in .DAT file data begins.
        warning('off','MATLAB:table:ModifiedAndSavedVarnames') % Turn column header command line warning off.
        T_raw = readtable(file,opts); % Load AE33 data into table.
        dates = string(T_raw.Date_yyyy_MM_dd__); % Convert dates and times to strings.
        times = string(T_raw.Time_hh_mm_ss__);
        date_time = dates + times; % Merge dates and times.
        date_time = datetime(date_time,InputFormat="yyyy/MM/ddHH:mm:ss",Format="yyyy/MM/dd HH:mm:ss"); % Convert time string to datetimes for timetable.
        AE33_TT = table2timetable(T_raw(:,3:end),'RowTimes',date_time); % Create timetable from raw data and datetimes.
    else
        AE33_TT = timetable();
    end

    if Settings.e_log == 1
        [~,k] = max(extractfield(dlog,'datenum'));
        file = string(dlog(k).folder) + buffer + string(dlog(k).name); % Combine folder path and file name for full path.
        opts = detectImportOptions(file,'ConsecutiveDelimitersRule','join'); % Information about file being loaded.
        opts.DataLines = [1,inf]; % Specify where data is loacted in .DAT file.
        opts.SelectedVariableNames = {'Var1','Var2'};
        opts.VariableTypes{1} = 'datetime'; % Specify variable types of log data for consistency
        opts.VariableTypes{2} = 'char';
        opts.VariableOptions(1,1).DatetimeFormat = 'yyyy/MM/dd HH:mm:ss'; % Specify datetime format for consistency
        AE33_log = readtimetable(file,opts); % Load AE33 log file as timetable and append
        Settings.e_log = 1;
    else
        AE33_log = timetable();
    end

    if Settings.e_setup == 1
        [~,j] = max(extractfield(dxml,'datenum'));
        file = string(dxml(j).folder) + buffer + string(dxml(j).name); % Combine folder path and file name for full path.
        AE33_setup{1} = readstruct(file); % Store AE setup as a strucutre of variables
        Settings.e_setup = 1;
    else
        AE33_setup = {};
    end

else % Condition if not loading most recent
    AE33_TT = timetable(); % Set final timetable as empty for appending in the loop.
    AE33_log = timetable();
    w = waitbar(0,'Importing AE33 data'); % Waitbar for loading
    holder = 0; % For indexing AE_setup structure if mulitple are present
    for n = 1:length(dfull) % Loop for each file within folder directory.
        if dfull(n).isdir == 1 % Ignore blank entries or extra folders.
        elseif strcmp(dfull(n).name(end-3:end),'.XML') == 1 % See if there is an AE33 setup file containing instrument settings, which will be a .XML file.
            holder = holder + 1; % Increase for indexing
            file = string(dfull(n).folder) + buffer + string(dfull(n).name); % Combine folder path and file name for full path.
            AE33_setup{holder} = readstruct(file); % Store AE setup as a strucutre of variables
            Settings.e_setup = 1;
        elseif strcmp(dfull(n).name(end-3:end),'.dat') == 1 % Make sure file is .DAT
            if strcmp(dfull(n).name(1:8),'AE33_log') == 1 % Loop to pull out log file data into timetable
                file = string(dfull(n).folder) + buffer + string(dfull(n).name); % Combine folder path and file name for full path.
                opts = detectImportOptions(file,'ConsecutiveDelimitersRule','join'); % Information about file being loaded.
                opts.DataLines = [1,inf]; % Specify where data is loacted in .DAT file.
                opts.SelectedVariableNames = {'Var1','Var2'};
                opts.VariableTypes{1} = 'datetime'; % Specify variable types of log data for consistency
                opts.VariableTypes{2} = 'char';
                opts.VariableOptions(1,1).DatetimeFormat = 'yyyy/MM/dd HH:mm:ss'; % Specify datetime format for consistency
                AE33_log = [AE33_log ; readtimetable(file,opts)]; % Load AE33 log file as timetable and append
                Settings.e_log = 1;
            elseif  strcmp(dfull(n).name(1:9),'AE33_AE33') == 1 % Loop to pull out data from correct files
                file = string(dfull(n).folder) + buffer + string(dfull(n).name); % combine folder path and file name for full path.
                opts = detectImportOptions(file,'VariableNamesLine',6); % Get .DAT file info and specify where variable names are.
                opts.DataLines = [13,inf]; % Define what line in .DAT file data begins.
                warning('off','MATLAB:table:ModifiedAndSavedVarnames') % Turn column header command line warning off.
                T_raw = readtable(file,opts); % Load AE33 data into table.
                dates = string(T_raw.Date_yyyy_MM_dd__); % Convert dates and times to strings.
                times = string(T_raw.Time_hh_mm_ss__);
                date_time = dates + times; % Merge dates and times.
                date_time = datetime(date_time,InputFormat="yyyy/MM/ddHH:mm:ss",Format="yyyy/MM/dd HH:mm:ss"); % Convert time string to datetimes for timetable.
                TT_hold = table2timetable(T_raw(:,3:end),'RowTimes',date_time); % Create timetable from raw data and datetimes.
                AE33_TT = [AE33_TT;TT_hold]; % Append data from this loop to timetable.
            end
        end % End loop for ignoring extra entries or folders in directory
        waitbar(n/height(dfull),w) % Update wait bar based on loop iteration
    end % End loop for all entries in directory.
    
end

%% Formattting raw, concatenated timetable. Columns for each variable are ordered as: 370, 470, 520, 590, 660, 880, and 950 nm.
AE33_TT = mergevars(AE33_TT,["RefCh1_","RefCh2_","RefCh3_","RefCh4_","RefCh5_","RefCh6_","RefCh7_"],"NewVariableName",'Ref'); % Reference signal for each channel
AE33_TT = mergevars(AE33_TT,["Sen1Ch1_","Sen1Ch2_","Sen1Ch3_","Sen1Ch4_","Sen1Ch5_","Sen1Ch6_","Sen1Ch7_"],"NewVariableName","Sensor1"); % Intensities for spot 1 at all wavelengths
AE33_TT = mergevars(AE33_TT,["Sen2Ch1_","Sen2Ch2_","Sen2Ch3_","Sen2Ch4_","Sen2Ch5_","Sen2Ch6_","Sen2Ch7_"],"NewVariableName","Sensor2"); % Intensities for spot2 at all wavelengths.
AE33_TT = mergevars(AE33_TT,["BC11_","BC21_","BC31_","BC41_","BC51_","BC61_","BC71_"],"NewVariableName","BC1"); % BC1 (spot one) uncompensated concentrations
AE33_TT = mergevars(AE33_TT,["BC12_","BC22_","BC32_","BC42_","BC52_","BC62_","BC72_"],"NewVariableName","BC2"); % BC2 (spot two) uncompensated concentrations
AE33_TT = mergevars(AE33_TT,["BC1_","BC2_","BC3_","BC4_","BC5_","BC6_","BC7_"],"NewVariableName","BCC1"); % Compensated BC1 concentrations
AE33_TT = mergevars(AE33_TT,["K1_","K2_","K3_","K4_","K5_","K6_","K7_"],"NewVariableName","K_weight"); % Weighted compensation parameter
AE33_TT = renamevars(AE33_TT,["Timebase_","Flow1_","Flow2_","TapeAdvCount_"],["Timebase","Flow1","Flow2","TapeCount"]);

if Settings.e_log == 1 && height(AE33_log) >= 7 % This ensures that logs are present and that they contain ATN zeros.
    AE33_log.Properties.DimensionNames{1}='Time'; % Rename "Var1" to "Time".
    AE33_log = renamevars(AE33_log,"Var2","Message");
else
    fprintf(2,"Log files with ATN zeros not present. ATN on spot 2 cannot be calculated. All other properties that do not depend on ATN 2 will be calculated. \nOther variables will be added as columns of zeros or 'NaN' \n")
    AE33_log = timetable();
    Settings.e_log = 0; % Make sure flag is switched, if logs were present but not long enough (do not contain ATN zeros).
end

%% Compare defined settings and settings from AE setup file

if Settings.e_setup == 1
    for n = 1:length(AE33_setup)
        if AE33_setup{n}.C ~= Settings.C  
            fprintf(2,"Scattering correction (C) value from AE33 setup value does not match input above. Verify correct input value before proceeding")
        elseif AE33_setup{n}.Zeta ~= Settings.Z
            fprintf(2,"Leakage correction (Z) value from AE33 setup value does not match input above. Verify correct input value before proceeding")
        elseif AE33_setup{n}.AtnMAX ~= Settings.ATN_TA
            fprintf(2,"Attenuation threshold (ATN_TA) value from AE33 setup value does not match input above. Verify correct input value before proceeding")
        elseif AE33_setup{n}.ATNf2 ~= Settings.ATN_f2
            fprintf(2,"ATN_f2 value from AE33 setup value does not match input above. Verify correct input value before proceeding")
        elseif AE33_setup{n}.Area ~= Settings.S
            fprintf(2,"Spot area (S) value from AE33 setup value does not match input above. Verify correct input value before proceeding")
        elseif AE33_setup{n}.TAtype ~= 1
            fprintf(2,"Tape advance not set to threshold value. Parameters for ATN_TA changed.")
        end
    end
else
    AE33_setup = {};
end

close(w) % Close waitbar
end % End of function