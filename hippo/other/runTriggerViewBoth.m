function [ac numSamps vSamps] = runTriggerViewBoth(Xf,v,pos,thresh,accumbins,W,posInds)
%% some kind of artifact

%ratio = round(size(X,2)/size(pos,1));
%dec = 32/ratio;
%%Processing of position information
Xf = Xf(:,1:size(v,1));
bounds = [.2 .9];
pos(pos == -1) = nan;
reject = 0;
for i = 1:4
    reject = reject | min([0; diff(pos(:,i))],flipud([0; diff(flipud(pos(:,i)))])) < -20;
end
pos(reject,:) = nan;
for i = 1:4
    nanInds = find(~isnan(pos(:,i)));
    pos(:,i) = interp1(nanInds,pos(nanInds,i),1:size(pos,1));
end
nanInds = isnan(pos(:,1)) | isnan(pos(:,3));
vel = angVel(pos);vel = vel(:,1);
vel = [0; vel];
pos = bsxfun(@minus,pos,nanmean(pos));
[~,~,c] = svd(pos(~nanInds,1:2),'econ');pos = (c\pos(:,1:2)')';%pos = a;pos(nanInds) = nan;
pos = pos(:,1);
pos = pos - min(pos) + eps;
pos = pos/(max(pos)+eps);
pos(nanInds) = 0;
vel = filtLow(vel,1250/32,1);
nanInds = find(~isnan(vel));
vel = interp1(nanInds,vel(nanInds),1:numel(vel));
inds = vel > thresh(1);
%% which repetition of rat running
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
%runs = bwlabel(b > 0);
runs = watershed(b==0);
f = find(runs == 0);
runs(f) = runs(f-1);
% for i = 1:max(runs)
%     if mean(diff(pos(w == i))) < 0
%         pos(w == i) = 2 - pos(w == i);
%     end
% end
dPos = [0; diff(pos)];
%vel = resample(vel,ratio,1);    
%posd(mod(w,2) ==1 ,1) = posd(mod(w,2) ==1 ,1) + max(posd(:));
%inds(pos < bounds(1) | pos > bounds(2)) = 0;
%% which contiguous chunk of data
chunk = bwlabel(inds);
h = hist(chunk,0:max(chunk));
a = accumarray([ones(size(chunk)); chunk+1]',pos,[],@mean);
f = find(h(2:end) < 1250/32*thresh(2) | a(2:end) < bounds(1) | a(2:end) > bounds(2));
inds(ismember(chunk,f)) = 0;
%chunk1 = bwlabel(round(resample(double(inds),ratio,1)));chunk1 = chunk1(1:size(X,2));
a = accumarray(runs'+1,dPos,[],@mean);f = find(a(2:end) > 0);
pos(ismember(runs,f)) = 2-pos(ismember(runs,f));pos = pos/2;
runs = ceil(runs/2);
%runs1 = round(resample([runs runs(end)*ones(1,100)],ratio,1));runs1 = runs1(1:size(X,2));
posd = floor(pos*accumbins*2)+1;posd = min(2*accumbins,max(1,posd));
% pos = resample(pos,ratio,1);
% pos = pos(1:size(X,2)); 
% posd1 = floor(pos*accumbins*2)+1;posd1 = min(accumbins*2,max(1,posd1));
% %posd(ismember(reg,f)) = posd(ismember(reg,f)) + accumbins;
% %% whiten X
% if ~exist('whiteningMatrix','var') || isempty(whiteningMatrix)
%     numSamples = 50000;
%     indsSub = rand(numel(inds),1) < numSamples/sum(inds);
%     [Ex, Dx] = eig(cov(X(:,indsSub' & inds)'));
%     d = flipud(diag(Dx));
%     cumVar = sum(d);
%     maxLastEig = sum(cumsum(d)/cumVar < .9999999)
%     Dx = Dx(end-maxLastEig+1:end,end-maxLastEig+1:end);
%     Ex = Ex(:,end-maxLastEig+1:end);
%     factors = diag(Dx);
%     noise_factors = ones(size(Dx,1),1);
%     rolloff_ind = sum(cumsum(flipud(factors))/cumVar > .999999)
%     noise_factors(1:rolloff_ind) = .5*(1+cos(linspace(pi-.01,0,rolloff_ind)));
%     Dx = diag(factors./noise_factors);
%     whiteningMatrix = sqrt(inv(Dx)) * Ex';
%     dewhiteningMatrix = Ex * sqrt (Dx);
%     %else
%     %whiteningMatrix = pinv(dewhiteningMatrix);
% end
% X = whiteningMatrix * X;
% %          phi1 = phi;
% %     [~,J,R] = size(phi);
% %     phi = zeros(size(whiteningMatrix,1),J,R);
% %     for j = 1:J
% %         phi(:,j,:) =  whiteningMatrix * squeeze(phi1(:,j,:));
% %     end
% 
% 
% opts_lbfgs_a = lbfgs_options('iprint', -1, 'maxits', 20,'factr', 0.01, 'cb', @cb_a);
% [N,J,R] = size(phi);
% ac1 =0;numSamps1 = 0;
% lambda = [.5 3/50];%[.8 .25];%2.5;
% for j = 1:max(chunk1)
%     Xsamp = X(:,chunk1 == j);
%     %% compute the map estimate
%     S = size(Xsamp,2);
%     P = S+R-1;	% number of selection locations for source generation
%     a0 = zeros(J, P);
%     %% no bounds
%     lb  = zeros(1,J*P); % lower bound
%     ub  = zeros(1,J*P); % upper bound
%     nb  = 0*ones(1,J*P); % bound type (none)
%     a1 = lbfgs(@objfun_a_conv, a0(:), lb, ub, nb, opts_lbfgs_a, Xsamp, phi, lambda);
%     a1 = reshape(a1, J, P);
%     [~,id] = meshgrid(1:S,1:J);id = id';
%     aTemp = a1(:,1:S);aTemp = aTemp';
%     ac1 = ac1 + accumarray([id(:) repmat(runs1(chunk1 == j)',[J 1]) ...
%         repmat(posd1(chunk1 == j),[J 1])],abs(aTemp(:)),[J max(runs1) max(posd)],@sum);
%     numSamps1 = numSamps1 + accumarray([runs1(chunk1 == j)' posd1(chunk1 == j)],ones(1,sum(chunk1 == j)),[max(runs1) max(posd)],@sum);
% %     subplot(211);imagesc(a1);
% %     subplot(212);imagesc(bsxfun(@rdivide,ac,numSamps'));
% %     drawnow;
% end
if ~exist('W','var')
    [W,s] = svds(Xf(:,inds),min(size(Xf,1),64));
    L2=s.^2;
    dsum=diag(L2)/trace(L2);
    Xf = pinv(W)*Xf;
else
    if exist('posInds','var')
        Xf1 = zeros(numel(posInds)+1,size(Xf,2));
        A = pinv(W);
        for i = 1:numel(posInds)
            temp = A(:,posInds(i))*W(posInds(i),:)*Xf - Xf;
            Xf1(i,:) = sqrt(sum(temp.*conj(temp)));
        end
        Xf1(end,:) = sqrt(sum(Xf.*conj(Xf)));
        Xf = Xf1;clear Xf1;
    else
        Xf = W*Xf;
    end
end

Xf = bsxfun(@rdivide,Xf,std(Xf(:,inds),0,2));
if ~exist('posInds','var')
    Xf = bsxfun(@times,Xf,exp(1i*angle(v(:,1)).'));
end
for j = 1:size(Xf,1)
     ac(j,:,:) = accumarray([runs(inds); posd(inds)']',Xf(j,inds),[max(runs) 2*accumbins] ,@sum);
end
numSamps = accumarray([runs(inds); posd(inds)']',ones(1,sum(inds)),[max(runs) max(posd)],@sum);
vSamps = accumarray([runs(inds); posd(inds)']',vel(inds),[max(runs) max(posd)],@sum);
if ~exist('posInds','var')
    ac(:,:) = bsxfun(@rdivide,ac(:,:),max(1,numSamps(:)).');
else
    ac(1:end-1,:) = 1-bsxfun(@rdivide,ac(1:end-1,:),ac(end,:));
    ac(end,:,:) = [];
end
vSamps = vSamps./max(1,numSamps);
%[id,~] = meshgrid(1:size(Xf,1),1:size(Xf,2));
%ac = accumarray([id(:) repmat([runs(inds); posd(inds)'],[1 size(Xf,2)])'],Xf(:),[size(Xf,1) max(runs) 2*accumbins] ,@mean);