function w = findVarDims(pos,v)
%% find behavioral dimensions that best capture LFP PC's
bounds = [.1 .9];
pos(pos == -1) = nan;
sV = size(v,1);
pos = pos(1:sV,:);
for i = 1:2
    pos(:,i) = interp1(find(~isnan(pos(:,i))),pos(~isnan(pos(:,i)),i),1:size(pos,1));
end
nanInds = isnan(pos(:,1));
pos = pos(~nanInds,:);v = v(~nanInds,:);
pos = bsxfun(@minus,pos,mean(pos));
[pos,~,~] = svd(pos(:,1:2),'econ');
pos(:,1) = pos(:,1)-min(pos(:,1));pos(:,1) = pos(:,1)/max(pos(:,1));
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
numPast = 30;numFuture = 30;numDilate = 10;
v(:,2) = v(:,2).*exp(1i*-angle(v(:,1)));
v(:,1) = [0; v(2:end,1).*exp(1i*-angle(v(1:end-1,1)))];
v = filtLow(v.',1250/32,2).';
%figure;plot(pos(:,1)/200);hold all;plot(imag(v(:,1)));hold all;plot(real(v(:,2)));hold all;plot(imag(v(:,2)));return
v = imag(v(:,1));
%pos = filtLow(pos',1250/32,4)';
figure;
for k = 1:2
    running = bwmorph(b*((-1)^k)>0,'dilate',numDilate);%ones(size(b));%runs(runs > 30000) = [];%
     runs = find(running);
     %figure(1);plot(pos(:,1));hold all;plot(running);return
     runs(runs < numPast) = [];runs(runs > size(pos,1)-numFuture) = [];
     X = zeros(numPast + numFuture,numel(runs));
     for i = (-numPast+1):numFuture
         X(i+numPast,:) = pos(i+runs,1);
     end
     tic
     w(k,:) = SCA(X,v(runs).',1);
     wx = (w(k,:)*X)';
     %w1(k,:) = glmfit(X',v(runs),'normal');
     %a = GSIR(X,v(runs), 1, 0);w(k,:) = a.edrs;wx = a.Xv';
     %[wx,w(k,:)] = ldr(v(runs),X','IPFC','cont','bic','nslices',20);
     %[wx,w(k,:)] = SAVE(v(runs),X','cont',1,'nslices',20);
     toc;
     [h,dims] = hist3([v(runs) wx],[100 100]);
     [corr(v(runs),wx)]% corr(v(runs),glmval(w1(k,:)',X','identity'))]
     %figure(1);
     subplot(2,1,k);imagesc(dims{2},dims{1},sqrt(h));
     %[h,dims] = hist3([v(runs) glmval(w1(k,:)',X','identity')],[100 100]);
     %figure(2);subplot(2,1,k);imagesc(dims{2},dims{1},sqrt(h));drawnow;
end

figure;plot(w');%hold all;plot(w1');