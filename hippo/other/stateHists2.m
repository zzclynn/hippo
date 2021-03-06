function stateHists2(pos,resp,inds)
%2D histogram of neural response properties
%   Detailed explanation goes here
if ~exist('inds','var')
    inds = 1:size(resp,1);
end
%warning off all;
%pos(pos == -1) = nan;
%v = diff(pos);
vel = angVel(pos);inds = vel(:,1) > .1;
%v = filtLow(v',1250/32,3)';
%v(isnan(v)) = 0;
v = pos(inds,1:2);%v(inds,:);
v(isnan(v)) = 60;
resp = resp(inds,:);
%state = [pos(:,1) v(:,1)];
vp12 = resp(:,1).*conj(resp(:,2));vp12 = filtLow(vp12,1250/32,1);
vp1 = resp(:,1).*conj(resp(:,1));vp1 = filtLow(vp1,1250/32,1);
vp2 = resp(:,2).*conj(resp(:,2));vp2 = filtLow(vp2,1250/32,1);
vp11 = resp(1:end-1,1).*conj(resp(2:end,1));vp11 = filtLow(vp11,1250/32,1);
vp11 = [0;vp11];%vp11 = gsorth(vp11);
vp12 = vp12;%./vp1
%state = [real(vp12)-imag(vp12) real(vp12)+imag(vp12)];
%state = [real(vp11)-imag(vp11) real(vp11)+imag(vp11)];
state = v;% [real(vp12) imag(vp12)];
%figure;plot(v(:,1)./max(v(:,1)));hold all;
%plot(v(:,2)./max(v(:,1)));
%plot(bsxfun(@rdivide,state,max(eps,max(state(:)))));
%figure;imagesc(log(hist3(state,[100 100])));
[data al] = binData(state,vp12,[60 60]);%resp
figure;imagesc(imag(data));
%colormap(hsv);return
figure;plot(nanmean(data));hold all;plot(nanmean(data,2));
%figure;imagesc(log(al));
drawnow;
%set(gca,'color','k');
%set(h,'AlphaData',al);

function [data al] = binData(x,y,nbins)
for i = 1:size(x,2)
    s = std(x(:,i));m = mean(x(:,i));
    x(:,i) = min(max(x(:,i),m-3*s),m+3*s);
    x(:,i) = x(:,i) - min(x(:,i));
    x(:,i) = ceil(nbins(min(i,numel(nbins)))*max(eps,x(:,i))/max(x(:,i)));
    x(:,i) = min(nbins(min(i,numel(nbins))),x(:,i));
end
[size(x) size(y) size(nbins)]
data = accumarray(x,y,nbins,@nanmean);
al = accumarray(x,y,nbins,@ste);
al = accumarray(x,y,nbins,@histo);
al = al-min(al(:));
al = al/max(al(:));
data(data == 0) =nan;

function a = histo(a)
a = numel(a);

function a = gsorth(a)
a=complex(real(a),imag(a)-real(a)*diag(sum(real(a).*imag(a))./sum(real(a).^2)));

function x1 = ste(x)
x1 = (numel(x))/var(x);
x1 = log(x1);
if numel(x) < 2
    x1 = 0;
elseif abs(x1) == inf || isnan(x1)
    x1 = 0;
end