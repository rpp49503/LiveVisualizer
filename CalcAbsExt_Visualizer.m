function [PAS_dat_tt,Backgrounds_tt] = CalcAbsExt_Visualizer(PAS_int,e_445,e_tdcrd)
%% Initialize constants
c = 2.99792E8; % m/s

% Change values of numerator of purge here if flows in lab are changed
purge_pas = 1 - (22/320);
purge_445 = 1 - (15/320);
purge_tdcrd = 1 - (28/320);

% Change values of rL term if needed on each CRD
rL_pas = 1.13;
rL_445 = 1.297;
rL_tdcrd = 1.13;

% Condition for which CRD instruments are present in the input timetable
rL = rL_pas;
purge = purge_pas;
if e_445 == 1
    rL = [rL_pas rL_445];
    purge = [purge_pas purge_445];
else
end

if e_tdcrd == 1
    rL = [rL_pas rL_tdcrd];
    purge = [purge_pas purge_tdcrd];
else
end

if e_445 == 1 && e_tdcrd == 1
    rL = [rL_pas rL_445 rL_tdcrd];
    purge = [purge_pas purge_445 purge_tdcrd];
else
end

ext_holder = width(PAS_int.Tau); % used to initialize width of extinction variable

%% pull out and initialize an array with the valve state
VS = PAS_int.('Filter_state');
VSR = reshape(VS,1,[]);

% Now we need to pull out when sample time starts and stops
mask = VSR == 0; % this creates a logical array where PAS is sampling 
% Valve state reads 0 on data file
start = strfind([0 mask], [0 1]); % array with spectrum 
% indicies where sampling starts
stop = strfind([0 mask], [1 0]); % array with spec ind. where samp stops
if length(start) > length(stop) % incase the files stop saving during samp
    stop = [stop, length(VSR)];
end

%% S0
absorption = NaN(height(PAS_int),4);
ext = NaN(height(PAS_int),ext_holder);
Backgrounds_tt = [];
wb = waitbar(0,"Calculating Absorbance");
for n = 1:length(start)

% pull out background timerange from 5th - 7th minute.
bkg_tr = timerange(PAS_int.Time(start(n))-minutes(3),PAS_int.Time(start(n))-minutes(1));

PAS_t = PAS_int(bkg_tr,:); % create new timetable for background timerange

% Average background timetable variables
Signal = mean(PAS_t.Signal,'omitnan');
Power = mean(PAS_t.Power,'omitnan');
Tau = mean(PAS_t.Tau,'omitnan');
Filter_state = mean(PAS_t.Filter_state,'omitnan');

% Loop to make sure times exist in table (error if not) and that background timerange is long enough
if ~isnan(Filter_state) && height(PAS_t) > 100
    idx_time = round(height(PAS_t)/2); % index of bakcground timetable to assign averaged variables
    tt_hold = timetable(PAS_t.Time(idx_time),Signal, Power, Tau, Filter_state); % Create timetable for averaged background data
    Backgrounds_tt = [Backgrounds_tt;tt_hold]; % Append row time to total timetable for backgrounds
else
end

% For short backgrounds, set absorption and extinction equal to NaN. Set to minimum of 100 seconds.
if height(PAS_t) < 100
    absorption(start(n)+2:stop(n)-4,:) = nan;
    ext(start(n)+2:stop(n)-4,:) = nan;
else

    % calculate absorption, subtracting average of background if long enough.
    absorption(start(n):stop(n),:) = ...
       ((PAS_int.('Signal')(start(n):stop(n),:))...
       -mean(PAS_int.('Signal')(bkg_tr,:),1,'omitnan'))...
        ./(PAS_int.('Power')(start(n):stop(n),:).* PAS_int.Mic_cal(start(n):stop(n)));
    
    ext(start(n):stop(n),:) = purge.*(rL/c).* ...
        ((PAS_int.('Tau')(start(n):stop(n),:).^-1)...
        -(mean(PAS_int.('Tau')(bkg_tr,:),'omitnan')).^-1);
end

if mod(n,10) == 0
    waitbar(n/length(start),wb)
else
end

end
close(wb)

ext = ext.*1E6; % Convert units

PAS_dat_tt = addvars(PAS_int,absorption,ext,'NewVariableNames',{'PAS_abs','Ext'}); % Append absorption and extinction to raw timetable

%% Remove background times from timetable
wb = waitbar(0,'Extracting Filter Cycles');
PAS_dat_2 = PAS_dat_tt;
for n = 2:length(start)

    get_time_start = PAS_dat_2.Time(start(n));
    get_last_stop = PAS_dat_2.Time(stop(n-1));
    time_range_cut_for = timerange(get_last_stop,get_time_start+minutes(4));
    %     time_range_cut_back = timerange(get_time_start-minutes(10),get_time_start);

    PAS_dat_tt(time_range_cut_for,:)=[]; % Remove times 
    if mod(n,10) == 0
        waitbar(n/length(start),wb);
    end

end

% condition to remove filter time if first cycle is filter in.
if PAS_dat_2.Filter_state(1) == 1
    cut_start = timerange(PAS_dat_2.Time(1),PAS_dat_2.Time(start(1)));
    PAS_dat_tt(cut_start,:) = [];
else
end

% Condition to remove filter time if last cycle is filter in.
if PAS_dat_2.Filter_state(end) == 1
    cut_stop = timerange(PAS_dat_2.Time(stop(end)),PAS_dat_2.Time(end),'closed');
    PAS_dat_tt(cut_stop,:) = [];
else
end

PAS_dat_tt = removevars(PAS_dat_tt,["Laser_temps","Mic_cal"]);
PAS_dat_tt.Time.TimeZone = 'America/New_York';
Backgrounds_tt.Time.TimeZone = 'America/New_York';

close(wb)

end