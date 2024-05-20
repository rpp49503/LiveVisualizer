function [TT_avg] = CalcAAERatio_Visualizer(TT_avg, lambda_vector)

% This function calculates AAE values from two wavelengths input as a vector in the format of [lambda_1,lambda_2] and is called by
% the AAE_calc function to append AAE values to origianl time table from
% MultiPAS-IV LabView data collection.

lambda_1=lambda_vector(1);
lambda_2=lambda_vector(2);

AAE_denom=log(lambda_2/lambda_1); % Calculate denominator of AAE based on wavelengths. This will change depending on the wavlength ratio being investigated.

%% If statements to select apprpriate data columns from original table
% 406 nm
if lambda_1==406
    x=1;
elseif lambda_2==406
    y=1;
else 
end

% 532 nm
if lambda_1==532
    x=2;
elseif lambda_2==532
    y=2;
else 
end

% 662 nm
if lambda_1==663
    x=3;
elseif lambda_2==663
    y=3;
else
end

% 785 nm
if lambda_1==783
    x=4;
elseif lambda_2==783
    y=4;
else
end

%% Create a for-loop to calculate the numerator of AAE
AAE_num = real(log(TT_avg.PAS_abs(:,x)./TT_avg.PAS_abs(:,y)));

aae_vals=AAE_num/AAE_denom; % Divide numerator and denominator to get AAE values in matrix

% Remove negative AAE values
vd = find(aae_vals <= 0);
aae_vals(vd) = nan;

TT_avg = addvars(TT_avg,aae_vals,'NewVariableNames',"AAE " + lambda_1 + "/" + lambda_2); % Add AAE values to timetable

end