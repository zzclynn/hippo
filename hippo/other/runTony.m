function runTony(pos,Xf,r,accumbins,thresh)
%% runTony shows how to preprocess positional information in order to sort
%% samples by trial, position, and direction, and to extract activation of
%% independent component
%usage >> runTony(pos,Xf,A1,[50 1],.05);
bounds = [.1 .9];
%%Processing of position information
pos(pos == -1) = nan;
reject = 0;
for i = 1:4
    reject = reject | min([0; diff(pos(:,i))],flipud([0; diff(flipud(pos(:,i)))])) < -20;
end
pos(reject,:) = nan;
if size(Xf,2) < size(pos,1)
    pos = pos(1:size(Xf,2),:);
end
for i = 1:4
    nanInds = find(~isnan(pos(:,i)));
    pos(:,i) = interp1(nanInds,pos(nanInds,i),1:size(pos,1));
end
nanInds = isnan(pos(:,1)) | isnan(pos(:,3));
pos = pos(~nanInds,:);Xf = Xf(:,~nanInds);
vel = angVel(pos);
vel = [0; vel(:,1)];
pos = bsxfun(@minus,pos,mean(pos));
[a,~,~] = svd(pos(:,1:2),'econ');pos = a;
for i = 1:2    
    pos(:,i) = pos(:,i) - min(pos(:,i));
    pos(:,i) = pos(:,i)/(max(pos(:,i)));
    pos(:,i) = min(pos(:,i),.9999);
    posd(:,i) = floor(pos(:,i)*accumbins(min(numel(accumbins),i)))+1;
end
%%THE filtLow function requires some functions from the signal processing
%%toolbox, but is not particularly necessary.
vel = filtLow(vel,1250/32,1);
vel = vel/max(vel);
% t contains the activations of the independent components
t = r*zscore(Xf,0,2);
% %%FOR 1D TRACK
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
runs = bwlabel(b > 0);
%% vInterp allows you to bin data by position, may make the decoding more tractable
%vInterp = zeros(2,size(t,1),max(runs),accumbins(1));
%% w breaks apart data into runs
w = watershed(b==0);
w = w-1;
for k = 1:2 %for forward and backward runs
    runs1 = bwlabel(w>0 & mod(w,2) == k-1 & w <=2*max(runs));
    inds = runs1 > 0 & vel' > thresh;   %the 2nd argument is optional, in case you only want samples when rat is running
    %Now inds contains all of the samples for the rat running in 1 direction
%     for j = 1:size(t,1)
%         vInterp(k,j,:,:) = accumarray([runs1(inds); posd(inds,1)']',t(j,inds),[max(runs) accumbins(1)] ,@mean);
%     end
end

function [v h] = angVel(pos)

pos(pos == -1) = nan;
or = pos(:,1:2) - pos(:,3:4);
or(end,:) = [];
pos = diff(pos);
h = hypot(or(:,1),or(:,2));
or = bsxfun(@rdivide,or,h);

v(:,1) = sum(pos(:,1:2).*or,2);
v(:,3) = sum(pos(:,3:4).*or,2);
or(:,2) = -or(:,2);or = or(:,[2 1]);
v(:,2) = sum(pos(:,1:2).*or,2);
v(:,4) = sum(pos(:,3:4).*or,2);

function y = filtLow(sig,Fs,f,order)

if nargin < 4
    order = 8;
end
nanInds = isnan(sig);
sig(nanInds) = 0;
f1 = fdesign.lowpass('n,f3dB',order,f,Fs);
d1 = design(f1,'butter');
%a1 = filter(d1,flipud(filter(d1,flipud(a'))))';
[B,A]= sos2tf(d1.sosMatrix,d1.ScaleValues);
if isreal(sig)
    y = filtfilt(B,A,sig')';
else
    y = complex(filtfilt(B,A,real(sig)')',filtfilt(B,A,imag(sig)')');
end
y(nanInds) = nan;