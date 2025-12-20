function ex = preprocess_signal(ex)

ex = reject_artefacts(ex);
ex = bandpass_filter(ex);
ex = denoiser(ex);