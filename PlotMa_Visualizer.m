function PlotMa_Visualizer(TT_avg,tr,status,e_both,y_limits,yn_fit)
% Plots relevant data for microaeths in live script visualizer

TT_avg = TT_avg(tr,:);

% Modify timeteable to exlude all rows out of absorbance limit range
for n = 1:5
    if e_both == 1
        TT_avg = TT_avg(TT_avg.BCC_abs_uga(:,n) >= y_limits(1),:); 
        TT_avg = TT_avg(TT_avg.BCC_abs_wcu(:,n) >= y_limits(1),:);
        TT_avg = TT_avg(TT_avg.BCC_abs_uga(:,n) <= y_limits(2),:);
        TT_avg = TT_avg(TT_avg.BCC_abs_wcu(:,n) <= y_limits(2),:);
    else
        TT_avg = TT_avg(TT_avg.BCC_abs(:,n) >= y_limits(1),:);
        TT_avg = TT_avg(TT_avg.BCC_abs(:,n) <= y_limits(2),:);
    end
end

tr_recent = timerange(TT_avg.Time(end)-days(1),TT_avg.Time(end)); % Designate timerange to highlight for background histograms
tr_older = timerange(TT_avg.Time(1),TT_avg.Time(end)-days(1),"openright"); % Designate timerange exluding most recent

figure
close(figure)

if status == 1 % BEGIN LOOP FOR STATUS 1 PLOTS
    if e_both == 0

        figure
        scatter(TT_avg.Time,TT_avg.BCC_abs(:,1),10,'filled','c')
        hold on
        scatter(TT_avg.Time,TT_avg.BCC_abs(:,2),10,'filled','b')
        scatter(TT_avg.Time,TT_avg.BCC_abs(:,3),10,'filled','g')
        scatter(TT_avg.Time,TT_avg.BCC_abs(:,4),10,'filled','r')
        scatter(TT_avg.Time,TT_avg.BCC_abs(:,5),10,'filled','k')
        ylabel('MA350 BCC Absorbance (Mm^{-1})')
        legend({'375','470','528','625','880'})
        title('MA350 Absorbance Timeseries')
        hold off

        % Pie chart for color order
        TT_avg_2 = rmmissing(TT_avg.BCC_abs);
        order_count = zeros(1,4);
        for n = 1:length(TT_avg_2)
            if  TT_avg_2(n,5)>TT_avg_2(n,4) % IR/R order
                order_count(1) = order_count(1) + 1; % Increase counter
            end
            if TT_avg_2(n,4)>TT_avg_2(n,3) % R/G order
                order_count(2) = order_count(2) + 1;
            end
            if TT_avg_2(n,3)>TT_avg_2(n,2) % G/B order
                order_count(3) = order_count(3) + 1;
            end
            if TT_avg_2(n,2)>TT_avg_2(n,1) % B/UV order
                order_count(4) = order_count(4) + 1;
            end
        end
        X = [order_count(1),order_count(2),order_count(3),order_count(4),height(TT_avg_2)];
        figure
        pie(X)
        hold on
        legend({'IR > R','R > G','G > B','B > UV','Ordered'},'Location','northeast')
        title('Checking MA Order of Absorbance')
        hold off

%         figure
%         scatter(TT_avg.ATN1(:,1),TT_avg.BCC_abs,10,'filled')
%         hold on
%         scatter(TT_avg.ATN1(:,1),TT_avg.BC1_abs,10,'filled')
%         ylabel('MA350 Absorbance 370nm (Mm^{-1})')
%         legend({'BCC','BC1'})
%         hold off

        figure
        histogram(TT_avg.RH)
        xlabel("RH %")

    else

        figure
        hold on
        t =tiledlayout(1,1);
        nexttile
        scatter(TT_avg.Time,TT_avg.BCC_abs_uga(:,1),10,'filled','c')
        hold on
        scatter(TT_avg.Time,TT_avg.BCC_abs_uga(:,2),10,'filled','b')
        scatter(TT_avg.Time,TT_avg.BCC_abs_uga(:,3),10,'filled','g')
        scatter(TT_avg.Time,TT_avg.BCC_abs_uga(:,4),10,'filled','r')
        scatter(TT_avg.Time,TT_avg.BCC_abs_uga(:,5),10,'filled','k')
        title(t,'Absorbance Timeseries (UGA MA350)')
        ylabel(t,'BCC Absorbance (Mm^{-1})')
        hold off

        figure
        hold on
        tiledlayout(1,1)
        nexttile
        histogram(TT_avg.RH_uga./TT_avg.RH_wcu)
        xline(1)
        title('Checking RH Agreement')
        xlabel('RH ratio (UGA/WCU)')
        hold off

        figure
        hold on
        t = tiledlayout(1,3);
        nexttile
        histogram(TT_avg.BCC_abs_uga(:,1)./TT_avg.BCC_abs_wcu(:,1))
        title('370')
        nexttile
        histogram(TT_avg.BCC_abs_uga(:,3)./TT_avg.BCC_abs_wcu(:,3))
        title('528')
        nexttile
        histogram(TT_avg.BCC_abs_uga(:,5)./TT_avg.BCC_abs_wcu(:,5))
        title('880')
        xlabel(t,'BCC Absorbance Ratio (UGA/WCU)')
        title(t,'Checking BCC Absorbance Agreement')
        hold off

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else % CASE WHEN OPTICAL PROPERTIES ARE CALCULATED AND MA ONLY EXISTS


end % END LOOP FOR CASES

  
end