%% Theremax Simulator %%
%
% Jackson Cornell
%

%% Testing %%

% read input audio
[input_audio, fs1] = audioread('gabagool.wav');
[target_audio, fs2] = audioread('theremin2.wav');
% splice audio
%input_audio = input_audio(550000:740000,1);
%target_audio = target_audio(250000:680000)';
input_audio = input_audio(1:500000,1);
target_audio = target_audio(1:680000)';
%spectrogram(input_audio,hamming(size(input_audio,1)/100),[],[],fs1);
% perform pitch shifting
y = pitch_matcher(input_audio, target_audio, fs1, fs2);
% output audio
soundsc(y,fs1);


%% Functions %%

% matches input pitch to target pitch
function [y] = pitch_matcher(input_audio, target_audio, fs1, fs2)
    % constants and variables
    w_len = 2048;
    % find amount of frames needed for input
    frames_cnt_input = 4*floor(length(input_audio)/w_len) - 1;
    input_pitch = zeros(frames_cnt_input, 1);
    % find amount of frames needed for target
    frames_cnt_target = 4*floor(length(target_audio)/w_len) - 1;
    target_pitch = zeros(frames_cnt_input, 1);
    % adjust pitch array if target less than input
    if (frames_cnt_input > frames_cnt_target)
        target_pitch(frames_cnt_target:frames_cnt_input) = 0;
    else
        frames_cnt_target = frames_cnt_input;
    end
    % find pitch of input
    for i=0:frames_cnt_input-3
        frame = input_audio(i*w_len/4+1:i*w_len/4+w_len).*hanning(w_len);
        input_pitch(i+1) = pitch_detection(frame, fs1);
    end
    % find pitch of target
    for i=0:frames_cnt_target-3
        frame = target_audio(i*w_len/4+1:i*w_len/4+w_len).*hanning(w_len);
        target_pitch(i+1) = CAMDF(frame, fs2);
    end
    % compute stretch array
    stretch_arr = hz2stretch(input_pitch, target_pitch);
    % do phase vocoder
    y = dynamic_phase_vocoder(input_audio, fs1, w_len, stretch_arr);
end

% changes pitch by scale controlled by modulator pitch
function [y] = pitch_offsetter(input_audio, modulator_audio, fs1, fs2)

end


%% Helper Functions %%

% circular average magnitude difference function for pitch detection
function [pitch] = CAMDF(x, fs)
    % variables
    L = size(x,1);
    D = zeros(L,1);
    % perform CAMDF
    min_val = 10000;
    prev_val = 0;
    min_i = 1;
    for m = 1:L/2
        Dm = 0;
        for n = 1:L
            Dm = Dm + abs(x(mod(n+m-1,L)+1) - x(n));
        end
        D(m) = Dm;
        if (Dm < min_val) && (Dm < prev_val)
            min_val = Dm;
            min_i = m;
        end
        prev_val = Dm;
    end
    pitch = fs / (min_i - 1);
    if (pitch >= 1600)
        pitch = 0;
    end
end

% fft based pitch detection
function [pitch] = pitch_detection(x, fs)
    mag = abs(fft(fftshift(x)));
    maximum = max(mag);
    if (maximum > length(x)/2)
        maximum = maximum - length(x)/2;
    end
    pitch = maximum * fs / length(mag);
end

% modified version of pitch_shift that modulates each frame by a different
% pitch
function [y] = dynamic_phase_vocoder(x, fs, w_len, stretch_arr)
    % constants and variables
    w = hanning(w_len);
    frame_cnt = length(stretch_arr);
    interp_index = floor(w_len./stretch_arr);
    y = zeros(length(x) + max(interp_index), 1);
    phi = zeros(w_len, 1);
    psi = zeros(w_len, 1);
    % iterate through each frame
    for n=0:frame_cnt-3
        % retrieve frame
        frame = x(n*w_len/4+1:n*w_len/4+w_len).*w;
        % perform phase vocoding
        [new_frame, phi, psi] = phase_vocoder_fft(frame, phi, psi, stretch_arr(n+1));
        % perform interpolation
        interp_frame = interpolation(new_frame.*w, stretch_arr(n+1));
        % overlap and add
        y(n*w_len/4+1:n*w_len/4+interp_index(n+1)) = y(n*w_len/4+1:n*w_len/4+interp_index(n+1)) + interp_frame;
    end
end

% changes size of frame by factor 'stretch' without frequency distortion
function [y, phi, psi] = phase_vocoder_fft(frame, phi0, psi0, stretch)
    % constants and variables
    w_len = length(frame);
    % calculate sprectrum
    X = fft(fftshift(frame));
    mag = abs(X);
    phase = angle(X);
    % calculate delta phi
    dphi = 2*pi*(0:w_len-1)' + unwrap_phase(phase-phi0-2*pi*(0:w_len-1)');
    % update phi and psi
    phi = phase;
    psi = unwrap_phase(psi0+dphi*stretch);
    % reconstruct spectral components
    Y = mag.*exp(i*psi);
    % calculate new frame
    y = fftshift(real(ifft(Y)));
end

% interpolation function for non-integer factors
function [y] = interpolation(x, stretch)
    L = floor(length(x)/stretch);
    t = 1+(0:L-1)'*length(x)/L;
    t_floor = floor(t);
    dt = t-t_floor; 
    x_ext = [x;0];
    y = x_ext(t_floor).*(1-dt)+x_ext(t_floor+1).*dt;
end

% unwraps phase to interval [0, 2pi] for phase vocoder
function [phase] = unwrap_phase(phi)
    phase = mod(phi+pi,-2*pi) + pi;
end

% converts pitch in Hz to stretch factor
function [stretch] = hz2stretch(pitch1, pitch2)
    stretch = ones(length(pitch1),1);
    for i=1:length(stretch)
        if (pitch1(i) ~= 0 && pitch2(i) ~= 0)
            stretch(i) = pitch1(i)/pitch2(i);
        end
    end
end