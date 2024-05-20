function [CRD_dat] = Load445_Visualizer(root,yn_recent,buffer)
% This function loads in data from the 445 nm CRD from monthly folder
% selection

root_crd = strrep(root,"MultiPAS-IV","445 CRD"); % Change path from PAS to CRD folder
file_list = dir(fullfile(root_crd,'*.txt')); % Get directory of folder elements
datenums = extractfield(file_list,'datenum'); % extract datenumbers from file list
% Statement changes loop iteration number for loading below
if yn_recent == 1
    [~,m] = max(datenums);
else
    m = 1:length(file_list);
end

% Create cell of data tables from folder
crd_cell{length(m),1} = zeros(length(m),1);
for k = m
    fnm_crd = strjoin({file_list(k).folder,file_list(k).name},buffer);
    opt = detectImportOptions(fnm_crd);
    opt.VariableNames = {'Date','Raw_Time','Tau_445','Temp'};
    opt.SelectedVariableNames = {'Date','Raw_Time','Tau_445'};
    opt = setvaropts(opt,'Date','InputFormat','yyyy-MM-dd');
    crd_cell{k,1} = readtable(fnm_crd,opt);
end

if yn_recent ==1
    tbl = crd_cell{m};
else
    tbl = vertcat(crd_cell{:}); % Concatenate tables
end

% Reformat time
tmp = tbl.Date + tbl.Raw_Time;
tmp.Format = 'yyyy-MM-dd HH:mm:ss';
tbl.dt = tmp;

% Reformat timetable for export
CRD_dat = table2timetable(tbl,'RowTimes',tbl.dt);
CRD_dat = removevars(CRD_dat, {'Raw_Time','Date','dt'});
CRD_dat.Time = dateshift(CRD_dat.Time,'start','second','next');
CRD_dat(CRD_dat.Tau_445 == Inf,:) = [];
dTau = 1E6.*abs(CRD_dat.Tau_445 - movmedian(CRD_dat.Tau_445,60,"omitnan"));
CRD_dat(dTau > 3,:) = [];

end
