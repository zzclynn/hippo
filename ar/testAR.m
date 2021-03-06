function [A,m] = testAR()

sampling_rate = 10^3;%2*1.5;
duration = 2;
freq = 50;
df = .05*freq;
gap = 1;
figsOn = 0;

ts_noise = randn(duration*sampling_rate,1);
%[cMor1 times] = cmorwavf(-lenWav/2,lenWav/2,lenWav*sampling_rate,df,freq);

cMor = getMor(freq,df,sampling_rate,5);
A = conv(ts_noise,cMor,'same');
dPhase = getDiffs(A,gap);
A = dPhase;%angle(A);%
dPhase = dPhase/gap*sampling_rate/2/pi;
figure;plot(dPhase);
%m = arx(iddata(A),2);
%figure;plot(ts_noise);hold on;plot(real(A),'r');%plot(filter(1,arEst,ts_noise),'g');
Am = mean(A);A = A-Am;
allDat(1,:) = real(A)+Am;%/max(real(A));
figure;hold all;plot(hist(A,-pi:.1:pi));%(log(abs(fft(A))));getDiffs(A,gap)
imp = zeros(size(A));imp(100) = 1;
for i = 1:3
    m = ar(A,i,'yw','ppw'); %arx(iddata(A),i)
    [a b] = tfdata(m);
    [a{1} b{1}];
    temp = filter(a{1},b{1},ts_noise(1:(end-gap))/600);%%imp30
%    temp1 = real(arData(ts_noise/100,b{1}));
    plot(hist(temp,-pi:.1:pi));%(log(abs(fft(temp))));getDiffs(temp,gap)
%    temp = real(temp);
    allDat(i+1,:) = temp+Am;%/max(temp);
%    allDat1(i+1,:) = temp1/max(temp1);
end
sPlot(allDat);%(:,2000:5000)
%sPlot(allDat1);
allDat = cumsum(allDat,2);
%sPlot(allDat(:,2000:5000));
allDat = exp(1j*allDat);
sPlot(allDat);%(:,2000:5000)

allDat = abs(fft(real(allDat),[],2));
figure;plot(allDat');

if figsOn
    figure;plot(dPhase,'r');
    figure;hist(dPhase,-pi:.05:pi);
    figure;hist(diff(abs(A)),50);
    figure;plot(ts_noise);hold on;plot(real(A),'r');
end

function dPhase = getDiffs(sig,gap)
angleA = angle(sig);
angleB = asin(imag(sig)./abs(sig));
figure;plot(angleA((gap+1):end)); hold on;plot(angleA(1:(end-gap)),'r');
plot(real(3*exp(1j*angleA)),'m');
plot(real(sig*3),'k');plot(imag(sig*3),'k--');
%dPhase = angleA((gap+1):end) - angleA(1:(end-gap));%diff(angle(A));
%dPhase = mod(dPhase+pi,2*pi)-pi;
dPhase = circ_dist(angleA((gap+1):end),angleA(1:(end-gap)));
%dPhase(dPhase < 0) = dPhase(dPhase < 0) + 2*pi;


function w = getMor(freq,sd,rate,ns)
st = 1./(2*pi*sd);%df;%
w_sz = ns*st*rate; % half time window size
t = (-w_sz:(w_sz+1))/rate;
w = exp(-t.^2/(2*st^2)).*exp(2j*pi*freq*t)/sqrt(sqrt(pi)*st*rate);

function y = arData(x,b)
y = x;
%temp = zeros(numel(x),numel(x));
for i = 1:numel(x)
    for j = max(1,i-numel(b)+1):(i-1)
        y(i) = y(i) + y(j)*b(i-j+1);
%        temp(i,j) = real(b(i-j+1));
    end
end
%rho=b(2:end);
% y2=x;
% I=2;
% while I<=length(x);
%    y2(I)=y2(I-1)*rho+x(I);
%    I=I+1;
% end