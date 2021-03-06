function [coeff noise noise2] = complexAR(frac,figsOn,sig)

sampling_rate = 10^3;
duration = 100;
freq = 50;
df = frac*freq;
gap = 1;
numPred = 10;
modelSize = 4;
theNoise = 1;

if exist('sig','var')
    A = sig(:);
else
    ts_noise = makeComplex(duration*sampling_rate,theNoise,[1 1]);
    cMor = getMor(freq,df,sampling_rate,5);
A = conv(ts_noise,cMor,'same');
end
%[cMor1 times] = cmorwavf(-lenWav/2,lenWav/2,lenWav*sampling_rate,df,freq);
allDat(1,:) = A;%allDat1(1,:) = A;
for i = 1:modelSize
    [coeff noise(i)] = arburg(A,i);%armcov also
    thisNoise = makeComplex(numel(A),sqrt(noise(i)),[1 1]);
%    temp = filter(1,coeff,thisNoise);
%    allDat(i+1,:) = temp;
    allDat(i+1,:) = arData(thisNoise,coeff);
end
coeff
[r,p] = residue([1 zeros(1,modelSize-1)],coeff);
[b,a] = residue(ones(size(p)),p,1);
figure;hold all;
for j = 1:1
[varPred predVars] = getSpread(allDat(end,:),noise(end),modelSize,numPred,ceil(.9*numel(A)*rand),coeff);
for i = 1:size(varPred,2)
    plot(real(varPred(:)),imag(varPred(:)));
end
axis image;
end
allDat2 = arPred(allDat(end,:),coeff,numPred);
% bounds{1} = -1:.1:1;
% bounds{2} = bounds{1};
% figure;imagesc(hist3([real(A) imag(A)],bounds));
% temp = arData(makeComplex(100000,sqrt(noise(end)),[1 1]),coeff);
% figure;imagesc(hist3([real(temp) imag(temp)],bounds));
% figure;imagesc(hist3([real(thisNoise) imag(thisNoise)],[20 20]));
if figsOn
figure;plot(0:.01:pi/2,hist(getDiffs(allDat,1)',0:.01:pi/2));
figure;plot(0:.1:2,hist(abs(allDat)',0:.2:4));
%sPlot(real(bsxfun(@minus,allDat2,allDat2(1,:))));
% sPlot(exp(1j*angle(allDat)));
% allDat2a = getDiffs(allDat,gap);
P = zeros(numel(coeff)-1);
ac = abs(coeff);%rand(size(coeff));%
%nc = angle(coeff);
%coeff = ac.*exp(1i*nc);
%figure;plot(coeff(2:end));
% for i = 2:numel(coeff)
%     coeff(i) = ac(i)*exp((i-1)*1i*(-2.99));
% end
[r,p] = residue([1 zeros(1,modelSize-1)],coeff);
% angle(coeff)
% hold all;plot(coeff(2:end));title('me');
% coeff([4 5]) = coeff([5 4]);%coeff(5) = coeff(5)/1.01;
sPlot(real(allDat));
A = [-coeff(2:end);eye(numel(coeff)-1)];A(end,:) = [];

[sum(coeff(2:end)) angle(sum(coeff(2:end)))/pi+1]
[a b] = eig(A);b = diag(b);
figure;plot(abs(coeff));hold on;plot([1 5 10 10 5 1].*power(mean(abs(b)),1:6),'r');
for j = 1:50
for i = 1:modelSize
    a(:,i) = a(:,i)*b(i);
    temp(i,j) = abs(a(1,i));
end
%plot(a); axis image;xlim([-1 1]*max(abs(a(:))));ylim([-1 1]*max(abs(a(:))));
end
figure;plot(temp');
[a b2] = eig(cov(A)); b2 = diag(b2);
a(:,end)
%figure;plot(a(:,5)/norm(a(:,5)));hold all;plot(-complex(imag(coeff(2:end)),real(coeff(2:end)))/norm(coeff(2:end)));
[b abs(b) b2]
% figure;plot(a);axis image;
% figure;plot(angle(a));
% figure;plot(abs(a));
% figure;plot(abs(coeff(2:end)))
% getFit(coeff(2:end));
spots = -1:.01:1.2;
[x y] = meshgrid(spots);
grid = x + 1i*y;
dat = myDet(coeff(2:end),grid(:));
figure;hold all;imagesc(spots,spots,log(abs(reshape(dat,sqrt(numel(dat))*[1 1]))));%%plot(log(abs(myDet(coeff(2:end),0:.01:1.1))));
axis image tight;
%figure;hold all;plot(abs(b));
Q = P; Q(1,1) = noise(end);
for i = 2:size(allDat2,1)
    P = A*P*A' + Q;
    estNoise(i-1) = real(P(1,1));
    angDiff = circ_dist(angle(allDat2(i,:)),angle(allDat2(1,:)));
    vmHists(i,:) = hist(angDiff,-pi/2:.1:pi/2);
    vmHists(i,:) = vmHists(i,:)/sum(vmHists(i,:));
%     subplot(6,6,i-1);
%     plot(-pi/2:.1:pi/2,vmHists(i,:));
%     gamma(i) = real(circ_gamma(angDiff));
%     kappa(i) = circ_kappa(angDiff);
%     hold on;plot(-pi/2:.1:pi/2,circ_vmpdf1(-pi/2:.1:pi/2,0,kappa(i)),'r');
%     plot(-pi/2:.1:pi/2,circ_wcpdf(-pi/2:.1:pi/2,0,gamma(i)),'g');
%    set(gca,'YScale','log');
end
figure;imagesc(log(vmHists));
allDat2 = bsxfun(@minus,allDat2,allDat2(1,:));
%figure;hold all;
for i = size(allDat2,1):-1:1
%    scatter(real(allDat2(i,:)),imag(allDat2(i,:)));
    noise2(i,:) = [var((allDat2(i,:)))];% 1./kappa(i)];
end
figure;plot(log(noise2(2:end,:)));hold all;plot(log(estNoise));plot(log(predVars)');
end

function getFit(b)
b = [0 abs(b)];
c = [];
for i = 1:numel(b)
c = [c; i*ones(round(1000*b(i)),1)];
end
a = raylfit(c);%poiss
a = raylpdf(0:numel(b),a);
figure;plot(b/sum(b));hold on;plot(a,'r');


function d = myDet(coeff,b)
p = numel(coeff);
for i = 1:numel(b)
    d(i) = -(-b(i))^p;
    for j = 1:p
        d(i) = d(i) + ((-1)^(j+1)*coeff(j)*((-b(i))^(p-j)));
    end
end

function [varPred vars] = getSpread(signal,noise,p,steps,seed,b)
trials = 200;
signal = signal(seed:(seed+p-1));
varPred = zeros(trials,steps+p);
for k = 1:trials
    varPred(k,1:p) = signal;
    varPred(k,(p+1):end) = makeComplex(steps,sqrt(noise),[1 1]);
    for i = (p+1):(steps+p)
        for j = max(1,i-numel(b)+1):(i-1)
            varPred(k,i) = varPred(k,i) - varPred(k,j)*b(i-j+1);
        end
    end
end
varPred = varPred(:,(p+1):end);
vars = [var(varPred); var(real(varPred)); var(imag(varPred))];

function c = makeComplex(len,dev,ratio)
tot = sum(ratio.^2);
c = dev/sqrt(tot)*complex(randn(len,1)*ratio(1),randn(len,1)*ratio(2));

% function dVal = getDist(sig,gap)
% dVal = sig(:,(gap+1):end)-sig(:,1:(end-gap));
% %dVal = dVal*exp(-1j*angle(sig(:,(gap+1))));
% 
function dPhase = getDiffs(sig,gap)
angleA = angle(sig);
dPhase = circ_dist(angleA(:,(gap+1):end),angleA(:,1:(end-gap)));
% 
% function dPhase = getDiffsPred(sig,gap)
% angleA = angle(sig);
% dPhase = circ_dist(angleA((gap+1):end,(gap+1):end),angleA(1:(end-gap),1:(end-gap)));

function y = arData(x,b)
y = x;
for i = 1:numel(x)
    for j = max(1,i-numel(b)+1):(i-1)
        y(i) = y(i) - y(j)*b(i-j+1);
    end
end

function y = arPred(dat,b,numPred)
y = zeros(numPred+1,numel(dat));
y(1,:) = dat;
for i = 2:(numPred+1)
    for j = i:numel(dat)
        for k = max(1,j-numel(b)+1):(j-1)
            y(i,j) = y(i,j) - y(max(1,k+i-j),k)*b(j-k+1);
        end
    end
end