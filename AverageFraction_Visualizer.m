function TS = AverageFraction_Visualizer(TS,avgTime,fraction)

    % TS: timetable with numeric data only (no categorical variables)
    % avgTime: time interval for data 
    % fraction: fraction of sample points in averaging window that must be present for averaging to be valid
    %            e.g. 0.5 requires at least half of the possible times to be present

    % calculate most common difference between rows - assume this is the time step
    time_step = mode(time(caldiff(TS.Properties.RowTimes)));

    % check to see if time_step is larger than avgTime
    if avgTime < time_step
        error('Averaging time (%d minutes) is shorter than sample time step (%d minutes).',avgTime,minutes(time_step))
    end

    % count # of samples in each averaging period
    TT2 = retime(TS,'regular','count','TimeStep',avgTime);

    % calculate minimum # of samples required to average
    min_samples = round(avgTime / time_step * fraction);

    % flag for removal averaging periods with < minimum # of samples
    remove = TT2{:,:} < min_samples;
    TT2 = retime(TS,'regular','mean','TimeStep',avgTime);

    % replace entries with fewer than minimum # of samples with 0 then replace with NaN
    % then remove all rows that have NaNs for all variables
    TT2{:,:} = TT2{:,:} .* ~remove;
    TS = standardizeMissing(TT2,0);
    TS = rmmissing(TS,'MinNumMissing',width(TS));

end