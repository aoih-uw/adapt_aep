# Posthoc pipeline bug audit — `posthoc_preprocess_menu`

Audit of everything reachable from `src/matlab/posthoc/posthoc_preprocess_menu.m`.
Repo state: `main` @ `9ecd02a`.

## Call map

```
posthoc_preprocess_menu.m                    (script, base workspace, loops subjids)
├─ posthoc_load_my_file.m                    (fn)  -> grand_ex_save
├─ posthoc_sort_data.m                       (fn)  -> meta, org_data
│  ├─ posthoc/get_kept_trials.m              (fn)  [DUPLICATE in posthoc/utilities/]
│  ├─ utilities/extract_stim_ON_OFF.m        (fn)
│  ├─ utilities/calc_fft_complex.m           (fn)
│  └─ utilities/find_fft_bins.m              (fn)
├─ posthoc_hydrophone_analysis.m             (SCRIPT) -> hydro_results
│  └─ utilities/select_chan_color.m -> utilities/tableau_10.m
├─ posthoc_resp_consist.m                    (SCRIPT) -> T_ON_2f
├─ posthoc_waterfall.m                       (SCRIPT) -> figures only
├─ posthoc_bootstrap_sim.m                   (SCRIPT) -> sim_results
│  ├─ utilities/execute_cumu_avg_bootstrap.m (fn)
│  │  ├─ utilities/calculate_bootstrap.m  (bootstrp)
│  │  └─ posthoc/utilities/complex_bf.m
│  ├─ plot_logBF.m
│  ├─ sim_trial_count_heatmap.m
│  ├─ utilities/plot_2f_growth_func.m -> utilities/param_softplus.m
│  ├─ fit_low_CI_model.m              -> utilities/param_softplus.m
│  └─ convert_sim_data_to_long.m
├─ utilities/apply_tufte.m
└─ utilities/save_figs_to_ppt.m
```

Four of the six stages are **scripts run in the base workspace**, not functions. They
communicate through shared variable names (`meta`, `org_data`, `hydro_results`,
`sim_results`, `T_ON_2f`). That is the root cause of several findings below.

Config at audit time (`setup/setup_info.m`): `stim_name = {'ONOFF'}` (1 type),
`stim_freqs = [55 100 410]`, `test_amplitudes = {83:3:140, 95:3:140, 116:3:140}`
(20/16/9 amps), `trials_per_block = 10`, `max_trials = 260`, 4 channels
(`Forebrain, Subcranial, Subcutaneous, EKG`).

---

## CRITICAL

### C1. Crash when any amplitude has fewer than 260 kept trials
`utilities/execute_cumu_avg_bootstrap.m:66-80`

```matlab
if size(cur_ON,1) < max_batches*trials_per_block
    fprintf('Not enough trials at %d dB and Channel %d\n', ...);   % warns
end                                                               % ...then continues
...
n_per_phase = (idx+trials_per_block-1)/length(phases);
phase_idx   = find(cur_phase == phases(ip));
inc_select  = [inc_select; phase_idx(1:n_per_phase)];             % unguarded
```

`max_batches = 260/10 = 26`, so the last iteration needs `phase_idx(1:130)` for
each of the two polarities — i.e. exactly 260 kept trials at every
(amplitude, channel, frequency). Any amplitude short of that (session ended
early, heavy artefact rejection, a partial file) indexes past the end and
throws `Index exceeds the number of array elements`. The code detects the
condition and prints a warning, then walks straight into the crash.

Fix: cap the loop at the data actually present.
```matlab
max_avail = min(arrayfun(@(p) sum(cur_phase==p), phases));
for ibatch = 1:min(max_batches, floor(max_avail*length(phases)/trials_per_block))
```

Same class of bug, same cause: `posthoc_waterfall.m:72`
`randperm(length(cur_phase_idx), n_per_phase)` errors if fewer than 128 trials
of a polarity survive.

### C2. Subject loop does not reset the workspace — cross-subject contamination
`posthoc_preprocess_menu.m:4-56`

`clearvars` runs once, *before* the loop. The stage scripts write into the base
workspace and nothing is cleared between subjects. Concretely:

* `posthoc_bootstrap_sim.m:173` does `sim_results(ifreq) = ...` with no
  preallocation. If subject 1 had 3 frequencies and subject 2 has 2, subject 2's
  saved file contains **subject 1's third frequency**.
* `hydro_results` / `T_ON_2f` are overwritten wholesale, so they are safe — but
  only by accident. If any stage errors mid-way for subject 2, the `save` on
  line 44 silently writes subject 1's values under subject 2's filename.
* No figures are ever closed. `save_figs_to_ppt` (line 33) does
  `findobj(groot,'Type','figure')` — **every open figure**. Subject 2's deck
  contains all of subject 1's figures.

Fix: at the top of the loop body, `clearvars -except subjids isubj` and
`close all`.

### C3. Threshold line plotted from the previous channel
`fit_low_CI_model.m:6, 73-79, 93`

```matlab
cur_thresh = NaN;              % line 6 — set ONCE, outside the channel loop
for ichan = 1:length(my_chans_name)
    ...
    if y_vec(1) < 0
        cross_idx = find(y_vec >= 0, 1, 'first');
        if ~isempty(cross_idx)
            cur_thresh = x_vec(cross_idx);          % only assigned on success
            low_growth.thresh_ci(ichan) = cur_thresh;
        end
    end
    ...
    xline(cur_thresh, '--', sprintf('%.2f dB', cur_thresh), ...)   % line 93
```

If channel *n* has no zero crossing, `cur_thresh` still holds channel *n-1*'s
value and gets drawn and **labelled in dB on channel *n*'s panel**. The saved
`low_growth.thresh_ci(ichan)` is correctly NaN, so the figure and the data
disagree — the figure is the one people read.

Fix: `cur_thresh = NaN;` as the first line inside the channel loop.

### C4. Failed and boundary-pinned model fits are saved as thresholds
`fit_low_CI_model.m:63, 102`

`param_softplus` returns `fit_ok` (exit flag > 0 **and** no parameter pinned to a
bound). `fit_low_CI_model` captures it and never reads it — `low_growth.p` and
`thresh_ci` are written unconditionally at line 102. A non-converged fit is
indistinguishable from a good one downstream.

Two ways the fit degenerates, both reachable:

* `param_softplus.m:9` is `(p(1)/p(2))*log1p(exp(p(2).*(x-p(3))))` with
  `lb(2) = 0`. At the bound this is `0/0`.
* the same line overflows: `exp()` of `p(2)*(x-p(3))` with `p(2)` unbounded above
  and a ~57 dB x-range saturates to `Inf` well before `p(2)=1`. Use the stable
  form `z = p(2).*(x-p(3)); max(z,0) + log1p(exp(-abs(z)))`.

Fix: gate on `fit_ok` before writing `p`/`thresh_ci`, and bound `p(2)` away from 0
(`lb(2) = 1e-3`).

### C5. The whole pipeline is non-reproducible
No `rng` call anywhere in the posthoc path (only `rng('shuffle')` in
`setup/setup_info.m`, which is experiment-time).

Three unseeded random sources feed the published numbers:
`bootstrp` (`calculate_bootstrap.m:16`), the two `randperm` calls in
`execute_cumu_avg_bootstrap.m:126-127`, and `randperm` in
`posthoc_waterfall.m:72`.

Because `resp_found` is a threshold test on a bootstrap percentile
(`lower_CI > 0`), any batch sitting near the boundary flips between runs. That
changes `resp_found_vec`, which selects which batch `fit_low_CI_model` reads
(line 32), which moves the softplus fit, which moves the **threshold in dB**.
Re-running the same data gives a different answer.

Fix: `rng(<fixed seed>)` at the top of `posthoc_bootstrap_sim.m`, and record the
seed in `meta`.

### C6. `target_freq_range` is overwritten mid-loop (Timed path)
`posthoc_sort_data.m:41, 272, 377-381`

```matlab
target_freq_range = meta.target_freq_range;     % 3 Hz, line 41
...
[temp_ON_2f(itrial), ~] = find_fft_bins(target_freq, target_freq_range, ...);  % line 272
...
if strcmp(meta.exp_type,'Timed')
    target_freq_range = diff(tmp_freq_vec_OFF(1:2));      % line 378 — clobbers it
end
```

From trial 2 onward, the **ON** bin search uses the OFF window's bin width
instead of ±3 Hz. Silent: no error, just a different bin-selection rule for
trial 1 versus every other trial. Only bites `exp_type = 'Timed'`; the current
`'Mixed freqs'` run is unaffected.

Fix: use a separate variable, e.g. `off_freq_range`.

---

## HIGH

### H1. Error bars do not describe the plotted quantity
`utilities/execute_cumu_avg_bootstrap.m:92-93`

```matlab
cur_diff_mean = abs(mean(cur_ON_batch)) - abs(mean(cur_OFF_batch));   % difference of magnitudes
cur_diff_sem  = abs(std(cur_ON_batch - cur_OFF_batch))/sqrt(n);       % spread of complex differences
```

Plain-language version: the dot is "how tall the ON average is minus how tall the
OFF average is". The error bar is "how much the ON and OFF *arrows* disagree
trial by trial, including their directions". Those are different measurements.
Two trials can have identical heights but point opposite ways — that contributes
nothing to the dot and a lot to the error bar. So the shaded band in
`posthoc_bootstrap_sim.m:158` and the error bars in `plot_2f_growth_func.m:56`
are systematically too wide and are not a standard error of the plotted statistic.

The bootstrap already computes the right thing — `simu.diff.sem` is the standard
deviation of the bootstrap distribution of exactly `abs(mean(on)) - abs(mean(off))`.
Fix: plot `simu.diff.sem`, or set
`cur_diff_sem = std(bootstat)` from the same call.

(`abs()` around `std` is a no-op — `std` of a complex vector is already real and
non-negative.)

### H2. Dead guard on the hydrophone target bin
`posthoc_hydrophone_analysis.m:63-66` and `81-84`

```matlab
targ_idx = find(freq_vec_OFF == target_freq);
if freq_vec_OFF(targ_idx) ~= target_freq
    keyboard
end
```

Two problems:
1. The check is tautological. `find` only returns indices where the values are
   already equal, so the branch can never be true when `targ_idx` is non-empty.
2. When `targ_idx` **is** empty — the case the guard was written for —
   `freq_vec_OFF([]) ~= target_freq` is an empty logical, and `if []` is false in
   MATLAB. Execution falls through to `my_noise_floor(itrial,iamp,ifreq) = <1x0>`
   and dies with an unrelated "size of the left side is 1-by-1" message,
   thousands of iterations later.

The exact float equality currently works only by luck: `select_experiment_stim_params.m`
forces the analysis window to `fs/5` samples, so bins are exactly 5 Hz apart and
55/100/410 land exactly. Change `desired_freq_res` and every hydrophone number
disappears.

Fix:
```matlab
[d, targ_idx] = min(abs(freq_vec_OFF - target_freq));
assert(d <= 0.5*mean(diff(freq_vec_OFF)), 'no bin near %g Hz', target_freq);
```
and hoist it out of the `itrial` loop — it is recomputed per trial for no reason.

### H3. OFF arrays have no stimulus-type dimension — cross-type overwrite
`posthoc_sort_data.m:55, 289, 294, 360-373`

`OFF_2f`, `OFF_fft`, `hydro_OFF_fft` are allocated with size 1 on the stim-type
dimension and always written at index `1`, but `row_range` is derived from
`ON_2f(:, amp_idx, stim_type_idx, ...)` — which is **per stim type** and
therefore restarts at row 1 for each type.

`OFF_2f` is protected by the `if strcmp(cur_stim_type,'ONOFF')` guard at line 393.
`OFF_fft` and `hydro_OFF_fft` are **not** — lines 368 and 371 write
unconditionally. The moment `info.mixed.stim_name` contains more than one entry,
`trim` batches and `ONOFF` batches write to the same rows and the later one wins.
That silently corrupts the hydrophone noise floor and the waterfall Stim-OFF and
ON−OFF panels.

Latent today (`stim_name = {'ONOFF'}`), but `create_new_stimuli_block.m:21-37`
and `count_mixed_trials.m:74-80` both handle a two-type schedule, so this is one
config change away.

Fix: give the OFF arrays a full stim-type dimension and index them with
`stim_type_idx`.

### H4. `posthoc_resp_consist` silently analyses only stim type 1, and breaks outright with two
`posthoc_resp_consist.m:33-36`

```matlab
tmp      = permute(squeeze(ON_2f(:,:,1,:,ifreq)),      [1 3 2]);   % stim type pinned to 1
tmp_time = permute(squeeze(time_vec(:,1,:,:,:,ifreq)), [1 3 2]);   % stim type NOT pinned
```

The two lines disagree. With one stim type both squeeze to
`(rows × amp × chan)` and it works. With two, `time_vec` squeezes to a 4-D
`(rows × amp × type × chan)` and `permute(...,[1 3 2])` throws
*ORDER must have at least N elements*. `T_ON_2f` — which is saved to the summary
file — therefore covers only stim type 1 with no record that it did.

Fix: `time_vec(:,1,:,1,:,ifreq)` and pull the `1` into a named variable shared
with the `ON_2f` line.

### H5. File selection is fragile and fails unhelpfully
`posthoc_load_my_file.m:14-27`

```matlab
current_folder = dir(subject_folder);                       % 'D:\...\*_42*'
my_path = sprintf('%s/%s/%s', base_dir, current_folder.name, file_type);
...
files = dir(sprintf('*%s_%s_*_%s_%s*', subjid, stim_freq, stim_amp, file_type));
if isempty(files)
    fprintf('No files found')                               % no return/error
else
    my_names = {files.name};
end
for iname = 1:numel(my_names)                               % undefined variable
```

* **No files** → prints a message, then dies on `Unrecognized function or variable
  'my_names'`. Should `error(...)`.
* **Multiple matching folders** → `current_folder.name` expands to a
  comma-separated list, `sprintf` recycles the format string, and you get a
  garbage path. `*_42*` also matches `_420`, `_421`. Same for the file glob:
  `*42_*` matches subject 142.
* Files are consumed in `dir` order (alphabetical), which is only chronological
  if the names happen to sort that way. The whole cumulative-averaging
  simulation assumes rows are in acquisition order.

Fix: `assert(isscalar(current_folder))`, anchor the subject pattern
(`sprintf('*_%d_*', subjid)`), `error` on empty, and sort files explicitly by
`[files.datenum]`.

### H6. Two incompatible `get_kept_trials` on the path
`posthoc/get_kept_trials.m` (8 args, 5 outputs) vs
`posthoc/utilities/get_kept_trials.m` (7 args, 2 outputs, hardcoded `10`, and a
`grand_ex_save{iname,isubj}` indexing convention the current data does not use).

`addpath(genpath(...))` puts both on the path. It currently resolves to the
`posthoc/` copy only because `genpath` lists a parent before its children. Any
change to how the path is set produces
`Too many output arguments` from a line that looks correct.

Fix: delete `posthoc/utilities/get_kept_trials.m`. It is the only duplicated
filename in the whole tree.

### H7. Missing `round()` on ramp samples
`posthoc_sort_data.m:120`

```matlab
ramp_duration_samples = grand_ex_save{1,iname}.info.stimulus(freq_idx).ramp_duration_ms/1e3*fs;
```

Every other site in the codebase rounds — `count_mixed_trials.m:24`,
`calculate_hydrophone_sig_quality.m:10`, `measure_calibration_stimuli.m:39`.
`ramp_duration_ms` is itself derived as `samples/fs*1e3`
(`select_experiment_stim_params.m:29`), so the round trip through milliseconds
can land on `4810.999999999999`. That value is then used as an array subscript
in `extract_stim_ON_OFF.m:40`, which requires an integer.

Fix: wrap in `round()` to match the rest of the codebase.

---

## MEDIUM

| # | Location | Issue |
|---|---|---|
| M1 | `convert_sim_data_to_long.m:44-45` | `low_growth.trials` (a trial **count**) is written into a column named `STD`. Anything downstream reading `STD` as a dispersion measure is wrong. |
| M2 | `calculate_bootstrap.m:8-20` | `CI_vec = 99` produces a **two-sided** 99% interval, then `resp_found = lower_CI > 0` uses only the lower edge. The effective one-sided false-positive rate is 0.5%, not 1% — but `CI` is recorded as `99` in the output table. The comment still says "99.9% CI". Conservative, but mislabelled in the saved results. |
| M3 | `param_softplus.m:13` | `weight_vec = sqrt(1./trials_needed)` is inverted. More trials means *less* noise, so weight should rise with n (`sqrt(trials_needed)`). Currently dormant — both callers pass `weight_data = 0`. |
| M4 | `param_softplus.m:32` | `s = max(std(cur_data(amp_vec < min+0.3*range)), eps)`. If that mask selects 0 or 1 points, `s` collapses to `eps` and `asinh(y/eps)` flattens the entire fit. Guard with a fallback such as `std(cur_data)`. |
| M5 | `select_chan_color.m` | No `else` — `select_chan_color(5)` errors with *Output argument "cur_color" not assigned*. Also called as `select_chan_color(ifreq)` in `posthoc_hydrophone_analysis.m:216`, so a 5th stimulus frequency breaks the hydrophone figure. |
| M6 | `posthoc_sort_data.m:409` | `org_data.freq_vec_OFF = select_freq_vec_hydro_OFF` stores the **hydrophone** frequency axis under the generic OFF name; the AEP `select_freq_vec_OFF` (line 338) is computed and never used. Both are undefined if no trial ever runs with `ichan == 1`. |
| M7 | `posthoc/get_kept_trials.m:5-20` | The single-batch branch takes the **raw block** without applying `kept_trials_idx`. The `keyboard` guard that catches this is wrapped in `strcmp(cur_exp_type,'Mixed freqs')`, so on the Timed path rejected trials are silently analysed. |
| M8 | `posthoc_sort_data.m:94` | `single_batch_locs = 1:20` hardcoded for Timed — silently drops batches 21+ or references batches that do not exist. |
| M9 | `posthoc_bootstrap_sim.m:139`, `plot_logBF.m:5`, `execute_cumu_avg_bootstrap.m:12`, `posthoc_resp_consist.m:57` | `tiledlayout(5,4)` / `(4,5)` gives exactly 20 tiles. The 55 Hz amplitude vector `83:3:140` is exactly 20 entries. One more amplitude and `nexttile` errors. Use `ceil(sqrt(n))` or pass the count. |
| M10 | 39 `keyboard` calls under `posthoc/` and `utilities/` | Unattended or batch runs hang at a debug prompt instead of failing. Several sit on genuine data-integrity conditions (`posthoc_sort_data.m:107, 147, 231, 387`) that deserve `error()` with context. |
| M11 | `posthoc_load_my_file.m:3,16`, `posthoc_sort_data.m:423`, `posthoc_preprocess_menu.m:43` | Four `cd()` calls with no restore. The working directory at the end of the run depends on which stage last succeeded, and `save_figs_to_ppt`'s `git rev-parse` provenance stamp is taken relative to it. Use absolute paths / `fullfile` instead. |
| M12 | `posthoc_bootstrap_sim.m:137` | Channel 4 is EKG (`setup_info.m:56`). It is bootstrapped, fitted, and given a threshold like an AEP channel. `reject_artefacts_mixed.m:6` explicitly excludes it from artefact rejection; the posthoc analysis does not exclude it from anything. |
| M13 | `sim_trial_count_heatmap.m:38` | `cur_data(cur_data == max_trials) = NaN` renders "260 trials, never found a response" in the same grey as "no data". Those are different outcomes. |
| M14 | `fit_low_CI_model.m:57` | `if any(isnan(cur_y)), continue; end` — a single NaN amplitude discards the entire channel's threshold. Fit the non-NaN subset instead. |
| M15 | `fit_low_CI_model.m:87` | `max_batch = (max_trials/10)` hardcodes `trials_per_block`; the parameter is already in scope. Marker opacity is also unclamped and can exceed 1. |
| M16 | `posthoc_waterfall.m:61-64, 101` | `nan_rows` ORs the ON and OFF masks, so once H3 is fixed (or a second stim type appears) valid ON trials get deleted because the OFF slice is empty for that type. `cur_mean` at line 101 is read after the amplitude loop and is undefined if `amp_vec` is empty. |
| M17 | `fit_low_CI_model.m:25-33` | `low_growth.mean` is read at the batch where the simulation *stopped* — i.e. the first batch whose lower CI crossed zero. That value is selected *because* it is just above zero, so it is biased upward at exactly the amplitudes near threshold. This is inherent to simulating the adaptive protocol, but the resulting threshold inherits the stopping bias and should be reported as such (or compared against the fixed-260-trial fit). |
| M18 | `posthoc_preprocess_menu.m:8` | `addpath(genpath('C:\Users\Aoi Hunsaker\Desktop\adapt_aep\src\matlab\'))` is an absolute machine-specific path inside the loop. Derive it from `fileparts(mfilename('fullpath'))`. |

---

## Verified correct (checked, no action)

These looked suspicious and are fine — recording so they are not re-audited:

* **Retry-group detection** (`posthoc_sort_data.m:83-91`). `collection_attempts`
  is 0-based (`reject_artefacts_mixed.m:41`), so appending a sentinel `0` and
  using `first = last + att_diff(last)` is correct for single batches, interior
  groups, and a group at the end of a file.
* **`kept_trials_idx` row mapping.** `get_kept_trials` builds `temp_sigs` in
  block-major order with `trials_per_block` stride, matching
  `collapse_raw_data.m:17-21` exactly, so the rejection indices apply to the
  right rows.
* **Per-frequency amplitude indexing.** `ON_2f` dim 2 is sized to the longest
  amplitude vector (20) and indexed by position within `amp_vecs{freq_idx}`.
  `posthoc_resp_consist.m:34` (`tmp(:,:,1:numel(amp_vec))`) and
  `posthoc_hydrophone_analysis.m:52` both respect that convention.
* **`find_fft_bins` peak picking.** With `desired_freq_res = 5` the analysis
  window is `fs/5` samples, bins are 5 Hz apart, and `target_freq_range = 3`
  selects exactly one bin — so there is no per-trial bin hopping today. It
  *would* appear if the frequency resolution were made finer, and would bias the
  noise floor low (noise picks a random peak, signal picks a consistent one),
  inflating `abs(mean(ON)) - abs(mean(OFF))`.
* **`complex_bf`.** Behaves as documented: under H0, `R ≈ 1/n` so `logBF → -log(1+gn)`
  and drifts to negative evidence; under H1 with fixed `R`, the `n*log1p(R)` term
  grows linearly and wins. `bootstrp` with two data arguments resamples them with
  shared row indices (paired), which is what the ON/OFF design wants, and the two
  `randperm` calls at lines 126-127 correctly break that pairing for the
  noise-vs-noise null.
* **Hydrophone long-table construction** (`posthoc_hydrophone_analysis.m:164-193`).
  Each `(amp, freq)` column is compacted from row 1, so the global trailing-NaN
  removal preserves alignment, and `n_row` matches the triple loop exactly.
