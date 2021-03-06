function [o,i] = regressAll(pcaDat,lfpDat,posDat,inds)
%% an attempt to fit PC2 with PC1  -- outdated


if size(lfpDat,1) > size(lfpDat,2)
    lfpDat = lfpDat.';
end
if size(pcaDat,1) > size(pcaDat,2)
    pcaDat = pcaDat.';
end
if size(posDat,1) > size(posDat,2)
    posDat = posDat.';
end
if size(posDat,2) > size(pcaDat,2)
    posDat(:,(size(pcaDat,2)+1):end) = [];
else
    pcaDat(:,(size(posDat,2)+1):end) = [];
    lfpDat(:,(size(posDat,2)+1):end) = [];
end
posDat(posDat == -1) = nan;
for i = 1:size(posDat,1)
    nanInds = find(~isnan(posDat(i,:)));
    posDat(i,:) = interp1(nanInds,posDat(i,nanInds),1:size(posDat,2));
end
nanInds = any(isnan(posDat));
posDat = posDat(:,~nanInds);pcaDat = pcaDat(:,~nanInds);lfpDat = lfpDat(:,~nanInds);
if ~exist('inds','var')
    inds = size(posDat,2);
end
if inds > 50000
    decFac = ceil(inds/50000);
    posDat = deciMatrix(posDat,decFac);
    pcaDat = deciMatrix(pcaDat,decFac);
    inds = floor(inds/decFac);
end
lfpDat = lfpDat(:,1:inds);pcaDat = pcaDat(:,1:inds);posDat = posDat(:,1:inds);
relPhase = diff(angle(pcaDat(1:2,:)));
instPhase = [diff(angle(pcaDat),1,2) zeros(size(pcaDat,1),1)];
vel = [angVel(posDat')' zeros(size(posDat,1),1)];
%input = [pcaDat;relPhase;exp(1i*relPhase);abs(pcaDat(1,:)).*exp(1i*relPhase);...
%    abs(pcaDat(2,:)).*exp(1i*relPhase);circ_std(angle(lfpDat));instPhase];
%input = (pcaDat(1,:));
output = (pcaDat(1,:));%vel(1,:);%[vel; abs(vel)];
input = (pcaDat(2,:));
%output = (pcaDat(2,:));
%output = [pimpOut(posDat,1); pimpOut(posDat,2)];
%output = filtLow(output,1250/32,2,8);
%input = [input;input.*conj(input)];

offset = 20;
[c,~,~,o,i] = splitToep1(output,input,50,1250/32,1,size(input,2)-offset,offset,1000);
%figure;plot(abs(o)*10);hold all;plot(abs(i));plot(vel(1,:));
if numel(c) == 1
    c
else
    figure;plot(abs(c))
end

function b = deciMatrix(a,r)
b = zeros(size(a,1),ceil(size(a,2)/r));
for i = 1:size(b,1)
    b(i,:) = decimate(a(i,:),r);
end

%%converting position data into complex-valued!
function p = pimpOut(data,nDiff)
data(data == -1) = nan;
orient = angle(complex(diff(data([1 3],:)),diff(data([2 4],:))));
if nDiff 
    data = [diff(data,nDiff,2) zeros(size(data,1),nDiff)];
end
data(isnan(data)) = 0;orient(isnan(orient)) =0;
cData = complex(data([1 3],:),data([2 4],:));
relC = bsxfun(@times,cData,exp(-1i*orient));
%figure;hist(angle(relC(1,:)),100)
%circ_std(angle(relC'))
p = [data;cData;exp(1i*angle(cData));abs(cData);relC;real(relC);imag(relC);diff(cData);abs(diff(cData))];