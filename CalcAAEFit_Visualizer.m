function [TT_avg,fit_check] = CalcAAEFit_Visualizer(TT_avg)
% This function calculates AAE for PAS using power-law fit of all 4
% wavelengths.

wavelengths = [406;532;663;783]; % PAS wavelengths
y = TT_avg.PAS_abs; % PAS absorption

AAE_fit = nan(height(TT_avg),1);
R2 = nan(height(TT_avg),1);
wb = waitbar(0,'Calculating AAE');
for n = 1:height(TT_avg)
    if sum(isnan(y(n,:))) >= 1 
        AAE_fit(n) = nan;
    else
    [f,gof] = fit(wavelengths,y(n,:)','power1','StartPoint',[1,-1]); % fit power law to extract coefficeints

        % Loop to remove negative AAE fits
        if -f.b <= 0
            AAE_fit(n) = nan;
        else
            AAE_fit(n) = -f.b; % Extract PAS AAE
            R2(n) = gof.rsquare; % extract PAS r-squared
        end
    end

    if mod(n,10) == 0
        waitbar(n/height(TT_avg),wb);
    else
    end

end
close(wb)

TT_avg = addvars(TT_avg,AAE_fit,R2);
fit_check = 1;

end