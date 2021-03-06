function [cr,cc1,cc2,kerns]= posVsSpike(pos,sp,v,numNeuro)%,vInterp 
bounds = [.1 .9];accumbins = 50;
shift = 1;shifts = 0;
if size(sp,2) > size(v,1)
    sp = sp(:,1:size(v,1));
elseif size(v,1) < size(sp,2)
    v = v(1:size(sp,2),:);
end
pos(pos == -1) = nan;
if size(v,1) < size(pos,1)
    pos = pos(1:size(v,1),:);
end
for i=1:size(pos,2)
    nanInds = find(~isnan(pos(:,i)));
    pos(:,i) = interp1(nanInds,pos(nanInds,i),1:size(pos,1));
end
nanInds = isnan(pos(:,1));
pos = pos(~nanInds,:);v = v(~nanInds,:);sp = sp(:,~nanInds);
vel = angVel(pos);vel = filtLow(vel(:,1),1250/32,4);
pos = bsxfun(@minus,pos,mean(pos));%pos = bsxfun(@rdivide,pos,std(pos));
%[a,~,~] = svd(pos(:,1:2),'econ');pos = a;
%pos(:,1) = pos(:,1)-min(pos(:,1));pos(:,1) = pos(:,1)/max(pos(:,1));
[pos,~,~] = svd(pos(:,1:2),'econ');
pos(:,1) = pos(:,1)-min(pos(:,1));pos(:,1) = pos(:,1)/max(pos(:,1));
v = bsxfun(@rdivide,v,std(v));
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
[~,inds] = sort(sum(abs(sp(:,b ~= 0)),2),'descend');
numCross = 3;
sp = sp(inds(1:numNeuro(end)),:);
sp = bsxfun(@rdivide,sp,std(sp,0,2));%sp/std(sp(:));
sp = bsxfun(@times,sp,(v(:,1)./abs(v(:,1))).');
v(:,2) = v(:,1).*conj(v(:,2))./abs(v(:,1));
v(:,1) = [zeros(shift,1); v((shift+1):end,1).*conj(v(1:end-shift,1))./abs(v(1:end-shift,1))];
v = filtLow(v.',1250/32,2).';
sp = filtLow(sp,1250/32,2);
runs = bwlabel(b > 0);
vInterp = zeros(2,2,max(runs),accumbins);
spInterp = zeros(2,size(sp,1),max(runs),accumbins);
bins = (bounds(1))+((1:accumbins)-.5)/accumbins*(diff(bounds));
numX = ceil(sqrt(size(sp,1)));numY = ceil(size(sp,1)/numX);
for k = 1:2
    runs = bwlabel(b*((-1)^k)>0);
    for i = 1:max(runs)
        inds = find(runs == i);inds = min(inds):max(inds);
        inds(vel(inds,1) < .1) = [];
        for j = 1:2
            vInterp(k,j,i,:) = csaps(pos(inds,1),v(inds,j),1-1e-7,bins);
        end
        for j = 1:size(sp,1)
            spInterp(k,j,i,:) = csaps(pos(inds,1),sp(j,inds),1-1e-7,bins);
        end
    end
    figure;
    for j = 1:size(sp,1)
       subplot(numX,numY,j);imagesc(complexIm(squeeze(spInterp(k,j,:,:)),0,1));title(num2str(j));
    end
end
kernFig = figure;
drawnow;h = figure;
shuffle = randperm(max(runs));
cc1 = zeros(numel(numNeuro),2,numCross);cc2 = cc1;cr = zeros(numel(numNeuro),2,numCross);
for k = 1:2
    allX = squeeze(spInterp(k,1:size(sp,1),:,:));
    for i = 1:shifts
        allX = [allX; circshift(squeeze(spInterp(k,1:size(sp,1),:,:)),[0 0 -i]) ;circshift(squeeze(spInterp(k,1:size(sp,1),:,:)),[0 0 i])];
    end
    allX = allX(:,:,(shifts+1):(end-shifts));
    Y = squeeze(vInterp(k,2,shuffle,(shifts+1):(end-shifts)));
    Y1 = squeeze(vInterp(mod(k,2)+1,2,shuffle,shifts+1:end-shifts));
    for n = 1:numel(numNeuro)
        allXC = allX(1:numNeuro(n),:,:);
        allXC = allXC(:,:).';
        allXC = [ones(size(allXC,1),1) real(allXC) imag(allXC) abs(allXC)];
        [cc1(n,k,:),~] = pipeLine(Y(:).',allXC,numCross,1000);
        allXC = allX(1:numNeuro(n),shuffle,:);
        allXC = allXC(:,:).';
        allXC = [ones(size(allXC,1),1) real(allXC) imag(allXC) abs(allXC)];
        [cc2(n,k,:),~,kern] = pipeLine(Y1(:).',allXC,numCross,1000);
        [cr(n,k,:),~,~] = pipeLine(Y(:).',allXC,numCross,1000);
    end
    size(kern)
    kern =  mean(kern);kerns(k,:) = squeeze(kern);
    Y = squeeze(vInterp(k,2,:,(shifts+1):(end-shifts)));
    allXC = allX(1:numNeuro(n),:,:);
    allXC = allXC(:,:).';allXC = [ones(size(allXC,1),1) real(allXC) imag(allXC) abs(allXC)];
    subplot(2,4,(k-1)*4+3);image(complexIm(reshape(conj(kern*allXC'),size(Y)),0,.25));
    subplot(2,4,k*4);image(complexIm(Y,0,.25));
    kern = reshape(kern(2:end),numel(kern(2:end))/3,3);
    figure(kernFig);plot(abs(kern));
    in = squeeze(spInterp(k,input('which neuron? '),:,shifts+1:end-shifts));
    figure(h);subplot(2,4,(k-1)*4+1);imagesc(abs(in));
    subplot(2,4,(k-1)*4+2);image(complexIm(in,0,.5));
end