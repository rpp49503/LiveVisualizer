function [AE33_TT,AE33_log,AE33_setup,TA_times] = AE33_VisualizerFun(root,Settings,yn_recent,buffer)
% % In order to use this script seamlessly, keep all raw data, log, and AE 
% setup files in the same monthly folder as conventionally exported by the 
% AE33. The"Load_AE33" function will load in files from monthly folders and 
% reformat variables for easier indexing. The output of this script will be
% concatenated timetable over the time range  with new variables appended 
% (TT_AE). The new variables to be calculated and appended are as follows: 

% Attenuation on spot 1: ATN1 (unitless)
% Attenuation on spot 2: ATN2 (unitless)
% Compensated BC concentrations on spot 2: BCC2 (ng/m^3)
% Absorbance on channel 2: BCC2_abs (Mm^-1)
% Instantaneous Drinovec compensation parameter: K_inst (unitless)
% Instantaneous compensated BC concentration on spot 1: BCC1_inst (ng/m^3)
% Instantaneous compensated absorbance on spot 1: BCC1_inst_abs (Mm^-1)
% Isntantaneous compensated BC concentration on spot 2: BCC2_inst (ng/m^3)
% Instantaneous compensated absorbance on spot 2: BCC2_inst_abs (Mm^-1)
% Virkkula-based compensation parameter: K_vrkla (unitless)
% Virkkula-based compensated BC concentration: BCC_vrkla (ng/m^3)
% Virkkula-based compensated absorbance: BCC_vrkla_abs (Mm^-1)

% Imports raw data from .DAT data files into single timetable. Formats
% variables such that columns of each represent all 7 wavelengths in
% increasing order. Also import data from log files and AE33 setup as
% separate timetables.

[AE33_TT,AE33_log,AE33_setup,Settings] = LoadAE33_Visualizer(root,Settings,buffer,yn_recent);

% If you are alerted that the "AE Setup" parameters do not match the
% settings specified above, make necessary changes to variable assignments
% in "Settings" structure before continuing.

%% Pull out tape advance times and store as new variable.
change_val = zeros(height(AE33_TT),1); % Initialize vairable for easier indexing/speed.
for n = 1: height(AE33_TT)-1 % Loop through all times
    change_val(n) = AE33_TT.TapeCount(n+1) - AE33_TT.TapeCount(n); % Find difference in tape count between time(n) and next time.
end

tape_adv_idx = find(change_val ~= 0); % Find where changes in tape count are non-zero
TA_times = [AE33_TT.Time(tape_adv_idx)]; % Pull out times where changes in tape count are non-zero (tape advances).

%% Calculate ATN1 and ATN2, correcting for ATN_zeros from log files.
if Settings.e_log == 1
    ATN_0 = timetable();
    check = 0;
    for n = 1:height(AE33_log)
        holder = string(AE33_log.Message(n));
        if length(holder{:}) >= 11 && strcmp(holder{1}(1:11),'ATN1zero(1)') == 1
            check = check+1;
            holder = strjoin(AE33_log.Message(n:n+6));
            new = strsplit(holder);
            ATN1_0 = str2double(new(2:4:26));
            ATN2_0 = str2double(new(4:4:end));
            tt = timetable(ATN1_0,ATN2_0,'RowTimes',AE33_log.Time(n));
            ATN_0 = [ATN_0;tt];
        end
    end
    if isempty(ATN_0)
        Settings.e_log = 0;
    end
end

if Settings.e_log == 1
    % Calculate ATN1 and ATN2 from respective channel singals and references and subtract background ATN.
    ATN1 = -100*log(AE33_TT.Sensor1./AE33_TT.Ref); % Calculate attenuation
    ATN2 = -100*log(AE33_TT.Sensor2./AE33_TT.Ref);
    AE33_TT = addvars(AE33_TT,ATN1,ATN2); % Add attenuation on both spots to timetable
    AE33_TT = sortrows(AE33_TT,'Time','ascend');

    AE33_TT = synchronize(AE33_TT,ATN_0,'union','previous'); % Synchronize ATN zero and data timetables to union of timeranges, and maintaining previous ATN_0 values between tape advances.
    if sum(isnan(sum(AE33_TT.ATN1_0,1))) == 7 || sum(isnan(sum(AE33_TT.ATN2_0,1))) == 7 % Alert if there are mismatched ATN and ATN_0 times/values.
        fprintf(2,"Not all ATN values have been corrected for background due to missing ATN_0 from logs. Consider removing rows with '0' to avoid negative/inaccurate ATN values, or manually correct for these time periods.")
        AE33_TT.ATN1_0(isnan(AE33_TT.ATN1_0)) = 0; % Replace Nan with 0 for subtraction of missing background values
        AE33_TT.ATN2_0(isnan(AE33_TT.ATN2_0)) = 0;
    end

    AE33_TT.ATN1 = AE33_TT.ATN1 - AE33_TT.ATN1_0; % Subtract background ATN
    AE33_TT.ATN2 = AE33_TT.ATN2 - AE33_TT.ATN2_0;

else % If ATN zeros are not present, create empty columns for variables that cannot be calculated to keep table dimensions equal in either case.
    ATN1 = (1-(AE33_TT.BC1./AE33_TT.BCC1))./AE33_TT.K_weight; % Calculate attenuation on spot 1 from BCC and BC1. Already corrected for ATN zero.
    ATN2 = zeros(height(AE33_TT),7);
    ATN1_0 = zeros(height(AE33_TT),7);
    ATN2_0 = zeros(height(AE33_TT),7);
    AE33_TT = addvars(AE33_TT,ATN1,ATN2,ATN1_0,ATN2_0); % Add attenuation on spot 1 and variables of zeros for properties unable to extract or calculate.
end

% Attenuation values in the output "TT_AE" timetable are automatically
% corrected for background "ATN_0" values, which are also stored as a 
% separate timetable for reference if needed. You may want to verify that
% ATN_0 values match those from AE33 log files.

%% Calculate all properties using Drinovec compensation parameter ("K_weight" and "K_inst")

% Derive instantaneous compensation factor and apply to spot 1 and 2
K_inst = nan(height(AE33_TT),7); % Initialize variable for easier/faster indexing.
K_old = nan; % Initialize to nan for generation of error message below.
check = 0; % Check to see if error message already thrown to avoid repeats.
w = waitbar(0,"Calculating Drinovec-based properties");
for n = 1:height(AE33_TT) % Loop through all times in timetable
    if AE33_TT.ATN1(n) < Settings.ATN_f2 % Condition for where K_weight does not change
        K_inst(n,:) = AE33_TT.K_weight(n); % Set instantaneous K equal to weighted when ATN < ATN_f2.
        K_old = K_inst(n,:); % Hold this value for calculation when ATN > ATN_f2 in statement below.
    else % Derive K_inst for when K_weight begins to change (ATN1 > ATN_f2)
        K_inst(n,:) = (AE33_TT.K_weight(n,:).*(Settings.ATN_TA - Settings.ATN_f2) - K_old.*(Settings.ATN_TA-AE33_TT.ATN1(n,:)))./(AE33_TT.ATN1(n,:)-Settings.ATN_f2); % Calculate K_inst from weighting equation (Drinovec 2015).
        if sum(isnan(K_inst(n,:))) == 7 && check == 0 % Condition to throw alert at times where K_inst can't be calculated
            fprintf(2,"Instantaneous K values cannot be calculated for tape cycles where ATN1 is never less than ATN_f2. \n This usually occurs in the first and/or last tape cycles of the time range. \n")
            check = check+1;
        end
    end
    if rem(n,100) == 0 % Condition to update waitbar
        waitbar(n/(height(AE33_TT)),w) % Update waitbar based on loop iteration
    end
end

AE33_TT = addvars(AE33_TT,K_inst); % Add to timetable.

% Calculate Instantaneous BCC concentrations (ng/m^3) and absorbance
% (Mm^-1) on each spot.
if Settings.e_log == 1
    BCC1_inst = AE33_TT.BC1./(1-AE33_TT.K_inst.*AE33_TT.ATN1); 
    BCC1_inst_abs = BCC1_inst.*Settings.MAC*1E-3; 
    BCC2_inst = AE33_TT.BC2./(1-AE33_TT.K_inst.*AE33_TT.ATN2);
    BCC2_inst_abs = BCC2_inst.*Settings.MAC*1E-3;
    
    AE33_TT = addvars(AE33_TT,BCC1_inst,BCC1_inst_abs,BCC2_inst,BCC2_inst_abs); % Add variables to timetable.
    
    % Apply K_weight to spot 2
    BCC2 = AE33_TT.BC2./(1-AE33_TT.K_weight.*AE33_TT.ATN2); % Calculate BCC2
    BCC2_abs = (BCC2.*Settings.MAC)*1E-3; % Calculate BCC2 absorbance and convert to Mm^-1
    BCC1_abs = AE33_TT.BCC1.*Settings.MAC*1E-3; % Calculate BCC1 absorbance and convert to Mm^-1
    
    AE33_TT = addvars(AE33_TT,BCC1_abs,BCC2,BCC2_abs); % Add new variables to timetable

else % When logs aren't present, cannot calculate properties on spot 2, so add these variables as "NaN"
    BCC1_inst = AE33_TT.BC1./(1-AE33_TT.K_inst.*AE33_TT.ATN1); 
    BCC1_inst_abs = BCC1_inst.*Settings.MAC*1E-3; 
    BCC1_abs = AE33_TT.BCC1.*Settings.MAC*1E-3; % Calculate BCC1 absorbance and convert to Mm^-1
    BCC2_inst = nan(height(AE33_TT),7);
    BCC2_inst_abs = nan(height(AE33_TT),7);
    BCC2 = nan(height(AE33_TT),7);
    BCC2_abs = nan(height(AE33_TT),7);
    AE33_TT = addvars(AE33_TT,BCC1_inst,BCC1_inst_abs,BCC2_inst,BCC2_inst_abs,BCC1_abs,BCC2,BCC2_abs); % Add new variables to timetable
end

close(w) % Close waitbar

%% Calculate all properties using, and including, Virkkula-based compensation parameter
if Settings.e_log == 1
    K_vrkla = (AE33_TT.BC2-AE33_TT.BC1)./((AE33_TT.BC2.*AE33_TT.ATN1)-(AE33_TT.BC1.*AE33_TT.ATN2)); % Calculate virkkula-based compensation parameter at each time step
    BCC_vrkla = AE33_TT.BC1./(1-K_vrkla.*AE33_TT.ATN1); % Compensate BC using virkkula-based method
    BCC_vrkla_abs = BCC_vrkla.*Settings.MAC*1E-3; % Calculate absorbance from virkkula-based BC
    
    AE33_TT = addvars(AE33_TT,K_vrkla,BCC_vrkla,BCC_vrkla_abs); % Add virkkula-based parameters to timetable

else % If logs aren't present, add 
    K_vrkla = nan(height(AE33_TT),7);
    BCC_vrkla = nan(height(AE33_TT),7);
    BCC_vrkla_abs = nan(height(AE33_TT),7);

    AE33_TT = addvars(AE33_TT,K_vrkla,BCC_vrkla,BCC_vrkla_abs); % Add virkkula-based parameters to timetable

end