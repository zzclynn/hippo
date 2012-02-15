function [lrAvg rlAvg lrV rlV lrVa rlVa] = posVsSpike(pos,sp,v,bounds,gauss)
accumbins = gauss(1);
if numel(gauss) == 1
    gaussWeights = ones(gauss(1),1);
elseif gauss(3) < gauss(2)
    gaussWeights = exp(-((1:gauss(1))-gauss(2)).^2/gauss(3).^2)';
else
    gaussWeights = zeros(gauss(1),1);
    gaussWeights(gauss(2):gauss(3)) = 1;
end
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
pos = pos(~nanInds,:);v = v(~nanInds,:);sp = sp(~nanInds);
 pos = bsxfun(@minus,pos,mean(pos));%pos = bsxfun(@rdivide,pos,std(pos));
 [a,~,~] = svd(pos(:,1:2),'econ');pos = a;
pos(:,1) = pos(:,1)-min(pos(:,1));pos(:,1) = pos(:,1)/max(pos(:,1));
sp = sp/std(sp(:));
v = bsxfun(@rdivide,v,std(v));
%vp11 = v((shift+1):end,1).*conj(v(1:end-shift,1))./abs(v(1:end-shift,1));
%vp11 = [zeros(shift,1); vp11];
vp12 = v(:,1).*conj(v(:,2))./abs(v(:,1));
sp = sp.*v(:,1).'./abs(v(:,1))';
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
lrRuns = bwlabel(b>0);rlRuns = bwlabel(b<0);
lrAvg = zeros(accumbins,max(lrRuns));lrV = lrAvg;
rlAvg = zeros(accumbins,max(rlRuns));rlV = rlAvg;
bins = (bounds(1))+((1:accumbins)-.5)/accumbins*(diff(bounds));
for i = 1:max(lrRuns)
    inds = find(lrRuns == i);inds = min(inds):max(inds);
    lrAvg(:,i) = csaps(pos(inds,1),sp(inds),1-1e-7,bins);
    lrV(:,i) = csaps(pos(inds,1),vp12(inds),1-1e-7,bins);
end
for i = 1:max(rlRuns)
    inds = find(rlRuns == i);inds = min(inds):max(inds);
    rlAvg(:,i) = csaps(pos(inds,1),sp(inds),1-1e-7,bins);
    rlV(:,i) = csaps(pos(inds,1),vp12(inds),1-1e-7,bins);
end
weighted = bsxfun(@times,rlAvg+randn(size(rlAvg))*.01,gaussWeights);
[~,indsrl] = sort(mdscale(pdist(abs(weighted)','correlation'),1));%[real(weighted); imag(weighted)]','criterion','sstress'
weighted = bsxfun(@times,lrAvg+randn(size(lrAvg))*.01,gaussWeights);
[~,indslr] = sort(mdscale(pdist(abs(weighted)','correlation'),1));%,'criterion','sstress'[real(weighted); imag(weighted)]
rlAvg = rlAvg(:,indsrl);
rlV = rlV(:,indsrl);
rlVa(:,:,1) = (angle(rlV)+pi)/(2*pi);rlVa(:,:,2) = 1;rlVa(:,:,3) = abs(rlAvg)/max(abs(rlAvg(:)));
rlVa = hsv2rgb(rlVa);
lrAvg = lrAvg(:,indslr);%lrV = lrV(:,indslr);
lrV = lrV(:,indslr);
lrVa(:,:,1) = (angle(lrV)+pi)/(2*pi);lrVa(:,:,2) = 1;lrVa(:,:,3) = abs(lrAvg)/max(abs(lrAvg(:)));
lrVa = hsv2rgb(lrVa);