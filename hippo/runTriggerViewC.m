function [posInds,t,tes] = runTriggerViewC(pos,v,Xf,accumbins,thresh,r,probes,posInds,r1)

bounds = [.1 .9];
pos(pos == -1) = nan;
reject = 0;
for i = 1:4
    reject = reject | min([0; diff(pos(:,i))],flipud([0; diff(flipud(pos(:,i)))])) < -20;
end
pos(reject,:) = nan;
if size(v,1) < size(pos,1)
    pos = pos(1:size(v,1),:);
end
for i = 1:4
    nanInds = find(~isnan(pos(:,i)));
    pos(:,i) = interp1(nanInds,pos(nanInds,i),1:size(pos,1));
end
nanInds = isnan(pos(:,1)) | isnan(pos(:,3));
pos = pos(~nanInds,:);v = v(~nanInds,:);Xf = Xf(:,~nanInds);%sp = sp(:,~nanInds);
vel = angVel(pos);
%vel = diff(pos);
vel = [zeros(1,2); vel(:,1:2)];
for i = 1:2
    vel(:,i) = filtLow(vel(:,i),1250/32,1);
end
veld = [ vel(:,1:2)];
vel = vel(:,1);
vel = vel/max(vel);inds = vel > thresh;
pos = bsxfun(@minus,pos,mean(pos));
[a,~,~] = svd(pos(:,1:2),'econ');pos = a;
for i = 1:2    
    pos(:,i) = pos(:,i) - min(pos(:,i));
    pos(:,i) = pos(:,i)/(max(pos(:,i)));
    pos(:,i) = min(pos(:,i),.9999);
    veld(:,i) = veld(:,i) - min(veld(:,i));
    veld(:,i) = veld(:,i)/max(veld(:,i));
    veld(:,i) = min(veld(:,i),.9999);
    posd(:,i) = floor(pos(:,i)*accumbins(min(numel(accumbins),i)))+1;
    veld(:,i) = floor(veld(:,i)*accumbins(min(numel(accumbins),i)))+1;
end
offSet = 1;
Xf = [bsxfun(@times,Xf,exp(1i*angle(v(:,1))).')];...
%     [zeros(offSet,1); v(1+offSet:end,1).*conj(v(1:end-offSet,1))./abs(v(1:end-offSet,1))].'];
%  Xf = [bsxfun(@times,Xf,v(:,1).');...
%    [zeros(offSet,1); v(1+offSet:end,1).*conj(v(1:end-offSet,1))].'];
%Xf = [real(Xf);imag(Xf)];
inds = bwmorph(inds,'dilate',20);
Xf = Xf(:,inds);posd = posd(inds,:);veld = veld(inds,:);vel = vel(inds);pos = pos(inds,:);
%Xf = bsxfun(@minus,Xf,mean(Xf,2));
if ~exist('r1','var')
    r1 = pinv(r);%r';%
end
%lambda = 1000;
%    [E, D]=pcamat(Xf, 1, size(r,1), 'off','off');
%    dD = flipud(diag(D));
%    r1 = E*inv(sqrt (D) + lambda*eye(size(D)))*E'*r1;%
if exist('posInds','var') && ~isempty(posInds)
    r1 = r1(:,posInds);r = r(posInds,:); %% IS THIS RIGHT??
end
% r = complex(r(:,1:end/2),r(:,end/2+1:end));r1 = complex(r1(1:end/2,:),r1(end/2+1:end,:));
% Xf = zscore([real(Xf);imag(Xf)],0,2);
% Xf = complex(Xf(1:end/2,:),Xf(end/2+1:end,:));
%Xf = zscore(Xf,0,2);
%     [V, D, U] = svd(Xf', 0);     % economy SVD of data matrix
%     B = U*D/sqrt(size(Xf,2));            % PCA mixing-matrix estimate
%     Xf = sqrt(size(Xf,2))*V';
t = (r)*Xf;%r1*bsxfun(@minus,Xf,mean(Xf,2));%
%t = abs(t);%[real(t);imag(t)];
if 0
    [B M] = size(t);
    opts = lbfgs_options('iprint', -1, 'maxits', 20, ...
        'factr', 1e-1, ...
        'cb', @cb_a);
    %a = phi\X;
    M1 = 10000;
    for i = 1:ceil(size(t,2)/M1)
        ind = (i-1)*M1+(1:M1);ind(ind > size(t,2)) = [];
        M = numel(ind);
        lb  = zeros(1,B*M); % lower bound
        ub  = zeros(1,B*M); % upper bound
        nb  = ones(1,B*M);  % bound type (lower only)
        nb  = zeros(1,B*M); % bound type (none)
        temp = t(:,ind);
        t(:,ind) = reshape(lbfgs(@objfun_a,temp(:),lb,ub,nb,opts,pinv(r),zscore(Xf(:,ind),0,2),2),B,M);
    end
end
% %2d stuff
% %
% % for i = 1:size(t,1)
% %    cc(i,:) = xcorr(t(i,:),vel,1000);
% % end
% % sPlot(cc);
% %figure;plot(cc');
% %xdim = ceil(sqrt(size(cc,1)));ydim= ceil(size(cc,1)/xdim);
% %posd = posd(inds,:);veld = veld(inds,:);
% %figure;for i = 1:size(cc,1)
% %    subplot(xdim,ydim,i);imagesc(imfilter(accumarray(veld,t(i,:),accumbins,@mean,0),fspecial('gaussian',5,1)));
% %end
% %sPlot([10*vel';t;abs(v(:,1)')/1000]);
% if isempty(posInds)
%     posInds = 1:size(r1,2);
% end
% xdim = ceil(sqrt(numel(posInds)));ydim = ceil(numel(posInds)/xdim);
% f1 = figure;f2 = figure;
% %[sk,si] = sort(abs(skewness(t,0,2)),'descend');
% %r1 = r1(:,si);t = t(si,:);
% t = r*zscore(Xf,0,2);
% for i = 1:numel(posInds)
%     u = complex(r1(1:size(Xf,1)/2-1,i),r1(size(Xf,1)/2+1:end-1,i));%r1(1:size(Xf,1)-1,posInds(i));%
%         if exist('probes','var') && ~isempty(probes)
%         up1 = probes;
%         for ii = 1:size(probes,1)
%             for j = 1:size(probes,2)
%                 up1(ii,j) = u(probes(ii,j)+1);%-256
%             end
%         end
%         %    up1 = up1(:,[1:4 6 5 8 7]);
%         up1 = up1(:,[1:12 14 13 16 15]);
%         %up1 = diff(up1);
%         up1 = [up1(:,1:8) zeros(size(up1,1),1) up1(:,9:16)];
%     else
%         up1 = reshape(u,[8 8]);
%     end
%     figure(f1);subplot(xdim,ydim,i);imagesc(complexIm(up1,0,1));axis off;
%     figure(f2);subplot(xdim,ydim,i);imagesc(imfilter(accumarray(posd,t(i,:),accumbins,@mean,0),fspecial('gaussian',5,1)));axis off;
% end
% sPlot([10*vel';t;abs(v(inds,1)')/1000]);
% return
% %%FOR 1D TRACK
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
runs = bwlabel(b > 0);
vInterp = zeros(2,size(t,1),max(runs),accumbins(1));
w = watershed(b==0);
w = w-1; 
posd(mod(w,2) ==1 ,1) = posd(mod(w,2) ==1 ,1) + max(posd(:));
pos(mod(w,2) ==1 ,1) = pos(mod(w,2) ==1 ,1) + max(pos(:));
runs1 = round(w/2);
inds = runs1 > 0 & runs1 <= max(runs);
t1 = zeros(size(t,1),max(runs),accumbins(1)*2);
for j = 1:size(t,1)
         t1(j,:,:) = accumarray([runs1(inds); posd(inds,1)']',t(j,inds),[max(runs) 2*accumbins(1)] ,@mean);
end
%h1 = figure;
spatial = randn(size(t1,1),2*accumbins(1));
for i = 1:size(t1,1)
    temp = reshape(t1(i,:),[max(runs) 2*accumbins(1)]);
    [u,s,v] = svds(temp,1);
    spatial(i,:) = exp(1i*angle(mean(u)))*s*v';% 
%     if -min(v) > max(v) 
%         v = -v; 
%     end
end

if ~exist('posInds','var') || isempty(posInds)
    posInds = find(max(abs(spatial')) > 5);
else
   posInds = 1:size(r,1);%
end
t = t(posInds,:);t1 = t1(posInds,:,:);
t = reshape(zscore(t(:)),size(t));
t1 = reshape(zscore(t1(:)),size(t1));
figure;plot(abs(spatial)');
spatial = spatial(posInds,:);
[~,peakLoc] = max(abs(spatial)');
[~,indLoc] = sort(peakLoc);
peakLoc = peakLoc(indLoc);
%posInds = posInds(indLoc);
spatial = spatial(indLoc,:);
t = t(indLoc,:);

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

%t1 = reshape(zscore(t1(:)),size(t1));
meanAng = zeros(1,size(t,1));
for i = 1:size(t,1)
    meanAng(i) = mean(r1(1:size(Xf,1),posInds(i)));%
    meanAng(i) = mean(t(i,posd(:,1) == peakLoc(i)));% < peakLoc(i)+accumbins(1)/10 & posd(:,1) > peakLoc(i)-accumbins(1)/10));
    meanAng(i) = angle(meanAng(i));
%    meanAng(i) = circ_mean(angle(r1(1:size(Xf,1)-1,posInds(i))),abs(r1(1:size(Xf,1)-1,posInds(i))));
end
spatial = bsxfun(@times,spatial,exp(1i*(pi/2-meanAng')));
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
    figure(h1);subplot(xdim,ydim,i);imagesc(complexIm(imfilter(te.*exp(1i*(pi/2-meanAng(i))),fspecial('gaussian',5,1)),0,1));axis off;%s(temp(indLoc(i))),[0 max(te(:))]
    tes(i,:,:) = te;
    u = r1(1:size(Xf,1),posInds(i));%*exp(1i*(pi/2-meanAng(i)));
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
        %up1 = reshape(u,[8 ,(size(Xf,1)/2-1)/8]);
        %up1 = reshape(u,[8,(size(Xf,1))/8]);
    end
    %ups(i,:,:) = up1;
    %figure(h2);subplot(xdim,ydim,i);imagesc(complexIm(up1,0,1));axis off;
end

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