function [TDCRD_dat] = LoadTDCRD_Visualizer(root,yn_recent,buffer)
% This funciton takes the text file output from the TD-CRD LabView funciton,
% and reads it into MATLAB for analysis.
%%
root = strrep(root,"MultiPAS-IV","TDCRD"); % Change folder path from PAS to TDCRD
file_list = dir(fullfile(root,'*.txt')); % Search directory of folder elements
datenums = extractfield(file_list,'datenum'); % extract datenumbers from file list
% Statement changes loop iteration number for loading below
if yn_recent == 1
    [~,i] = max(datenums);
else
    i = 1:length(file_list);
end

% Create cell of data tables from folder
crd_cell{length(i),1} = zeros(length(i),1);
for k = i
    fnm_crd = strjoin({file_list(k).folder,file_list(k).name},buffer);
    opt = detectImportOptions(fnm_crd);
    opt.VariableNames = {'Date','Raw_Time','Tau_TDCRD'};
    % opt = setvaropts(opt,'Date','InputFormat','yyyy-MM-dd');
    crd_cell{k,1} = readtable(fnm_crd,opt);
end

if yn_recent ==1
    tbl = crd_cell{i};
else
    tbl = vertcat(crd_cell{:}); % Concatenate tables
end

% Reformat Time
tmp = tbl.Date + tbl.Raw_Time;
tmp.Format = 'yyyy-MM-dd HH:mm:ss';
tbl.dt = tmp;

% Reformat Timetable for export
TDCRD_dat = table2timetable(tbl,'RowTimes',tbl.dt);
TDCRD_dat = removevars(TDCRD_dat, {'Raw_Time','Date','dt','ExtraVar1'});
TDCRD_dat.Time = dateshift(TDCRD_dat.Time,'start','second','next');
TDCRD_dat(TDCRD_dat.Tau_TDCRD == Inf,:) = [];
dTau = 1E6.*abs(TDCRD_dat.Tau_TDCRD - movmedian(TDCRD_dat.Tau_TDCRD,60,"omitnan"));
TDCRD_dat(dTau > 3,:) = [];

end
