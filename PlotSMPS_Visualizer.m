function PlotSMPS_Visualizer(TT_avg,Diams)
% This function is used in the live script data visualizer to plot relevant
% properties of SMPS scans: Surface plot of number distributions,
% timeseries of total concentration, geometric distribution.

% Surface plot of number distributions
figure
surf(Diams,TT_avg.Time,TT_avg{:,1:107})
set(gca,'xscale','log')
xlabel('Diameter (nm)')
zlabel('dN/dlog(Dp) (#/cm^3)')

% % Surface plot of mass distributions
% p = TT_avg.Density_g_cc_; % Aerosol density in g/cm^3
% M = TT_avg{:,1:107}.*p.*Diams.^3.*(pi/6); % Convert number distributions to mass distributions in ug/m^3
% figure
% surf(Diams,TT_avg.Time,M)
% set(gca,'xscale','log')
% xlabel('Diameter (nm)')
% zlabel('dM/dlog(Dp) (ug/m^3)'


end