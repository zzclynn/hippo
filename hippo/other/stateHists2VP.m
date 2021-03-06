function stateHists2VP(pos,resp,inds)
%2D histogram of neural response properties
lowFilt = 5;
if ~exist('inds','var')
    inds = 1:size(resp,1);
end
%warning off all;
pos(pos == -1) = nan;
v = diff(pos);
%v = angVel(pos);
v = filtLow(v',1250/32,5)';
v = v(inds,:);resp = resp(inds,:);pos = pos(inds,:);
state = [pos(:,1) v(:,1)];
vp12 = resp(:,1).*conj(resp(:,2))./abs(resp(:,1));vp12 = filtLow(vp12,1250/32,lowFilt);
vp1 = abs(resp(:,1));vp1 = filtLow(vp1,1250/32,lowFilt);
vp2 = abs(resp(:,2));vp2 = filtLow(vp2,1250/32,lowFilt);
vp11 = resp(1:end-1,1).*conj(resp(2:end,1))./abs(resp(1:end-1,1));vp11 = filtLow(vp11,1250/32,lowFilt);
vp11 = [0;vp11];%vp11 = gsorth(vp11);
%plot(bsxfun(@rdivide,state,max(eps,max(state(:)))));
figure;imagesc(log(hist3(state,[10 7])));
[data al] = binData(state,vp12,[10 7]);
figure;subplot(221);imagesc(real(data));
subplot(222);imagesc(imag(data));
subplot(223);imagesc(abs(data));
subplot(224);imagesc(angle(data));
%figure;imagesc(data,[0 1.5]);
%figure;plot(nanmean(data));hold all;plot(nanmean(data,2));
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