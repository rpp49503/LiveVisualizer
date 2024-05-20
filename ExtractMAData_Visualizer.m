function [MA_dat,MA_TA_times,MA_ref_codes,MA_status_tt] = ExtractMAData_Visualizer(MA_raw_tt)
% This function takes the raw MA timetable and extract relevant variables,
% as well as calculating absorption for a new timetable.
MA_dat = removevars(MA_raw_tt,[1 2 3 4 5 6 7 8 9 10 11 12 13 14 16 17 18 19 30 76]);
MA_dat = renamevars(MA_dat,["Flow1_mL_min_","Flow2_mL_min_","FlowTotal_mL_min_","SampleTemp_C_","SampleRH___","SampleDewpoint_C_","InternalPressure_Pa_","InternalTemp_C_"],["Flow1","Flow2","FlowT","SampleTemp","RH","DewPoint","IntPressure","IntTemp"]);

MA_dat = mergevars(MA_dat,{'UVSen1', 'BlueSen1', 'GreenSen1','RedSen1','IRSen1'},"NewVariableName","Sensor1");
MA_dat = mergevars(MA_dat,["UVSen2", "BlueSen2", "GreenSen2", "RedSen2" ,"IRSen2"],"NewVariableName","Sensor2");
MA_dat = mergevars(MA_dat,["UVRef", "BlueRef", "GreenRef", "RedRef", "IRRef"],"NewVariableName","Reference");
MA_dat = mergevars(MA_dat,["UVBC1","BlueBC1","GreenBC1","RedBC1","IRBC1"],"NewVariableName","BC1");
MA_dat = mergevars(MA_dat,["UVBC2","BlueBC2","GreenBC2","RedBC2","IRBC2"],"NewVariableName","BC2");
% if contains(PAS_dat.OpticalConfig(1),"DUALSPOT")
    MA_dat = mergevars(MA_dat,["UVBCc","BlueBCc","GreenBCc","RedBCc","IRBCc"],"NewVariableName","BCC");
    MA_dat = mergevars(MA_dat,["UVK","BlueK","GreenK","RedK","IRK"],"NewVariableName","K");
% end
MA_dat = mergevars(MA_dat,["UVATN1","BlueATN1","GreenATN1","RedATN1","IRATN1"],"NewVariableName","ATN1");
MA_dat = mergevars(MA_dat,["UVATN2","BlueATN2","GreenATN2","RedATN2","IRATN2"],"NewVariableName","ATN2");

MAC = [24.069, 19.070, 17.028, 14.091, 10.120];   % units of m2/g
correction = 1.3; % from: https://help.aethlabs.com/s/article/Define-Specific-Attenuation-Cross-section-%CF%83ATN-or-Sigma-Value-for-the-microAeth-MA-Series-instruments

% Calculate absorption
BC1_abs = MA_dat.BC1.*MAC./correction./1000;
BC2_abs = MA_dat.BC2.*MAC./correction./1000;
BCC_abs = MA_dat.BCC.*MAC./correction./1000;

MA_dat = addvars(MA_dat,BC1_abs,BC2_abs,BCC_abs);

%% Find tape advances
change_val = zeros(height(MA_dat),1); % Initialize vairable for easier indexing/speed.
for n = 1: height(MA_dat)-1 % Loop through all times
    change_val(n) = MA_dat.TapePosition(n+1) - MA_dat.TapePosition(n); % Find difference in tape count between time(n) and next time.
end

tape_adv_idx = find(change_val ~= 0); % Find where changes in tape count are non-zero
MA_TA_times = [MA_dat.Time(tape_adv_idx)]; % Pull out times where changes in tape count are non-zero (tape advances).

%% Find unique status flags and store in table
% Initialize tables and structure for storing status code information
status_message = ["Raw Status Codes","Tape Error","Device on external power","Tape not ready","Tape jam","Skipped T.A.","Pump limit","Flow unstable","DualSpot enabled","Optical saturation","Tape advance","Device start up"];
MA_ref_codes = table();
MA_status_tt = timetable(nan,0,0,0,0,0,0,0,0,0,0,0,'VariableNames',status_message,'RowTimes',MA_raw_tt.Time(1));
for n = 1:height(MA_raw_tt) % Loop through all rows (times) in raw data table
    if ~ismember(MA_raw_tt.Status(n),MA_status_tt{:,1}) % Make sure that code being assesed isn't already in table to avoid duplicate entries
        row_hold = timetable(MA_raw_tt.Status(n),0,0,0,0,0,0,0,0,0,0,0,'VariableNames',status_message,'RowTimes',MA_raw_tt.Time(n));
        MA_status_tt = [MA_status_tt;row_hold]; % Append newly identified code to table
    end
end
MA_status_tt = rmmissing(MA_status_tt);

% Provide description of common, known status codes for reference and
% checking identification from loop that follows.
warning('off','MATLAB:table:RowsAddedExistingVars')
MA_ref_codes{1,1} = 524288;
MA_ref_codes{1,2} = "Tape Error";
MA_ref_codes{2,1} = 131072;
MA_ref_codes{2,2} = "Device on external power";
MA_ref_codes{3,1} = 32768;
MA_ref_codes{3,2} = "Tape not ready";
MA_ref_codes{4,1} = 8192;
MA_ref_codes{4,2} = "Tape jam";
MA_ref_codes{5,1} = 1024;
MA_ref_codes{5,2} = "Skipped T.A";
MA_ref_codes{6,1} = 256;
MA_ref_codes{6,2} = "Pump limit";
MA_ref_codes{7,1} = 128;
MA_ref_codes{7,2} = "Flow Unstable";
MA_ref_codes{8,1} = 64;
MA_ref_codes{8,2} = "DualSpot enabled";
MA_ref_codes{9,1} = 16;
MA_ref_codes{9,2} = "Optical saturation";
MA_ref_codes{10,1} = 4;
MA_ref_codes{10,2} = "Tape advance";
MA_ref_codes{11,1} = 2;
MA_ref_codes{11,2} = "Device start up";

MA_ref_codes.Properties.VariableNames={'Code','Error Message'};

%% Solve for status codes based on difference with closest code value, assigning 1 or 0 "Identified_Codes" table for each type.
for n = 1:height(MA_status_tt) % Loop through all error codes identified
    code_array = MA_ref_codes{:,1}; % Separate into new array for clarity
    t = MA_status_tt.("Raw Status Codes")(n); % intialize t variable to first code
    while t > 0 % Loop to continue doing subtraction of codes when still possible.
    [~,idx] = min(abs(t-code_array)); % Find closest value in code array to code value being evaluated.
    if t-code_array(idx) < 0 % Make sure that minimum value of subtraction is not larger than original code.
        idx = idx+1; % If so, go to next index with positive subtraction value.
    end
    t = t - code_array(idx); % Subtract closest value identified from code error
        if t == 0 % Loop to end code identification if difference is zero (code successfully identified)
            MA_status_tt{n,idx+1} = 1; % Update status in table
            t = -1; % Change variable to stop while loop
        else % If difference is not zero, assign value to relevant type in table and continue in while loop
            MA_status_tt{n,idx+1} = 1;
        end
    end
end

end