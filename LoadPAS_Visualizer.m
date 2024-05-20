function [pas_dat] = LoadPAS_Visualizer(root,yn_recent,buffer)
% This function loads pas data based on the root from the network drive,
% and a selection to load only the most recent data file.
%% get raw table
file_list(:) = dir(fullfile(root,'**','pas.txt')); % compile file list
datenums = extractfield(file_list,'datenum'); % extract datenumbers from file list
% Statement changes loop iteration number for loading below
if yn_recent == 1
    [~,i] = max(datenums);
else
    i = 1:length(file_list);
end

% Create cell of data tables from folder. Currently does not load in laser temperatures from text file
pas_cell{length(file_list),1} = zeros(length(file_list),1);
for k = 1:length(file_list)
    fnm_pas = strjoin({file_list(k).folder,'pas.txt'},buffer);
    opts_pas = detectImportOptions(fnm_pas,'VariableNamingRule','preserve');
    opts_pas.VariableNames = {'Time','micCh1_mV','micCh2_mV','micCh3_mV','micCh4_mV','pdCh1_mV','pdCh2_mV','pdCh3_mV','pdCh4_mV','tau_sec','babsCh1_Mm','babsCh2_Mm','babsCh3_Mm','babsCh4_Mm','bext_Mm','fres_Hz','filter_state','elapsedTime_min','405_Temp','532_Temp','662_Temp','785_Temp','mic_cal'};
    opts_pas = opts_pas.setvartype(["405_Temp","532_Temp","662_Temp","785_Temp"],"double");

    if  length(opts_pas.VariableTypes{2}) == 8 % Change variable options for text files splitting up datetime into two variables.
        opts_pas.Delimiter = '\t';
        opts_pas = opts_pas.setvartype("micCh1_mV","double");
    end

    if length(opts_pas.VariableTypes{end}) == 4 % Make sure vertcat works if loading across different text file versions with or without mic cal constant included.
        opts_pas = opts_pas.setvartype("mic_cal","double");
        flag = 1; % Flag to see if we need to add calibration constants below
    else
        flag = 0;
    end

    pas_cell{k,1} = readtable(fnm_pas,opts_pas); % load data from text file into table

    if flag == 1 && ~exist("t_check","var") % Assign value to mic_cal from external text file if not present in PAS text file originally.
        cal_p = strsplit(root,buffer);
        cal_p = strjoin([cal_p(1:end-4),"MATLAB","Live Data Visualizer","NO2 CAL CONSTANTS.txt"],buffer); % Path to text file in L.S. folder
        cal_t = readtimetable(cal_p); % Load timetable of calibration constants
        t_diff = pas_cell{k,1}.Time(1) - cal_t.DateTime(:); % Difference in time from file and NO2 cals.
        t_diff = t_diff(t_diff>0); % Remove cals. performed after file dates
        [~,I] = min(t_diff); % Find closest time
        pas_cell{k,1}.mic_cal(:) = cal_t.MicCal(I); % Assign value based on time.
        t_check = 1; % Flag for already loading in table of cal constants.
    elseif flag == 1 && exist("t_check","var") % Condition for needing to assign value but already loaded in table
        t_diff = pas_cell{k,1}.Time(1) - cal_t.DateTime(:);
        t_diff = t_diff(t_diff>0);
        [~,I] = min(t_diff);
        pas_cell{k,1}.mic_cal(:) = cal_t.MicCal(I);
    else
    end

end
% Create table 
if yn_recent == 1
    pas_raw_table = pas_cell{i};
else
    pas_raw_table = vertcat(pas_cell{:}); % Concatenate tables
end

%% Extracting sweep times
sweep_files{length(i),1} = nan(length(i),1);
for n = i
    sweep_path = strjoin({file_list(n).folder,'sweeps','*.txt'},buffer);
    sweep_files{n} = dir(sweep_path);
end
% Create table
if yn_recent == 1
    sweep_struct = sweep_files{i};
else
    sweep_struct = vertcat(sweep_files{:,:});
end
% sweep_datetime = nan(length(sweep_struct),1);
if isempty(sweep_struct) == 0
    for n = 1:length(sweep_struct)
        sweep_datetime(n,1) = datetime(sweep_struct(n).date);
    end
sweep_datetime(:,2) = sweep_datetime(:,1)-minutes(2);
sweep_datetime(:,3) = sweep_datetime(:,1)+minutes(2);

end

% Editing table
pas_raw_table = removevars(pas_raw_table,[11:16 18]);

pas_rawdata = table2timetable(pas_raw_table);

pas_rawdata = mergevars(pas_rawdata,[1 2 3 4]);
pas_rawdata = mergevars(pas_rawdata,[2 3 4 5]);
pas_rawdata = mergevars(pas_rawdata,[5 6 7 8]);

pas_rawdata.Properties.VariableNames = {'Signal','Power','Tau_660','Filter_state','Laser_temps','Mic_cal'};
pas_dat = pas_rawdata;
%% remove frequency sweep
if exist('sweep_datetime','var')
    for n = 1:height(sweep_datetime)
        if sweep_datetime(n,2) < pas_dat.Time(1)
            continue
        else
            sweep_range = timerange(sweep_datetime(n,2),sweep_datetime(n,3));
            pas_dat(sweep_range,:)=[];
        end

    end
end

%% remove inf CRD

ix = find(pas_dat.Tau_660 == Inf);
pas_dat.Tau_660(ix) = NaN;
dTau = 1E6.*abs(pas_dat.Tau_660 - movmedian(pas_dat.Tau_660,60,"omitnan"));
pas_dat(dTau > 2,:) = [];

end
