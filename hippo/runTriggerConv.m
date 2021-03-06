function [phi whiteningMatrix] = runTriggerConv(X,pos,thresh,dewhiteningMatrix,phi)
%% run convolutional sparse coding, then bin and render activations.

ratio = round(size(X,2)/size(pos,1));
dec = 32/ratio;
peakToPeak = ceil(1250/dec/8);
%%Processing of position information
bounds = [.1 .9];
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
vel = [0; vel(:,1)];
pos = bsxfun(@minus,pos,nanmean(pos));
[~,~,c] = svd(pos(~nanInds,1:2),'econ');pos = (c\pos(:,1:2)')';%pos = a;pos(nanInds) = nan;
pos = pos(:,1);
for i = 1:size(pos,2)   
    pos(:,i) = pos(:,i) - min(pos(:,i));
    pos(:,i) = pos(:,i)/(max(pos(:,i)));
%    pos(:,i) = min(pos(:,i),.9999);
end
pos(nanInds) = 0;
vel = filtLow(vel,1250/32,.5);
vela = vel;
nanInds = find(~isnan(vel));
vel = interp1(nanInds,vel(nanInds),1:numel(vel));
%vel = vel/max(vel);
vel = resample(vel,ratio,1);
pos = resample(pos,ratio,1);
pos = pos(1:size(X,2),:); 
vel = vel(1:size(X,2));
inds = vel > thresh(1);
%inds(pos < bounds(1) | pos > bounds(2)) = 0;
reg = bwlabel(inds);
h = hist(reg,0:max(reg));
a = accumarray(reg'+1,pos,[],@mean);
f = find(h(2:end) < 1250/dec*thresh(2) | a(2:end)' < bounds(1) | a(2:end)' > bounds(2));
inds(ismember(reg,f)) = 0;
reg = bwlabel(inds);
% figure;plot(vel);hold all;plot(inds);return
% figure;
% params.tapers = [3 5]; params.Fs = 1250/32;
% for i = 1:max(r)
%     [S,f] = mtspectrumc(X(1,r == i),params);
%     plot(f,S);pause(1);
% end
%figure;hist(h(2:end),20);
%figure;plot(inds);hold all;plot(vel,'r');
%b = nan*ones(size(pos,1),1);
%b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
%nanInds = find(~isnan(b));
%b = interp1(nanInds,b(nanInds),1:size(pos,1));
%b = [0 diff(b)];
%runs = bwlabel(b > 0);
%w = watershed(b==0);
%% whiten X
%X = bsxfun(@minus,X,mean(X,2));
%S = 64;		% time points in original sources 
J = 1000;		% number of basis functions for source generation
R = 20;%20;		% number of time points in basis functions generating sources
if J >= 1
    if ~exist('dewhiteningMatrix','var') || isempty(dewhiteningMatrix)
        numSamples = 50000;
        indsSub = rand(numel(inds),1) < numSamples/sum(inds);
        %[Ex, Dx] = eig(cov(X(:,indsSub' & inds)'));
        %d = flipud(diag(Dx));
        %cumVar = sum(d);
        %maxLastEig = sum(cumsum(d)/cumVar < .9999999)
        %Dx = Dx(end-maxLastEig+1:end,end-maxLastEig+1:end);
        %Ex = Ex(:,end-maxLastEig+1:end);
        %factors = diag(Dx);
        %noise_factors = ones(size(Dx,1),1);
        %rolloff_ind = sum(cumsum(flipud(factors))/cumVar > .999999)
        %noise_factors(1:rolloff_ind) = .5*(1+cos(linspace(pi-.01,0,rolloff_ind)));
        %Dx = diag(factors./noise_factors);
        %whiteningMatrix = sqrt(inv(Dx)) * Ex';
        %dewhiteningMatrix = Ex * sqrt (Dx);
        [~,whiteningMatrix,dewhiteningMatrix] = whiten(X(:,indsSub' & inds)');
    else
        whiteningMatrix = pinv(dewhiteningMatrix);
    end
else
    numSamples = 50000;
    indsSub = rand(numel(inds),1) < numSamples/sum(inds);
    dewhiteningMatrix = diag(std(X(:,indsSub' & inds),0,2));
    whiteningMatrix = diag(1./diag(dewhiteningMatrix));
end
X = whiteningMatrix * X;
N = size(X,1);		% number of sources
randn('seed',1);
rand('seed',1);

%Jrows = 48;
Jrows = 4;

save_every = 200;
display_every = 5;
%reload_every = 20;
%srate = 15;
%num_chunks = 56;
%Nsz = sqrt(N);
%Fr = 128;
%Fc = 128;
%Ft = 64;
%buff = 4;
%topmargin = 15;
mintype_inf = 'lbfgsb';
%mintype_lrn = 'minimize';
%lrn_searches = 3;
mintype_lrn = 'gd';
opts_lbfgs_a = lbfgs_options('iprint', -1, 'maxits', 20,'factr', 0.01, 'cb', @cb_a);
eta = 0.0001;
eta_up = 1.01;
eta_down = 0.99;
eta_log = [];
target_angle = .01;%0.000001;

paramstr = sprintf('%s_J=%03d_R=%03d_N=%03d_%s', 'hippo', J, R, N, datestr(now,30));
update = 1;
if ~exist('phi','var') || isempty(phi)
phi = randn(N,J,R);
else
    phi1 = phi;
    [~,J,R] = size(phi);
    phi = zeros(N,J,R);
    for j = 1:J
        phi(:,j,:) =  whiteningMatrix * squeeze(phi1(:,j,:));
    end
end
% renormalize
for j = 1:J
    phi(:,j,:) = phi(:,j,:) / sqrt(sum(sum(phi(:,j,:).^2)));
end

num_trials = 200;
% if J == 1
%     lambda = [.2 .25];
% else
%     lambda = [.1 3/50];
% end
lambda = 1;
for q = 1:20
    totResp = zeros(J,1);
    sparsenet
    phi = timeshift_phi(phi,totResp);
    if lambda < 3
        lambda = lambda + .5;
    end
%     if J == 1
%         if lambda(1) < .8
%             lambda(1) = lambda(1) + .2;
%         end
%     else
%     if lambda(1) < .5
%         lambda(1) = lambda(1) + .1;
% %     else
% %         target_angle = target_angle * 0.9;
%     end
%     end
end
