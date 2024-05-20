function TT2 = CalcMaAAE_Visualizer(TT,device_name,option)
    % calculates AAE based on fit to all of the BCc values (default) or just a subset of wavelengths (option.colors)
    % REQUIRES Mathworks Curve Fitting Toolbox

    arguments
        TT timetable
        device_name string = ["UGA","WCU",""];
        option.colors string = ["UV","Blue","Green","Red","IR"];
    end

    colors = ["UV","Blue","Green","Red","IR"];
    wavelengths = [375,470,528,625,880];
    found = contains(colors,option.colors);
    wavelengths = wavelengths(found);

%     found = contains(TT.Properties.VariableNames,option.colors);
%     suffix = "BC1";
%     if contains(TT.Properties.VariableNames,"BCc")
%         suffix = "BCc";
%     end

    y = TT{:,found};
    neg = any(y<0,2);
    AAE = nan(height(TT),1);
    R2 = nan(height(TT),1);
    if length(wavelengths) == 2
        AAE = log(y(:,1)./y(:,2)) / log(wavelengths(2)/wavelengths(1));
    else
        wb = waitbar(0,'Calculating AAE');
        for i = 1:height(TT)
            [f,gof] = fit(wavelengths',y(i,:)','power1','StartPoint',[1,-1]);
            AAE(i) = -f.b;
            R2(i) = gof.rsquare;
            if mod(i,10) == 0
                waitbar(i/height(TT),wb);
            end
        end
        close(wb)
        % AAE = AAE';
        % R2 = R2';
        R2(neg) = NaN;
    end
    AAE(neg) = NaN;
    if length(wavelengths) > 2
        AAE_name = "MA_AAE_"  + strjoin(option.colors,"_") + device_name;
        TT{:,AAE_name} = AAE;
        TT{:,AAE_name+"_R2"} = R2;
        TT2 = TT(:,[AAE_name,AAE_name+"_R2"]);
    else
        AAE_name = "MA_AAE_" + strjoin(option.colors,"_") + device_name;
        TT{:,AAE_name} = AAE;
        TT2 = TT(:,AAE_name);
    end

end