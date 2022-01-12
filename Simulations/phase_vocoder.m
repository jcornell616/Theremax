%% Phase Vocoder %%
%
% Jackson Cornell
%
% https://www.youtube.com/watch?v=2Esfl8uw-2U
% https://www.mathworks.com/help/audio/ug/pitch-shifting-and-time-dilation-using-a-phase-vocoder-in-matlab.html;jsessionid=d02066dc208d93e622199bfa008d
% http://blogs.zynaptiq.com/bernsee/pitch-shifting-using-the-ft/
% https://octovoid.com/2019/10/01/68/
%

%% Testing %%

% read audio
[audio, fs] = audioread('theremin.wav');
% pitch shift audio
audio_out = pitch_shift(audio, fs, 0.5);
% play output audio
soundsc(audio_out, fs);


%% Functions %%

% pitches input audio by a factor of 'stretch'
function [y] = pitch_shift(x, fs, stretch)
    % constants and variables
    w_len = 2048;
    w = hanning(w_len);
    frame_cnt = 4*floor(length(x)/w_len) - 1;
    interp_index = floor(w_len/stretch);
    y = zeros(length(x) + interp_index, 1);
    phi = zeros(w_len, 1);
    psi = zeros(w_len, 1);
    % iterate through each frame
    for n=0:frame_cnt-1
        % retrieve frame
        frame = x(n*w_len/4+1:(n/4+1)*w_len).*w;
        % perform phase vocoding
        [new_frame, phi, psi] = phase_vocoder_fft(frame, phi, psi, stretch);
        % perform interpolation
        interp_frame = interpolation(new_frame.*w, stretch);
        % overlap and add
        y(n*w_len/4+1:n*w_len/4+interp_index) = y(n*w_len/4+1:n*w_len/4+interp_index) + interp_frame;
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


%% Helper Functions %%

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

% example phase vocoder from "Digital Audio Effects" textbook from which
% custom algorithm is based off of
function [DAFx_out] = DAFX_phase_vocoder(DAFx_in, FS)
    n1 = 256;
    n2 = 0.8*n1;
    tstretch_ratio = n2/n1;
    WLen = 2048;
    w1 = hanning(WLen);
    w2 = w1;
    L = length(DAFx_in) ;
    DAFx_in = [zeros(WLen, 1); DAFx_in; zeros(WLen-mod(L,n1) ,1)] / max(abs(DAFx_in));
    %----- for linear interpolation of a grain of length WLen -----
    lx = floor(WLen*n1/n2);
    %----- lnitializations -----
    DAFx_out = zeros(lx+length(DAFx_in) ,1);
    omega = 2*pi*n1*[0:WLen-1]'/WLen;
    phi0 = zeros(WLen, 1);
    psi = zeros(WLen , 1);
    tic
    pin = 0;
    pout = 0;
    pend = length(DAFx_in)-WLen; 
    while pin < pend
        grain = DAFx_in(pin+1:pin+WLen).*w1;
        f = fft(fftshift(grain));
        r = abs(f);
        phi = angle(f);
        delta_phi = omega + unwrap_phase(phi-phi0-omega);
        phi0 = phi;
        psi = unwrap_phase(psi+delta_phi*tstretch_ratio);
        ft = (r.* exp(i*psi));
        grain = fftshift(real(ifft(ft))) .*w2;
        %----- interpolation
        grain3 = interpolation(grain, tstretch_ratio);
        %plot(grain);drawnow;
        % ...........................................
        DAFx_out(pout+1:pout+lx) = DAFx_out(pout+1:pout+lx) + grain3;
        pin = pin + n1;
        pout = pout + n1;
    end
    %wwmnnnnrwvvwwvwrrvuuwrruuuwuuuwu
    toc
    DAFx_out = DAFx_out(WLen+1:WLen+L) / max(abs(DAFx_out));
    %soundsc(DAFx_out , FS);
end