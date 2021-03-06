function [rlV rlAvg] = posVsSpike1(pos,sp,v,bounds,gauss)% lrVa rlVa ccs
accumbins = gauss(1);shift = 1;shifts = 0;
% if numel(gauss) == 1
%     gaussWeights = ones(gauss(1),1);
% elseif gauss(3) < gauss(2)
%     gaussWeights = exp(-((1:gauss(1))-gauss(2)).^2/gauss(3).^2)';
% else
%     gaussWeights = zeros(gauss(1),1);
%     gaussWeights(gauss(2):gauss(3)) = 1;
% end
if numel(sp) > size(v,1)
    sp = sp(:,1:size(v,1));
end
pos(pos == -1) = nan;
if size(v,1) < size(pos,1)
    pos = pos(1:size(v,1),:);
end
nanInds = find(~isnan(pos(:,1)));
pos(:,1) = interp1(nanInds,pos(nanInds,1),1:size(pos,1));
pos(:,2) = interp1(nanInds,pos(nanInds,2),1:size(pos,1));
nanInds = isnan(pos(:,1));
pos = pos(~nanInds,:);v = v(~nanInds,:);sp = sp(:,~nanInds);
 pos = bsxfun(@minus,pos,mean(pos));%pos = bsxfun(@rdivide,pos,std(pos));
 [a,~,~] = svd(pos(:,1:2),'econ');pos = a;
pos(:,1) = pos(:,1)-min(pos(:,1));pos(:,1) = pos(:,1)/max(pos(:,1));
sp = bsxfun(@rdivide,sp,std(sp,0,2));%sp/std(sp(:));
v = bsxfun(@rdivide,v,std(v));
vp11 = v((shift+1):end,1).*conj(v(1:end-shift,1))./abs(v(1:end-shift,1));
vp11 = [zeros(shift,1); vp11];
vp12 = v(:,1).*conj(v(:,2))./abs(v(:,1));
vp12 = filtLow(vp12,1250/32,2);vp11 = filtLow(vp11,1250/32,2);
%vp12 = vp11;
sp = bsxfun(@times,sp,(v(:,1)./abs(v(:,1))).');
%sp = filtLow(sp,1250/32,2);
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
if 1
    lrRuns = bwlabel(b>0);rlRuns = bwlabel(b<0);
    lrAvg = zeros(size(sp,1),accumbins,max(lrRuns));lrV = zeros(accumbins,max(lrRuns));
    rlAvg = zeros(size(sp,1),accumbins,max(rlRuns));rlV = zeros(accumbins,max(rlRuns));
    bins = (bounds(1))+((1:accumbins)-.5)/accumbins*(diff(bounds));
    for i = 1:max(lrRuns)
        inds = find(lrRuns == i);inds = min(inds):max(inds);
        for j = 1:size(sp,1)
            lrAvg(j,:,i) = csaps(pos(inds,1),sp(j,inds),1-1e-7,bins);
        end
        lrV(:,i) = csaps(pos(inds,1),vp12(inds),1-1e-7,bins);
    end
    for i = 1:max(rlRuns)
        inds = find(rlRuns == i);inds = min(inds):max(inds);
        for j = 1:size(sp,1)
            rlAvg(j,:,i) = csaps(pos(inds,1),sp(j,inds),1-1e-7,bins);
        end
        rlV(:,i) = csaps(pos(inds,1),vp12(inds),1-1e-7,bins);
    end
else
    allX = sp;%vp12 = vp12(b<0);
    for i = 1:shifts
        allX = [allX; circshift(allX(1:size(sp,1),:),[0 -i]); circshift(allX(1:size(sp,1),:),[0 i])];
%        lrAvg = [lrAvg; circshift(lrAvg(1:size(sp,1),:),[0 -i]); circshift(lrAvg(1:size(sp,1),:),[0 i])];
%        rlAvg = [rlAvg; circshift(rlAvg(1:size(sp,1),:),[0 -i]); circshift(rlAvg(1:size(sp,1),:),[0 i])];
    end
    allX = [real(allX.') imag(allX.') abs(allX.')];
    size(allX)
    [cc,~,kernlr] = pipeLine(vp12.',allX,2,1000);
    cc
    return
%     end
%     b(:) = 1;
%     lrV = vp12(b>0,1);lrAvg = sp(:,b>0);
%     b(:) = -1;
%     rlV = vp12(b<0,1);rlAvg = sp(:,b<0);
end
%temp = lrV;lrV = rlV; rlV = temp;
for i = 1:shifts
    lrAvg = [lrAvg; circshift(lrAvg(1:size(sp,1),:,:),[0 -i 0]); circshift(lrAvg(1:size(sp,1),:,:),[0 i 0])];
    rlAvg = [rlAvg; circshift(rlAvg(1:size(sp,1),:,:),[0 -i 0]); circshift(rlAvg(1:size(sp,1),:,:),[0 i 0])];
end
lrAvg = lrAvg(:,(shifts+1):(end-shifts),:);
rlAvg = rlAvg(:,(shifts+1):(end-shifts),:);
lrV = lrV((shifts+1):(end-shifts),:);rlV = rlV((shifts+1):(end-shifts),:);
%%%
inds = 1:size(lrAvg,3);%randperm(size(lrAvg,3));%
lrV = lrV(:,inds);%lrAvg = lrAvg(:,:,inds);
allX = lrAvg(:,:).';%allX = [allX conj(allX) abs(allX)];%ones(size(allX,1),1) 
allX = [ones(size(allX,1),1) real(allX) imag(allX) abs(allX)];
size(allX)
[cclrc,mse,kernlr] = pipeLine(lrV(:).',allX,4,1000);
lrAvg = lrAvg(:,:,inds);
allX = lrAvg(:,:).';
allX = [ones(size(allX,1),1) real(allX) imag(allX) abs(allX)];
[cclr,mse,kernlr] = pipeLine(lrV(:).',allX,4,1000);

%figure;subplot(221);imagesc(imag(lrV));
%subplot(222);imagesc(reshape(-imag(mean(kernlr)*allX'),size(lrV)));
%temp = mean(reshape(conj(mean(kernlr)*allX'),size(lrV)),2);
%temp = temp-mean(temp);temp = temp/std(temp);
%allX = bsxfun(@minus,allX,mean(allX));
lrVHat = reshape(conj(mean(kernlr)*allX'),size(lrV));
%cclr
%figure;subplot(211);imagesc(angle(lrV));colormap hsv;subplot(212);imagesc(angle(lrVHat));colormap hsv
%return
%lrV = mean(lrV,2);
%lrV = lrV-mean(lrV);lrV = lrV/std(lrV);
%figure;subplot(211);plot(real(lrV));hold all;plot(imag(lrV));
%plot(real(temp));plot(imag(temp));
%[abs(cclr).^2 1-mse]
inds = 1:size(rlAvg,3);%randperm(size(rlAvg,3));%
rlV = rlV(:,inds);%rlAvg = rlAvg(:,:,inds);
allX = rlAvg(:,:).';%allX = [allX conj(allX) abs(allX)];%ones(size(allX,1),1) 
allX = [ones(size(allX,1),1) real(allX) imag(allX) abs(allX)];
[ccrlc,mse,kernrl] = pipeLine(rlV(:).',allX,4,1000);
rlAvg = rlAvg(:,:,inds);
allX = rlAvg(:,:).';%allX = [allX conj(allX) abs(allX)];%ones(size(allX,1),1) 
allX = [ones(size(allX,1),1) real(allX) imag(allX) abs(allX)];
[ccrl,mse,kernrl] = pipeLine(rlV(:).',allX,4,1000);
(abs(ccrlc).^2)
figure;imagesc(abs(rlV)');
size(allX')
figure;imagesc(reshape(squeeze(allX(:,2)),size(rlV)).');
return
%temp = mean(reshape(conj(mean(kernrl)*allX'),size(rlV)),2);
%temp = temp-mean(temp);temp = temp/std(temp);
%rlV = mean(rlV,2);
%rlV = rlV - mean(rlV);rlV = rlV/std(rlV);
%subplot(212);plot(real(rlV));hold all;plot(imag(rlV));
%plot(real(temp));plot(imag(temp));
%[abs(ccrl).^2 1-mse]
ccs = [cclrc cclr ccrlc ccrl];ccs = abs(ccs).^2
%figure;plot(abs(mean(kernlr)));hold all;plot(abs(mean(kernrl)));
%lrV = lrV-mean(lrV(:));
rlVa(:,:,1) = (angle(rlV)+pi)/(2*pi);rlVa(:,:,2) = 1;rlVa(:,:,3) = sqrt(abs(rlV)/max(abs(rlV(:))));
rlVa = hsv2rgb(rlVa);
lrVa(:,:,1) = (angle(lrV)+pi)/(2*pi);lrVa(:,:,2) = 1;lrVa(:,:,3) = sqrt(abs(lrV)/max(abs(lrV(:))));
lrVa = hsv2rgb(lrVa);
figure;subplot(221);image(lrVa);subplot(223);image(rlVa);
%allX = bsxfun(@minus,allX,mean(allX));
rlVHat = reshape(conj(mean(kernrl)*allX.'),size(rlV));
rlVa(:,:,1) = (angle(rlVHat)+pi)/(2*pi);rlVa(:,:,2) = 1;rlVa(:,:,3) = sqrt(abs(rlVHat)/max(abs(rlVHat(:))));
rlVa = hsv2rgb(rlVa);
lrVa(:,:,1) = (angle(lrVHat)+pi)/(2*pi);lrVa(:,:,2) = 1;lrVa(:,:,3) = sqrt(abs(lrVHat)/max(abs(lrVHat(:))));
lrVa = hsv2rgb(lrVa);
subplot(222);image(lrVa);subplot(224);image(rlVa);
templr = mean(abs(kernlr));size(templr)
%templr = reshape(templr(2:end),20,3);
temprl = mean(abs(kernrl));
%temprl = reshape(temprl(2:end),20,3);
figure;plot(templr);hold all;plot(temprl);
return
%lrAvg = abs(mean(lrAvg,3));lrAvg = bsxfun(@minus,lrAvg,mean(lrAvg,2));
%lrAvg = bsxfun(@rdivide,lrAvg,std(lrAvg,0,2));
%[u,~,v] = svds(lrAvg,1);
%u = ffa(lrAvg.',1);
%v = pinv(u)*lrAvg;
%figure;subplot(211);plot(real(v));hold all;plot(imag(v));
%rlAvg = abs(mean(rlAvg,3));rlAvg = bsxfun(@minus,rlAvg,mean(rlAvg,2));
%rlAvg = bsxfun(@rdivide,rlAvg,std(rlAvg,0,2));
%[u,~,v] = svds(rlAvg,1);
%u = ffa(rlAvg.',1);
%v = pinv(u)*rlAvg;
%subplot(212);plot(real(v));hold all;plot(imag(v));
%subplot(223);imagesc(imag(rlV));
%subplot(224);imagesc(reshape(-imag(mean(kernrl)*allX'),size(rlV)));
%figure;plot(abs(mean(kernlr)));hold all;plot(abs(mean(kernrl)));
%corr(nanmean(kernlr)',nanmean(kernrl)')
%temp = lrV;lrV = rlV; rlV = temp;
%lrV = rlV;lrAvg = rlAvg;
%lrV = lrV(:,randperm(size(lrV,2)));rlV = rlV(:,randperm(size(rlV,2)));
%lrAvg=abs(lrAvg);lrV = real(lrV);
%%using GLM
trainInds = 1:max(lrRuns);testInds = trainInds;%
trainInds = 1:2:max(lrRuns);%1:floor(max(lrRuns)*.7);
testInds = 2:2:max(lrRuns);%max(trainInds)+1:max(lrRuns);
xTrain = lrAvg(:,:,trainInds);
xTrain = [xTrain(:,:)' xTrain(:,:).' abs(xTrain(:,:)')];
xTest = lrAvg(:,:,testInds);xTest = [xTest(:,:)' xTest(:,:).' abs(xTest(:,:)')];
%[xTrain WM] = whiten(xTrain);xTest = (WM*xTest')';
yTrain = lrV(:,trainInds);yTest = lrV(:,testInds);
a = glmfit(xTrain,yTrain(:));
yHat = glmval(a,xTest,'identity');
trainInds = 1:2:max(rlRuns);%1:max(rlRuns);testInds = trainInds;%
testInds = 2:2:max(rlRuns);%1:floor(max(rlRuns)*.7);testInds = max(trainInds)+1:max(rlRuns);
xTrain = rlAvg(:,:,trainInds);
xTrain = [xTrain(:,:)' xTrain(:,:).' abs(xTrain(:,:)')];
xTest = rlAvg(:,:,testInds);xTest = [xTest(:,:)' xTest(:,:).' abs(xTest(:,:)')];
%[xTrain WM] = whiten(xTrain);xTest = (WM*xTest')';
yTrain = rlV(:,trainInds);yTest = rlV(:,testInds);
a1 = glmfit(xTrain,yTrain(:));
figure;plot(abs(a));hold all;plot(abs(a1))
yHat = glmval(a1,xTest,'identity');
yHat1 = glmval(a,xTest,'identity');
%figure;subplot(211);imagesc(real(reshape(lrVHat,size(lrV))));
%subplot(212);imagesc(real(lrV));
%figure;plot(real(lrV(:)));hold all;plot(real(lrVHat));
[1-mean((yHat-yTest(:)).^2)/var(yTest(:)) corr(yTest(:),yHat).^2]
%corr(yTest(:),yHat1)
% weighted = bsxfun(@times,rlAvg+randn(size(rlAvg))*.01,gaussWeights);
% [~,indsrl] = sort(mdscale(pdist(abs(weighted)','correlation'),1));%[real(weighted); imag(weighted)]','criterion','sstress'
% weighted = bsxfun(@times,lrAvg+randn(size(lrAvg))*.01,gaussWeights);
% [~,indslr] = sort(mdscale(pdist(abs(weighted)','correlation'),1));%,'criterion','sstress'[real(weighted); imag(weighted)]
% rlAvg = rlAvg(:,indsrl);
% rlV = rlV(:,indsrl);
% rlVa(:,:,1) = (angle(rlV)+pi)/(2*pi);rlVa(:,:,2) = 1;rlVa(:,:,3) = abs(rlAvg)/max(abs(rlAvg(:)));
% rlVa = hsv2rgb(rlVa);
% lrAvg = lrAvg(:,indslr);%lrV = lrV(:,indslr);
% lrV = lrV(:,indslr);
% lrVa(:,:,1) = (angle(lrV)+pi)/(2*pi);lrVa(:,:,2) = 1;lrVa(:,:,3) = abs(lrAvg)/max(abs(lrAvg(:)));
% lrVa = hsv2rgb(lrVa);

function [X WM] = whiten(X)
A = X'*X/size(X,1);
[V,D] = eig(A);d = diag(D);
D1 = diag(sqrt(1./d));
WM = D1*V';
X = (WM*X')';
DWM = V*D1^(-1);