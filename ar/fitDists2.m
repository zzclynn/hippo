function [A, noise, R] = fitDists2(fileNum,modelSize,numInds)

load_data;
spikes = spktrain;
v = signals;
if ~exist('numInds','var');
    numInds = size(v,2);
end
spikes = [spikes; zeros(size(v,1)-size(spikes,1),size(spikes,2))];
spikes = logical(spikes(:,1:numInds));
cMor = getMor(fm,sf,1000,5);
for i= 1:numInds
    z(:,i) = conv(v(:,i),cMor,'same');
    [coeffs(i,:) noise(i)] = arburg(z(:,i),modelSize);
end
coeffs(end+1,:) = mean(coeffs);noise(end+1) = mean(noise);
%%%%%%%%%%%%
temp = zeros(modelSize,sum(spikes(:)));
for i = 1:modelSize
    temp(i,:) = z(find(spikes)-i+1);
end
spikeFit.Sigma = cov(temp');
spikeFit.mu = mean(temp,2);
spikeTimes = getTimes1(spikes)'+1;
z = z.'; z = z(1:size(spikeTimes,1),:);
A = [-coeffs(end,2:end);eye(numel(coeffs(end,:))-1)];A(end,:) = [];
R = spikeFit.Sigma;
vT = simVar(A,noise(end),modelSize,R);
[h xs isiAll msIsi] = histISI(spikes,z);
h = cumsum(h);h = h/max(h);
hIm(:,:,1) = ones(2,numel(h));hIm(:,:,2) = ones(2,1)*h;hIm(:,:,3) = hIm(:,:,2);hIm = circshift(hIm,[0 0 1]);
ys = [0 .6];
figure;hold all;imagesc(xs,ys,hIm);
temp = .5*log2(2*pi*covAllZ(spikeTimes,z,400));temp = temp-temp(1);
plot(temp,'LineWidth',3);
temp = (log2(exp(1)*pi*vT));temp = temp-temp(1);%.5*
plot(temp,'r','LineWidth',3); 
scatter(median(isiAll),temp(round(median(isiAll))),100,'k','filled');
plot([0 300],[.14 .14],'k--','Linewidth',2);axis tight;legend({'Actual','AR3'},'Location','Southeast');legend boxoff;
set(gca,'fontsize',16);ylabel('Differential entropy (bits)');xlabel('Time after spike (ms)');
set(gca,'xlim',[1 400],'ylim',[-.05 .9]);
ms = simMean(A,spikeFit.mu);
bounds{2} = 0:2:400;bounds{1} = linspace(0,7,100);
vsIsi = vT(isiAll);
klIsi = klDiv(msIsi,vsIsi,spikeFit.mu,spikeFit.Sigma);
t1 = klDiv(zeros(size(vT),1),vT,0,spikeFit.Sigma,600);
figure;imagesc(bounds{2},bounds{1},hist3([klIsi isiAll'],bounds));colormap gray;hold all;
set(gca,'YDir','normal')
plot(klDiv(ms,vT,spikeFit.mu,spikeFit.Sigma,600),'Linewidth',2);
plot(t1,'linewidth',2);
plot(temp,'Linewidth',2);%2*pi/exp(2).^2
sum(t1)/sum(temp(1:numel(t1)).^2)
set(gca,'fontsize',16);
ylabel('information (bits)');xlabel('time after spike (ms)');

function d = klDiv(m0,s0,m1,s1,ts)
if ~exist('ts','var')
    ts = numel(m0);
end
m0 = m0(1:ts);s0 = s0(1:ts);
m1 = m1(1);s1 = s1(1);%d = zeros(1,ts);
%d = .5*(trace(s1\s0) + (m1-m0)'\inv(s1)*(m1-m0) - log(det(s0)/det(s1)) - 1);
d = (s0/s1 + conj(m1-m0).*(m1-m0)/s1 - log(s0/s1) - 1)/log(2); %.5*%WAY 1
%d = d(1:ts);
% m1 = [real(m1) imag(m1)]';
% s1 = [s1 0; 0 s1];
% for i = 1:ts
% S0 = [s0(i) 0; 0 s0(i)];M0 = [real(m0(i)) imag(m0(i))]';
% d(i) = 2/pi*(trace(inv(S0)*s1) + (m1-M0)'*inv(s1)*(m1-M0) + log(det(S0)/det(s1)) - 2);%COMP
% %%d(i) = 2/pi*(trace(inv(s1)*S0) + (m1-M0)'*inv(s1)*(m1-M0) - log(det(S0)/det(s1)) - 2); %% WIKI
% %d(i) = 2/pi*(trace(s1\S0) + (m1-M0)'/s1*(m1-M0) - log(det(S0)/det(s1)) - 2); %%WIKI
% end

function [h xs fAll muAll] = histISI(spikes,z)
xs = 0:1:700;
h = zeros(size(xs));
fAll = [];muAll = [];
for i = 1:size(spikes,2)
    f = find(spikes(:,i));
    muAll = [muAll z(i,f(2:end))];
    f = diff(f);
    fAll = [fAll f'];
    h = hist(f,xs) + h;
end
muAll = muAll.';

function mu = simMean(A,M)
numIt = 2000;
mu = zeros(numIt,1);
for i = 1:numIt
    mu(i) = M(1);
    M = A*M;
end

function [v P] = simVar(A,noise,p,R)
E = zeros(p); E(1,1) = noise;
P = R;
numIt = 2000;
v = zeros(numIt,1);
for i = 1:numIt
    v(i) = P(1,1);
    P = A*P*A' + E;
    P = (P+P')/2;
end
vecP = (eye(p^2,p^2) - kron(conj(A),A))\E(:);
P = reshape(vecP,p,p);
P = (P+P')/2;
[P(1,1) log(max(v)) log(real(P(1,1)))]

function z = covAllZ(spikes,zs,forw)
[r c] = find(spikes == 1);
r((c+forw-1) > size(spikes,2)) = [];
c((c+forw-1) > size(spikes,2)) = [];
z = zeros(numel(r),forw);
for i = 1:numel(r)
    z(i,:) = zs(r(i),c(i)+(1:forw)-1);
end
z = var(z);

function t = getTimes1(spikes)
spikes = spikes';
s = size(spikes);
t = zeros(size(spikes));
for i = 1:s(1)
    counter = 1001;
    for j= 1:s(2)
        if spikes(i,j)
            counter = 0;
        else
            counter = counter + 1;
        end
        t(i,j) = counter;
    end
end
t(t > 1000) = 500;
t = t';

function dPhase = getDiffs(sig,gap)
angleA = angle(sig);
if min(size(sig)) == 1
    dPhase = circ_dist(angleA((gap+1):end),angleA(1:(end-gap)));
else
    dPhase = circ_dist(angleA(:,(gap+1):end),angleA(:,1:(end-gap)));
end