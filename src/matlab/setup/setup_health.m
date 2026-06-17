function ex = setup_health(ex)
% Setup health
if ex.counter.ihealth > 0
    if isfield(ex.health(ex.counter.ihealth), 'time_stamp')
        ex.health(1).time_stamp = ex.health(ex.counter.ihealth).time_stamp;
        ex.health(1).electrodes_microV = ex.health(ex.counter.ihealth).electrodes_microV;
        ex.health(1).ekg_rate =  ex.health(ex.counter.ihealth).ekg_rate;
        ex.health(1).ekg_fs_ds =  ex.health(ex.counter.ihealth).ekg_fs_ds;
        ex.health(1).peak_threshold =  ex.health(ex.counter.ihealth).peak_threshold;
        for ihealth = 2:100
            ex.health(ihealth).time_stamp = NaN;
            ex.health(ihealth).electrodes_microV= NaN;
            ex.health(ihealth).ekg_rate = NaN;
            ex.health(ihealth).ekg_fs_ds = NaN;
            ex.health(ihealth).peak_threshold = NaN;
        end
    end
else 
    for ihealth = 1:100
        ex.health(ihealth).time_stamp = NaN;
        ex.health(ihealth).electrodes_microV= NaN;
        ex.health(ihealth).ekg_rate = NaN;
        ex.health(ihealth).ekg_fs_ds = NaN;
        ex.health(ihealth).peak_threshold = NaN;
    end
end
