clc; clear;
fs=44e3; 
record_time = 10;

%record 1
recorder = audiorecorder(fs,16,1,-1); %record and save voice
disp('Start speaking')
recordblocking(recorder, record_time);
disp('End of recording')

voice1 = getaudiodata(recorder);
filename = 'orig_voice1.wav';
audiowrite(filename,voice1,fs);
%sound(voice1,fs);

%record 2
recorder = audiorecorder(fs,16,1,-1); %record and save voice
disp('Start speaking')
recordblocking(recorder, record_time);
disp('End of recording')

voice2 = getaudiodata(recorder);
filename = 'orig_voice2.wav';
audiowrite(filename,voice2,fs);
%pause(record_time); sound(voice2,fs);

figure;
subplot(2,1,1); plot(voice1); title('Record 1');
xlabel('Samples in Time');
ylabel('Magnitude');
subplot(2,1,2); plot(voice2); title('Record 2');
xlabel('Samples in Time');
ylabel('Magnitude');

%%
%add gaussian noise to recordings
noisy_voice1 = gaussian_noise_adder(voice1, fs, record_time);
filename = 'Noisy_voice1.wav';
audiowrite(filename,noisy_voice1,fs);
%pause(record_time); sound(noisy_voice1 ,fs);

noisy_voice2 = gaussian_noise_adder(voice2, fs, record_time);
filename = 'Noisy_voice2.wav';
audiowrite(filename,noisy_voice2,fs);
%pause(record_time); sound(noisy_voice2 ,fs);

figure; 
subplot(2,1,1); plot(noisy_voice1); title('Record 1 with noise');
xlabel('Samples in Time');
ylabel('Magnitude');
subplot(2,1,2); plot(noisy_voice2); title('Record 2 with noise');
xlabel('Samples in Time');
ylabel('Magnitude');

%add echo to noisy recordings
echoed_noisy_voice1 = add_echo(noisy_voice1, fs);
filename = 'echoed_noisy_voice1.wav';
audiowrite(filename,echoed_noisy_voice1,fs);
%pause(record_time); sound(echoed_noisy_voice1 ,fs);

echoed_noisy_voice2 = add_echo(noisy_voice2, fs);
filename = 'echoed_noisy_voice2.wav';
audiowrite(filename,echoed_noisy_voice2,fs);
%pause(record_time); sound(echoed_noisy_voice2 ,fs);

%%
%filter first recording with LMS Adaptive Filter and extract filter's impulse response:
desired1= [voice1 ; zeros( length(echoed_noisy_voice1)-length(voice1), 1 ) ]; %zero-padding to adapt size
[lms_filtered_voice1 , h_lms] = lms_filter(echoed_noisy_voice1', desired1);
%pause(record_time); sound(lms_filtered_voice1,fs);
filename = 'lms_filtered_voice1.wav';
audiowrite(filename,lms_filtered_voice1,fs);
L=length(desired1);
figure;
plot( -(L-1):(L-1) , conv( desired1(end:-1:1) ,lms_filtered_voice1 ) );
xlabel('Samples in Time');
ylabel('Magnitude');
title("First recording filtered by LMS Adaptive Filter");
subtitle('Autocorrelation Function with original voice');

%filter second recording with the former filter's impulse response:
lms_filtered_voice2 = conv( echoed_noisy_voice2 , h_lms);
filename = 'lms_filtered_voice2.wav';
audiowrite(filename,lms_filtered_voice2,fs);
%pause(record_time); sound(lms_filtered_voice2,fs);

desired2= [voice2 ; zeros( length(lms_filtered_voice2)-length(voice2), 1 ) ];
M=length(desired2);
figure;
plot( -(M-1):(M-1) , conv( desired2(end:-1:1) ,lms_filtered_voice2 ) );
xlabel('Samples in Time');
ylabel('Magnitude');
title("Second recording filtered by first filter's weights");
subtitle('Autocorrelation Function with original voice');
%%
% PART 2:

fc=150;
N=length(voice1); %number of samples
t=[0:(N-1)]*1/fs; %time vector
modulator=cos(fc*2*pi*t); %carrier signal
modulated =voice1 .* modulator'; %shifted signal
f_res = fs/(length(modulated)); %normalize frequency index
f_vector = [-length(modulated)/2 : length(modulated)/2-1]*f_res;

figure;
subplot(3,1,1); plot(f_vector ,fftshift (abs(fft(modulator))));
title("Modulator signal's FFT");
xlabel('Frequency [Hz]');
ylabel('Magnitude');
subplot(3,1,2); plot(f_vector ,fftshift (abs(fft(modulated'))));
title("Modulated signal's FFT");
xlabel('Frequency [Hz]');
ylabel('Magnitude');

%HPF:
fpass=200; %passband frequency of the filter in hertz
modulated_filtered = highpass(modulated,fpass,fs); %Filter with HPF

subplot(3,1,3); plot(f_vector ,fftshift (abs(fft(modulated_filtered))));
title('FFT of Modulated signal filtered by HPF');
xlabel('Frequency [Hz]');
ylabel('Magnitude');
filename = 'hpf_filtered_modulated_voice.wav';
audiowrite(filename,modulated_filtered,fs);
figure; 
subplot(3,1,1); plot(voice1); title('Original Recording 1');
xlabel('Samples in Time');
ylabel('Magnitude');
subplot(3,1,2); plot(modulated_filtered); title('Modulated signal filtered by HPF');
xlabel('Samples in Time');
ylabel('Magnitude');

%add noise and echo to signal
noisy_voice3 = gaussian_noise_adder(modulated_filtered, fs, record_time);
echoed_noisy_voice3 = add_echo(noisy_voice3, fs);
filename = 'echoed_noisy_voice3.wav';
audiowrite(filename,echoed_noisy_voice3,fs);
subplot(3,1,3); plot(echoed_noisy_voice3);
title('Echoed & Noisy Voice (after HPF)');
xlabel('Samples in Time');
ylabel('Magnitude');

%Filter with RLS Adaptive Filter
desired3= [voice1 ; zeros( length(echoed_noisy_voice3)-length(voice1), 1 ) ]; %zero-padding to adapt size
rls_filtered = rls_filter(echoed_noisy_voice3' , desired3, fs);
filename = 'rls_filtered_signal.wav';
audiowrite(filename,rls_filtered,fs);
%sound(rls_filtered,fs);

%Adaptive RLS Filter:
function y = rls_filter(x,d,fs)
lambda=0.999; %Forgetting Factor
rls = dsp.RLSFilter(8,'ForgettingFactor',lambda);
[y,e] = rls(x,d);
w = rls.Coefficients;

figure; title('RLS Adaptive Filter');
subplot(3,1,1); plot(y); %RLS Filter output
title('Output of RLS Adaptive Filter');
xlabel('Samples in Time');
ylabel('Magnitude');
subplot(3,1,2); plot(e); %RLS Filter Error Function
title('Error Function of RLS Adaptive Filter');
xlabel('Samples in Time');
ylabel('Magnitude');
subplot(3,1,3); stem(w); %RLS Filter Coefficients
title('Coefficients of RLS Adaptive Filter');
xlabel('Coefficients Number');
ylabel('Magnitude');

figure;
LL=length(d);
plot( -(LL-1):(LL-1) , conv( d(end:-1:1) ,y ) );
title('Autocorrelation of Data with Orginal Voice after RLS Adaptive Filter');
subtitle("Checks Efficiency of Filter");

f_res = fs/(length(d)); %normalize frequency index
f_vector = [-length(d)/2 : length(d)/2-1]*f_res;
figure;
subplot(2,1,1); plot(f_vector ,fftshift (abs(fft(d))));
title("Original-Voice's FFT");
xlabel('Frequency [Hz]');
ylabel('Magnitude');
subplot(2,1,2); plot(f_vector ,fftshift (abs(fft(y))));
title("Filter's Output FFT");
xlabel('Frequency [Hz]');
ylabel('Magnitude');

end

%Adaptive LMS Filter:
function [y,wts] = lms_filter(x,d)       %x- input signal, d- desired signal, y- filtered output   
mu = 0.007;                              %err- filter's error
lms = dsp.LMSFilter(55,'StepSize',mu);   %wts- weights needed to minimize the error between the output signal and the desired signal

[y,err,wts] = lms(x,d);            

figure;
subplot(3,1,1); plot(err) ;         
title("LMS Filter's Error Function");
xlabel('Samples in Time');
ylabel('Magnitude');
subplot(3,1,2); plot( wts ) ;
title("LMS Filter's weights");
xlabel('Samples in Time');
ylabel('Magnitude');

N=length(d);
subplot(3,1,3); plot( -(N-1):(N-1) , conv( d(end:-1:1) ,y ) ) ;
title('Autocorrelation of Noisy-Voice-with-Echo with Orginal Voice after LMS Adaptive Filter');
subtitle("Checks Efficiency of Filter");

%set filter's weights in a table
weight_num=[(1:length(wts))'];
weights_table=table(weight_num,wts)
end

%Echo generator:
function data_with_echo = add_echo(data, fs)
echo_every_sec = 0.1; %in seconds
echo_every_sec_in_samples = echo_every_sec *fs; %T=N*dt
tap_delay = [1 zeros(1,echo_every_sec_in_samples-1)...
    -0.5...
    zeros(1,echo_every_sec_in_samples-1)...
    0.25 ...
    zeros(1,echo_every_sec_in_samples-1)...
    -0.125
    ];
data_with_echo = conv ( tap_delay , data )';

figure;
L = length(data_with_echo);
plot( -(L-1):(L-1), xcorr (data_with_echo , data));
title('Correaltion Function between recording and echo- displays the effect of echo');
end

%gaussian-ditributed noise generator function: 
%generates the noise and adds it to the voice
function noisy_voice = gaussian_noise_adder(voice, fs, record_time)

RMS = rms(voice); % RMS calculation- noise will be normalized to 0.1*RMS
fprintf('The RMS of the voice signal is: %f\n', RMS);

%constructing noise:
f_vec=0:fs-1; 
f0=600; %Center Frequency
std=200; %Standard Deviation
gaus_in_freq = normpdf(f_vec, f0, std) + normpdf(f_vec, fs-f0, std);
figure; subplot(4,1,1); plot(f_vec,gaus_in_freq);
title('Gaussian in frequency domain')
xlabel('Frequency')
ylabel('Amplitude')

gaus_with_noise_in_freq = rand(1,fs).*gaus_in_freq ; 
subplot(4,1,2); plot(f_vec, gaus_with_noise_in_freq);
title('Gaussian noise in frequency domain')
xlabel('Frequency')
ylabel('Amplitude')

gaus_with_noise_in_Samples= ifft(gaus_with_noise_in_freq);
gaus_with_noise_in_Samples= gaus_with_noise_in_Samples(100:end-100); %cutting large edges
gaus_with_noise_in_Samples_normalized= (gaus_with_noise_in_Samples / var(gaus_with_noise_in_Samples)^0.5 ).*(0.1*RMS); %normalize
subplot(4,1,3); plot( real( gaus_with_noise_in_Samples_normalized));
title('Gaussian noise in time (digital) domain')
xlabel('Samples')
ylabel('Amplitude')

y=gaus_with_noise_in_Samples_normalized; %concatenate to match voice size
for i = 1:(record_time-1) 
    gaus_in_freq = normpdf(f_vec, f0, std) + normpdf(f_vec, fs-f0, std);

    gaus_with_noise_in_freq = rand(1,fs).*gaus_in_freq ; 

    gaus_with_noise_in_Samples= ifft(gaus_with_noise_in_freq) ;
    gaus_with_noise_in_Samples= gaus_with_noise_in_Samples(100:end-100);
    gaus_with_noise_in_Samples_normalized= (gaus_with_noise_in_Samples / var(gaus_with_noise_in_Samples)^0.5 ).*(0.1*RMS);
    
    x = gaus_with_noise_in_Samples_normalized ; 
    z=[x y];
    y=z;
end

z(record_time*(fs-199) : record_time*fs)= gaus_with_noise_in_Samples_normalized(1:(199*record_time+1)); %fill cutted edges with noise
z=real(z'); % match noise vector to voice's, and normalize
filename = 'gaussian_distributed_noise.wav';
audiowrite(filename,z,fs);

noisy_voice= voice+z; % create noisy voice

subplot(4,1,4); plot(z); % graph noise
title('Total noise')
xlabel('Samples')
ylabel('Amplitude')
end