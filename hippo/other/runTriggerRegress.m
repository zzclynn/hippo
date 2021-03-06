function runTriggerRegress(pos,v,Xf,r,thresh)
%% convert demodulated complex data to real valued w/ 2x dimensionality, 
%% run fastICA, then bin and render activations.
warning off all;
dec = 1;
bounds = [.1 .9];
pos(pos == -1) = nan;
%figure;plot(pos(:,1));hold all;
%plot([0; diff(pos(:,1))]);
%plot(flipud([0; diff(flipud(pos(:,1)))]));
reject = 0;
for i = 1:4
    reject = reject | min([0; diff(pos(:,i))],flipud([0; diff(flipud(pos(:,i)))])) < -20;
end
pos(reject,:) = nan;
%plot(pos(:,1),'r');return;
if size(v,1) < size(pos,1)
    pos = pos(1:size(v,1),:);
end
for i = 1:4
    nanInds = find(~isnan(pos(:,i)));
    pos(:,i) = interp1(nanInds,pos(nanInds,i),1:size(pos,1));
end
nanInds = isnan(pos(:,1)) | isnan(pos(:,3));
pos = pos(~nanInds,:);v = v(~nanInds,:);Xf = Xf(:,~nanInds);%sp = sp(:,~nanInds);
if dec > 1
    for i = 1:4
        posd(:,i) = decimate(pos(:,i),dec);
    end
    pos = posd;clear posd;
end
vel = angVel(pos);%vel = filtLow(vel(:,1),1250/32,1);
vel = [0; vel(:,1)];
pos = bsxfun(@minus,pos,mean(pos));
[a,~,~] = svd(pos(:,1:2),'econ');pos = a;
for i = 1:2    
    pos(:,i) = pos(:,i) - min(pos(:,i));
    pos(:,i) = pos(:,i)/(max(pos(:,i)));
    pos(:,i) = min(pos(:,i),.9999);
end
offSet = 1;
Xf1 = bsxfun(@times,Xf(65:end,:),exp(1i*angle(v(:,1))).');
Xf = [bsxfun(@times,Xf(1:64,:),exp(1i*angle(v(:,1))).');...
     [zeros(offSet,1); v(1+offSet:end,1).*conj(v(1:end-offSet,1))./abs(v(1:end-offSet,1))].'];

vel = filtLow(vel,1250/32/dec,1);
vel = vel/max(vel);inds = vel > thresh;
Xf = Xf(:,inds);Xf1 = Xf1(:,inds);
Xf = [real(Xf);imag(Xf)];%[abs(Xf); angle(Xf)]
t = r*zscore(Xf,0,2);
Xf1 = [real(Xf1);imag(Xf1)];
Xf1 = zscore(Xf1,0,2);
[cc,~,W] = pipeLine1(Xf1,t',3,1);
W = squeeze(mean(W));
t = complex(Xf1,W'*t);
sPlot(t);
cc