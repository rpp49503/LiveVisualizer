function [TT_avg,fit_check] = CalcPASProps_Visualizer(TT_avg,yn_fit)
% This function calculates all AAEs and SSA for PAS

TT_avg = CalcAAERatio_Visualizer(TT_avg, [663 783]); % R/IR
TT_avg = CalcAAERatio_Visualizer(TT_avg, [406 532]); % B/G
TT_avg = CalcAAERatio_Visualizer(TT_avg, [406 663]); % B/R
TT_avg = CalcAAERatio_Visualizer(TT_avg, [406 783]); % B/IR
TT_avg = CalcAAERatio_Visualizer(TT_avg, [532 663]); % G/R
TT_avg = CalcAAERatio_Visualizer(TT_avg, [532 783]); % G/IR
SSA = (TT_avg.Ext(:,1)-TT_avg.PAS_abs(:,3))./(TT_avg.Ext(:,1)); % SSA 663
TT_avg = addvars(TT_avg,SSA);

if yn_fit == 1
    [TT_avg,fit_check] = CalcAAEFit_Visualizer(TT_avg);
else
    fit_check = 0;
end

end