function [posInds,t,tes] = runTriggerDist(pos,v,Xf,accumbins,thresh,r,probes,posInds,r2,alphas)
%% some unknown artifact

bounds = [.1 .9];
pos(pos == -1) = nan;
reject = 0;
for i = 1:size(pos,2)
    reject = reject | min([0; diff(pos(:,i))],flipud([0; diff(flipud(pos(:,i)))])) < -20;
end
pos(reject,:) = nan;
if size(v,1) < size(pos,1)
    pos = pos(1:size(v,1),:);
end
for i = 1:size(pos,2)
    nanInds = find(~isnan(pos(:,i)));
    pos(:,i) = interp1(nanInds,pos(nanInds,i),1:size(pos,1));
end
nanInds = isnan(pos(:,1));
if size(pos,2) > 2
    nanInds = nanInds | isnan(pos(:,3));
end
pos = pos(~nanInds,:);v = v(~nanInds,:);Xf = Xf(:,~nanInds);%sp = sp(:,~nanInds);
if size(pos,2) > 2
    vel = angVel(pos);
else
    vel = diff(pos);
    vel = sqrt(sum(vel.^2,2));
end
vel = [zeros(1,size(vel,2)); vel];
for i = 1:size(vel,2)
    vel(:,i) = filtLow(vel(:,i),1250/32,1);
end
%veld = vel;
vel = vel(:,1);
vel = vel/max(vel);inds = vel > thresh;
pos = bsxfun(@minus,pos,mean(pos));
[a,~,~] = svd(pos(:,1:2),'econ');pos = a;
for i = 1:2    
    pos(:,i) = pos(:,i) - min(pos(:,i));
    pos(:,i) = pos(:,i)/(max(pos(:,i)));
    pos(:,i) = min(pos(:,i),.9999);
%    veld(:,i) = veld(:,i) - min(veld(:,i));
%    veld(:,i) = veld(:,i)/max(veld(:,i));
%    veld(:,i) = min(veld(:,i),.9999);
    posd(:,i) = floor(pos(:,i)*accumbins(min(numel(accumbins),i)))+1;
%    veld(:,i) = floor(veld(:,i)*accumbins(min(numel(accumbins),i)))+1;
end
Xf = [bsxfun(@times,Xf,exp(1i*angle(v(:,1))).')];
%Xf = filtLow(Xf,1250/32,2);
inds = bwmorph(inds,'dilate',20);
%inds = abs(zscore(abs(v(:,1)))) < 2;
Xf = Xf(:,inds);posd = posd(inds,:);%veld = veld(inds,:);
vel = vel(inds);pos = pos(inds,:);v = v(inds,:);
% r1 = pinv(r);
% if ~exist('r2','var')
%     r2 = r1;
% end

% if exist('posInds','var') && ~isempty(posInds)
%     r = r(posInds,:);%r1 = r1(:,posInds);r2 = r2(:,posInds); %% IS THIS RIGHT??
% end
% t = r*Xf;%zscore(Xf,0,2);%
% %%FOR 1D TRACK
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
runs = bwlabel(b > 0);
w = watershed(b==0);
w = w-1; 
posd(mod(w,2) ==1 ,1) = posd(mod(w,2) ==1 ,1) + max(posd(:));
%pos(mod(w,2) ==1 ,1) = pos(mod(w,2) ==1 ,1) + max(pos(:));
runs1 = round(w/2);
inds = runs1 > 0 & runs1 <= max(runs);
XfAcc = zeros(size(Xf,1),2*accumbins(1));
for i = 1:size(Xf,1)
    XfAcc(i,:) = accumarray(posd(inds,1),Xf(i,inds),[],@mean);
end
bound = abs(mean(XfAcc));%filtfilt(gausswin(5),sum(gausswin(5)),abs(mean(XfAcc)));
thresh = bound > max(bound)*.75; thresh = bwlabel(thresh);
h = hist(thresh,0:max(thresh));h(1) = [];
thresh(ismember(thresh,find(h < 10))) =0;
thresh = thresh > 0;
XfAcc = bsxfun(@minus,XfAcc,mean(XfAcc,2));
%[~,~,XfAcc] = svds(XfAcc,3);XfAcc = XfAcc';
XfAcc = filtfilt(gausswin(10),1,XfAcc')';
d = sqrt(sum(abs(diff(XfAcc,1,2)).^2));
figure;plot(d);
%figure;plot(bound);hold all;plot(abs(mean(XfAcc)));plot(thresh);
%
% for i = 1:2
%     inds = (i-1)*accumbins(1)+(1:accumbins(1));
%     temp = XfAcc(:,thresh(inds));%(:,inds);
%     temp = bsxfun(@minus,temp,mean(temp,2));
%     c = corr(temp);%corr(temp);%
%     [X Y] = meshgrid(1:size(c,1));
%     X = X-Y;
%     X = X - min(X(:)) + 1;
%     cm = accumarray(X(:),c(:),[],@mean);
%     figure;plot(real(cm));hold all;plot(imag(cm));
% end
return
%XfAcc = XfAcc(:,thresh);XfAcc = [real(XfAcc);imag(XfAcc)];

%[~,~,v] = svds(bsxfun(@minus,XfAcc,mean(XfAcc,2)),2);
%v = filtfilt(gausswin(2),1,v);
c = max(1,round((1:size(v,1))/size(v,1)*64));
col = colormap;
figure;plot(v(:,1),v(:,2),'k');hold all;scatter(v(:,1),v(:,2),[],col(c,:),'filled');
figure;imagesc(complexIm(XfAcc,1,1));
return
t1 = zeros(size(t,1),max(runs),accumbins(1)*2);
for j = 1:size(t,1)
         t1(j,:,:) = accumarray([runs1(inds); posd(inds,1)']',t(j,inds),[max(runs) 2*accumbins(1)] ,@mean);
end
%h1 = figure;
spatial = randn(size(t1,1),2*accumbins(1));
for i = 1:size(t1,1)
    temp = reshape(t1(i,:),[max(runs) 2*accumbins(1)]);
    [u,s,v1] = svds(temp,1);
    spatial(i,:) = exp(1i*angle(mean(u)))*s*v1';% 
%     if -min(v) > max(v)
%         v = -v; 
%     end
end

if ~exist('posInds','var') || isempty(posInds)
    posInds = find(max(abs(spatial')) > 10);
else
   posInds = 1:size(r,1);%
end
% size(t)
% t = reshape(t(:),size(t));
% t1 = reshape(t1(:),size(t1));
figure;plot(abs(spatial)');
spatial = spatial(posInds,:);
[~,peakLoc] = max(abs(spatial)');
[~,indLoc] = sort(peakLoc);
%peakLoc = peakLoc(indLoc);
posInds = 1:size(t,1);%posInds(indLoc);
spatial = spatial(indLoc,:);
t = t(posInds,:);t1 = t1(posInds,:,:);
t = bsxfun(@times,t,exp(1i*-angle(v(:,1))).');
% sPlot(t);
% sPlot(morFilter(t,1250/32,8));
% sPlot(abs(t));
h1 = figure;
h2 = figure;
xdim = ceil(sqrt(numel(posInds)));ydim = ceil(numel(posInds)/xdim);
sk = ones(1,numel(posInds));
tes = zeros(numel(posInds),max(runs),2*accumbins(1));
if exist('probes','var') && ~isempty(probes)
    ups = zeros(numel(posInds),size(probes,1),size(probes,2)+1);
else
    ups = zeros(numel(posInds),8,(size(Xf,1))/8);%/2
end

% meanAng = zeros(1,size(t,1));meanAng1 = meanAng;
% for i = 1:size(t,1)
%     meanAng(i) = angle(mean(r1(1:size(Xf,1),posInds(i))));%
%     meanAng1(i) = angle(mean(t(i,posd(:,1) == peakLoc(i))));% < peakLoc(i)+accumbins(1)/10 & posd(:,1) > peakLoc(i)-accumbins(1)/10));
%     %meanAng(i) = angle(meanAng(i));
% %    meanAng(i) = circ_mean(angle(r1(1:size(Xf,1)-1,posInds(i))),abs(r1(1:size(Xf,1)-1,posInds(i))));
% end
% figure;scatter(meanAng,meanAng1);return
% spatial = bsxfun(@times,spatial,exp(1i*(pi/2-meanAng')));
%figure;imagesc(complexIm(spatial,0,1));
%spsh = spatial;
%for i = 1:size(spsh,1)
%    spsh(i,:) = circshift(spsh(i,:),[0 -peakLoc(i)+accumbins(1)]);
%end
%figure;imagesc(complexIm(spsh,0,1));
for i = 1:numel(posInds)
    te = reshape(t1(i,:),[max(runs) 2*accumbins(1)]);
%     if skewness(te(:)) < 0
%         te = -te;
%         sk(i) = -1;
%     end
    u = r1(:,posInds(i));%*exp(1i*(pi/2-meanAng(i)));
    tes(i,:,:) = te*exp(1i*angle(mean(u)));
    figure(h1);subplot(xdim,ydim,i);imagesc(complexIm(imfilter(squeeze(tes(i,:,:)),fspecial('gaussian',5,1)),0,1));axis off;%s(temp(indLoc(i))),[0 max(te(:))].*exp(1i*(pi/2-meanAng(i)))
    if exist('alphas','var')
        title(alphas(posInds(i)))
    end
    %meanAng1(i) = ;
    u = r2(:,posInds(i))*exp(-1i*angle(mean(u)));
    if exist('probes','var') && ~isempty(probes)
        up1 = probes;
        for ii = 1:size(probes,1)
            for j = 1:size(probes,2)
                up1(ii,j) = u(probes(ii,j)+1-min(probes(:)));%-256
            end
        end
        %up1 = up1(:,[1:4 6 5 8 7]);
        up1 = up1(:,[1:12 14 13 16 15]);
        up1 = [up1(:,1:8) zeros(size(up1,1),1) up1(:,9:16)];
    else
        up1 = reshape(u,[8,(size(Xf,1))/8]);
    end
%    ups(i,:,:) = up1;
    figure(h2);subplot(xdim,ydim,i);imagesc(complexIm(up1,0,1));axis off;
end
% h3 = figure;subplot(311);imagesc(reshape(std(r),[8 size(Xf,1)/8]));
% subplot(312);imagesc(reshape(std(r(posInds,:)),[8 size(Xf,1)/8]));
% subplot(313);imagesc(reshape(mean(abs(r(posInds,:))),[8 size(Xf,1)/8]));
% freezeColors(h3);
%sPlot([bsxfun(@times,t,sk'); vel']);
%figure;imagesc(complexIm(corr(ups(:,:)'),0,1));
superImpC(tes,[],1,prctile(abs(tes(:)),99.5));

% figure;
% for i = 1:max(runs1)
%     for j = 1:size(t,1)
%         indUse = runs1' == i & posd(:,1) < peakLoc(j)+accumbins(1)/10 & posd(:,1) > peakLoc(j)-accumbins(1)/10;
% %        plot(pos(indUse,1),posd(indUse,1));
% %        meanAng(j) = angle(mean(t(j,indUse)));
%         scatter(pos(indUse,1),angle(t(j,indUse)*exp(-1i*meanAng(j))),abs(t(j,indUse))*40,'filled');%angle(spatial(i,peakLoc(j)))
%  %       plot(pos(indUse,1),angle(t(j,indUse)*exp(-1i*meanAng(j))),'k');%angle(spatial(i,peakLoc(j)))
%         hold all;
%     end
%     hold off;pause(2);
% end
