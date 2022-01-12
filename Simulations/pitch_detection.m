%% Pitch Detection %%
%
% Jackson Cornell
%
% http://www2.ece.rochester.edu/~zduan/teaching/ece472/projects/2014/Lio_Chen_SpeechPitchDetection.pdf
%

%% Testing %%

% input audio
[audio, fs] = audioread('theremin.wav');
frame = audio(360001:361024);
F = fft(frame);
n = 0:fs/1024:fs-1;
figure;
plot(n,F);

% test different algorithms
pitch_acf = ACF(frame, fs);
pitch_amdf = AMDF(frame, fs);
%pitch_hramdf = HRAMDF(frame, fs);
pitch_camdf = CAMDF(frame, fs);

%% Functions %%

function [pitch] = ACF(x, fs)
    % variables
    N = size(x,1);
    R = zeros(N,1);
    % perform ACF
    min_val = 10000;
    prev_val = 0;
    min_i = 1;
    for m = 2:N
        Rm = 0;
        for n = 1:N-m
            Rm = Rm + x(m)*x(n);
        end
        R(m) = Rm/N;
        if (R(m) < min_val) && (R(m) < prev_val)
            min_val = R(m);
            min_i = m;
        end
        prev_val = R(m);
    end
    pitch = fs / (min_i - 1);
    if (pitch == 2400)
        pitch = 0;
    end
end

function [pitch] = AMDF(x, fs)
    % variables
    N = size(x,1);
    D = zeros(N,1);
    % perform AMDF
    min_val = 10000;
    prev_val = 0;
    min_i = 1;
    for m = 1:N
        Dm = 0;
        for n = 1:N-m
            Dm = Dm + abs(x(n) - x(n+m));
        end
        D(m) = Dm/(N-m);
        if (D(m) < min_val) && (D(m) < prev_val)
            min_val = D(m);
            min_i = m;
        end
        prev_val = D(m);
    end
    pitch = fs / (min_i - 1);
    if (pitch == 2400)
        pitch = 0;
    end
end

function [pitch] = HRAMDF(x, fs)
    % variables
    N = size(x,1);
    D = zeros(N,1);
    % perform HRAMDF
    min_val = 10000;
    prev_val = 0;
    min_i = 1;
    for m = 1:N
        Dm = 0;
        for n = floor((N/2-m)/2)+1:floor((N/2-m)/2+N/2)
            Dm = Dm + abs(x(n) - x(n+m));
        end
        D(m) = Dm;
        if (Dm < min_val) && (Dm < prev_val) 
            min_val = Dm;
            min_i = m;
        end
        prev_val = Dm;
    end
    pitch = fs / (min_i - 1);
    if (pitch == 2400)
        pitch = 0;
    end
end

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
    if (pitch == 2400)
        pitch = 0;
    end
end