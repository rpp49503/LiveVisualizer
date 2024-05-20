function [tr_recent,tr_older] = PlotPAS_Visualizer(TT_avg,PAS_dat,Bkg,tr,status,y_limits,e_445,e_tdcrd,yn_fit)
% Provides plots for checking PAS data based on current status in live
% script.

TT_avg = TT_avg(tr,:); % Apply timerange from sliders on front panel
Bkg = Bkg(tr,:);

% Modify timeteable to exlude all rows out of absorbance limit range
for n = 1:width(TT_avg.PAS_abs)
    TT_avg = TT_avg(TT_avg.PAS_abs(:,n) >= y_limits(1),:); 
    TT_avg = TT_avg(TT_avg.PAS_abs(:,n) <= y_limits(2),:);
end

% Loop to make sure recent timerange is within PAS data range
if PAS_dat.Time(end) - days(1) > PAS_dat.Time(1)
    tr_recent = timerange(TT_avg.Time(end)-days(1),TT_avg.Time(end)); % Designate timerange to highlight for background histograms
    tr_older = timerange(TT_avg.Time(1),TT_avg.Time(end)-days(1),"openright"); % Designate timerange exluding most recent
else
    tr_recent = timerange(TT_avg.Time(1),TT_avg.Time(end));
    tr_older = tr_recent;
end

if status == 1

figure % DO NOT REMOVE THIS DUPLICATE. IT IS NECESSARY FOR ALL OTHER FIGURES TO DISPLAY PROPERLY
scatter(TT_avg.Time,TT_avg.PAS_abs(:,1),10,'filled')
hold on
scatter(TT_avg.Time,TT_avg.PAS_abs(:,2),10,'filled','g')
scatter(TT_avg.Time,TT_avg.PAS_abs(:,3),10,'filled','r')
scatter(TT_avg.Time,TT_avg.PAS_abs(:,4),10,'filled','k')
ylabel('PAS Absorbance (Mm^{-1}')
ylim(y_limits)
legend({'406','532','663','783'})
title('Ambient Absorbance')
hold off
close(figure)

% Plotting absorbance
figure
hold on
tiledlayout(1,1)
nexttile
scatter(TT_avg.Time,TT_avg.PAS_abs(:,1),10,'filled')
hold on
scatter(TT_avg.Time,TT_avg.PAS_abs(:,2),10,'filled','g')
scatter(TT_avg.Time,TT_avg.PAS_abs(:,3),10,'filled','r')
scatter(TT_avg.Time,TT_avg.PAS_abs(:,4),10,'filled','k')
ylabel('PAS Absorbance (Mm^{-1}')
ylim(y_limits)
legend({'406','532','663','783'})
title('Ambient Absorbance')
hold off
hold off

% Checking distribution of 780 absorbance
TT_avg_new = rmmissing(TT_avg.PAS_abs(:,4));
low_abs = length(TT_avg_new(TT_avg_new < 1)); % Calculate % of 780 points below 1.5 Mm-1
low_abs = round(low_abs/height(TT_avg_new)*100,0);
figure
hold on
tiledlayout(1,1)
nexttile
h = histogram(TT_avg.PAS_abs(:,4),'BinWidth',0.25);
hold on
xlim(y_limits)
p = h.Parent.YLim(2);
text(y_limits(2)*0.75,p*0.96,'mean = ' +string(round(mean(TT_avg.PAS_abs(:,4),'omitnan'),2)))
text(y_limits(2)*0.75,p*0.92,'median = ' +string(round(median(TT_avg.PAS_abs(:,4),'omitnan'),2)))
text(y_limits(2)*0.75,p*0.88,string(low_abs)+'% < 1 Mm^{-1}')
xlabel('780 nm Absorbance (Mm^{-1})')
ylabel('Counts')
title('Checking Absorbance Distribution')
hold off
hold off

% Plotting sample and background powers
figure
hold on
tiledlayout(1,1)
nexttile
scatter(TT_avg.Time,TT_avg.Power(:,1),10,'filled','b')
hold on
scatter(TT_avg.Time,TT_avg.Power(:,2),10,'filled','g')
scatter(TT_avg.Time,TT_avg.Power(:,3),10,'filled','r')
scatter(TT_avg.Time,TT_avg.Power(:,4),10,'filled','k')
scatter(Bkg.Time,Bkg.Power(:,1),10,'o','b')
scatter(Bkg.Time,Bkg.Power(:,2),10,'o','g')
scatter(Bkg.Time,Bkg.Power(:,3),10,'o','r')
scatter(Bkg.Time,Bkg.Power(:,4),10,'o','k')
ylabel('Laser Power (mV)')
title("PAS Sample and Bkg Powers")
legend({'Sample Powers','','','','Bkg Powers'})
hold off
hold off

% Bar graphs for color order
order_count = zeros(1,3);
for n = 1:height(TT_avg)
    if  TT_avg.PAS_abs(n,4)>TT_avg.PAS_abs(n,3) % IR/R order
        order_count(1) = order_count(1) + 1;
    end
    if TT_avg.PAS_abs(n,3)>TT_avg.PAS_abs(n,2) % R/G order
        order_count(2) = order_count(2) + 1;
    end
    if TT_avg.PAS_abs(n,2)>TT_avg.PAS_abs(n,1) % G/B order
        order_count(3) = order_count(3) + 1;
    end
end
X = [order_count(1),order_count(2),order_count(3),height(TT_avg)];
figure
hold on
tiledlayout(1,1)
nexttile
pie(X)
hold on
legend({'IR > R','R > G','G > B','Ordered'},'Location','northeast')
title('Checking Order of Absorbance')
hold off
hold off

% Plotting extinctions and backgrounds if present
if e_445 ==1 && e_tdcrd == 1

    figure
    hold on
    tiledlayout(1,1)
    nexttile
    scatter(TT_avg.Time,TT_avg.Ext(:,1),10,'filled','r')
    hold on
    scatter(TT_avg.Time,TT_avg.Ext(:,2),10,'filled','b')
    scatter(TT_avg.Time,TT_avg.Ext(:,3),10,'filled','m')
    ylabel('Extinction (Mm^{-1})')
    legend({'663','445','TD 663'})
    title('Ambient Extinctions')
    hold off
    hold off

    figure
    hold on
    t = tiledlayout(1,3,"TileSpacing","compact");
    nexttile
    histogram(Bkg.Tau(tr_older,1)*1E6,'FaceColor','r','BinWidth',0.2,'FaceAlpha',0.5)
    hold on
    histogram(Bkg.Tau(tr_recent,1)*1E6,'FaceColor','g','BinWidth',0.2,'FaceAlpha',0.5)
    legend({'','Recent bkg'})
    title('663')
    nexttile
    histogram(Bkg.Tau(tr_older,2)*1E6,'FaceColor','b','BinWidth',0.2,'FaceAlpha',0.5)
    hold on
    histogram(Bkg.Tau(tr_recent,2)*1E6,'FaceColor','g','BinWidth',0.2,'FaceAlpha',0.5)
    title('445')
    nexttile
    histogram(Bkg.Tau(tr_older,3)*1E6,'FaceColor','m','BinWidth',0.2,'FaceAlpha',0.5)
    hold on
    histogram(Bkg.Tau(tr_recent,3)*1E6,'FaceColor','g','BinWidth',0.2,'FaceAlpha',0.5)
    title('TD 663')
    hold off
    title(t,'Distribution of \tau_0','Interpreter','tex')
    ylabel(t,'Counts')
    xlabel(t,'\tau_0 (\mus)','Interpreter','tex')
    hold off

elseif e_tdcrd == 1 && e_445 == 0
    figure(5)
    scatter(TT_avg.Time,TT_avg.Ext(:,1),10,'filled','r')
    hold on
    scatter(TT_avg.Time,TT_avg.Ext(:,2),10,'filled','m')
    ylabel('Extinction (Mm^{-1})')
    legend({'663','TD 663'})
    title('Ambient Extinctions')
    hold off

    figure
    hold on
    t = tiledlayout(1,2,"TileSpacing","compact");
    nexttile
    histogram(Bkg.Tau(tr_recent,1)*1E6,'FaceColor','g','BinWidth',0.2)
    hold on
    histogram(Bkg.Tau(tr_older,1)*1E6,'FaceColor','r','BinWidth',0.2)
    legend({'','Recent bkg'})
    title('663')
    nexttile
    histogram(Bkg.Tau(tr_recent,2)*1E6,'FaceColor','g','BinWidth',0.2)
    hold on
    histogram(Bkg.Tau(tr_older,2)*1E6,'FaceColor','m','BinWidth',0.2)
    title('TD 663')
    hold off
    title(t,'Distribution of \tau_0','Interpreter','tex')
    ylabel(t,'Counts')
    xlabel(t,'\tau_0 (\mus)','Interpreter','tex')
    hold off
    
elseif e_445 == 1 && e_tdcrd == 0
    figure
    scatter(TT_avg.Time,TT_avg.Ext(:,1),10,'filled','r')
    hold on
    scatter(TT_avg.Time,TT_avg.Ext(:,2),10,'filled','b')
    ylabel('Extinction (Mm^{-1})')
    legend({'663','445'})
    title('Ambient Extinctions')
    hold off

    figure
    hold on
    t = tiledlayout(1,2,"TileSpacing","compact");
    nexttile
    histogram(Bkg.Tau(tr_recent,1)*1E6,'FaceColor','g','BinWidth',0.2)
    hold on
    histogram(Bkg.Tau(tr_older,1)*1E6,'FaceColor','r','BinWidth',0.2)
    legend({'','Recent bkg'})
    title('663')
    hold off
    nexttile
    histogram(Bkg.Tau(tr_recent,2)*1E6,'FaceColor','g','BinWidth',0.2)
    hold on
    histogram(Bkg.Tau(tr_older,2)*1E6,'FaceColor','b','BinWidth',0.2)
    title('445')
    hold off
    title(t,'Distribution of \tau_0','Interpreter','tex')
    ylabel(t,'Counts')
    xlabel(t,'\tau_0 (\mus)','Interpreter','tex')
    hold off
    
else
    figure
    scatter(TT_avg.Time,TT_avg.Ext(:,1),10,'r','filled')
    hold on
    legend({'663 Ext'})
    ylabel('Extinction (Mm^{-1})')
    title('Ambient Extinctions')
    hold off

    figure
    histogram(Bkg.Tau(tr_older,1)*1E6,'FaceColor','r','BinWidth',0.2)
    hold on
    histogram(Bkg.Tau(tr_recent,1)*1E6,'FaceColor','g','BinWidth',0.2)
    xlabel('\tau_0 (\mus)','Interpreter','tex')
    ylabel('Counts')
    legend({'663','Recent bkg'})
    title('Distribution of \tau_0','Interpreter','tex')
    hold off

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BEGIN LOOP FOR PLOTS WITH OPTICAL PROPERTIES
elseif status == 2

    % AAE histograms
    figure
    hold on
    t = tiledlayout(1,3);
    nexttile
    histogram(TT_avg.("AAE 663/783")(tr_older),'FaceColor','r','FaceAlpha',0.7,'BinWidth',0.5)
    hold on
    histogram(TT_avg.("AAE 663/783")(tr_recent),'FaceColor','g','FaceAlpha',0.5,'BinWidth',0.5)
    title('R/IR AAE')
    xlim([0 6])
    legend({'Mean = ' + string(round(mean(TT_avg.("AAE 663/783")(tr_older),'omitnan'),2)),'Mean = ' + string(round(mean(TT_avg.("AAE 663/783")(tr_recent),'omitnan'),2))})
    hold off
    nexttile
    histogram(TT_avg.("AAE 406/532")(tr_older),'FaceColor','b','FaceAlpha',0.7,'BinWidth',0.5)
    hold on
    histogram(TT_avg.("AAE 406/532")(tr_recent),'FaceColor','g','FaceAlpha',0.5,'BinWidth',0.5)
    legend({'Mean = ' + string(round(mean(TT_avg.("AAE 406/532")(tr_older),'omitnan'),2)),'Mean = ' + string(round(mean(TT_avg.("AAE 406/532")(tr_recent),'omitnan'),2))})
    title('B/G AAE')
    xlim([0 6])
    hold off
    nexttile
    if exist("TT_avg.AAE_fit","var")
        histogram(TT_avg.AAE_fit(tr_older),'FaceColor','m','FaceAlpha',0.7,'BinWidth',0.5)
        hold on
        histogram(TT_avg.AA_fit(tr_recent),'FaceColor','g','FaceAlpha',0.5,'BinWidth',0.5)
        legend({'Mean = ' + string(round(mean(TT_avg.AAE_fit(tr_older),'omitnan'),2)),'Mean = ' + string(round(mean(TT_avg.AAE_fit(tr_recent),'omitnan'),2))})
        title('AAE Fit')
        xlim([0 6])
        hold off
    else
        histogram(TT_avg.("AAE 406/783")(tr_older),'FaceColor','m','FaceAlpha',0.7,'BinWidth',0.5)
        hold on
        histogram(TT_avg.("AAE 406/783")(tr_recent),'FaceColor','g','FaceAlpha',0.5,'BinWidth',0.5)
        legend({'Mean = ' + string(round(mean(TT_avg.("AAE 406/783")(tr_older),'omitnan'),2)),'Mean = ' + string(round(mean(TT_avg.("AAE 406/783")(tr_recent),'omitnan'),2))})
        title('B/IR AAE')
        xlim([0 6])
        hold off
    end
    title(t,'AAE Histograms')
    xlabel(t,'AAE')
    ylabel(t,'Counts')
    hold off

    if yn_fit == 1
        TT_avg_new = TT_avg.R2;
        TT_avg_new = rmmissing(TT_avg_new);
        r2 = TT_avg_new(TT_avg_new > 0.9,:);
        r2 = round(length(r2)/height(TT_avg_new)*100,2);
        figure
        histogram(TT_avg.R2,'BinWidth',0.1)
        legend(string(r2)+"% > 0.9",'Location','northwest')
        title('PAS R^2')
    end
    

end

end