function TT_avg = CalcMaProps_Visualizer(TT_avg,device_name,yn_fit)
% Compilation of AAEs to calculate for MA350 in live script.

% Initialize timetable to calculate power law fits
colors = ["UV","Blue","Green","Red","IR"];
TT_avg_2 = TT_avg(:,"BCC_abs");
TT_avg_2 = splitvars(TT_avg_2,"BCC_abs","NewVariableNames",colors);
TT_avg_2 = rmmissing(TT_avg_2);

TT_avg_new = CalcMaAAE_Visualizer(TT_avg_2,device_name,colors=["UV","Blue"]);   % calculates AAE just using UV and Blue wavelengths
TT_avg_new = [TT_avg_new,CalcMaAAE_Visualizer(TT_avg_2,device_name,colors=["Green","Red"])];   % calculates AAE just using UV and Blue wavelengths
TT_avg_new = [TT_avg_new,CalcMaAAE_Visualizer(TT_avg_2,device_name,colors=["Red","IR"])];   % calculates AAE just using Red and IR wavelengths
TT_avg_new = [TT_avg_new,CalcMaAAE_Visualizer(TT_avg_2,device_name,colors=["Blue","IR"])]; % Calculate AAE just using Blue and IR wavelengths

if yn_fit == 1
    TT_avg_new = [TT_avg_new,CalcMaAAE_Visualizer(TT_avg_2,device_name)];   % calculates AAE (and R^2) using all five wavelengths
    TT_avg_new = [TT_avg_new,CalcMaAAE_Visualizer(TT_avg_2,device_name,colors=["UV","Blue","Green","Red"])];
else
end

TT_avg = synchronize(TT_avg,TT_avg_new,'union');

end
