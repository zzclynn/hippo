function [allX,samplePos,W,t] = runChunks(X,v,pos,act,A)
%% find broadband features that are predictive of ICA activations - outdated

angCol = colormap('hsv');
ratio = round(size(X,2)/size(pos,1));
dec = 32/ratio;
peakToPeak = ceil(1250/dec/8);
%%Processing of position information
thresh = .05;bounds = [.1 .9];win = [-1 1]*ceil(1250/dec/8/2);
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
    pos(:,i) = min(pos(:,i),.9999);
end
pos(nanInds) = 0;
%%THE filtLow function requires some functions from the signal processing
%%toolbox, but is not particularly necessary.
vel = filtLow(vel,1250/32,1);
vel = vel/max(vel);
vel = resample(vel,ratio,1);pos = resample(pos,ratio,1);
act = resample(act',ratio,1)';act = [zeros(size(act,1),size(X,2)-size(act,2)) act];
pos = pos(1:size(X,2),:); vel = vel(1:size(X,2));
inds = vel > thresh;
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
runs = bwlabel(b > 0);
w = watershed(b==0);
w = w-1; %w(w== max(w)) = 0;
allX = zeros(size(X,1)*(range(win)+1),ceil(size(X,2)/peakToPeak/2));counter = 1;
samplePos = [];ys = zeros(size(act,1),size(allX,2));
for k = 1:2
%    runs1 = b*(-1^k)>0;runs1 = bwlabel(runs1);
    runs1 = bwlabel(w>0 & mod(w,2) == k-1 & w <=2*max(runs));
    for i = 1:max(runs1)
        runInds = find(runs1 == i);
        %aV = -angle(v(runInds));
        %[h,pk] = findpeaks(aV,'minpeakheight',pi*.8);
        aV = angle(-v(runInds)*exp(1i*5*pi/6));%*-pi/6)
        [~,pk] = findpeaks(-abs(aV),'minpeakheight',-.3);
        %h(~inds(runInds(pk))) = [];
        pk(~inds(runInds(pk))) = [];
        %plot(aV);hold all;
        %scatter(pk,h,'filled');
        %plot(vel (runInds));hold off;pause(.5);drawnow;
        pk = runInds(1)+pk-1;
        for j = 1:numel(pk)
            temp = X(:,pk(j)+(win(1):win(2)))';
            allX(:,counter) = temp(:);
            ys(:,counter) = mean(act(:,pk(j)+(win(1):win(2))),2);
            counter = counter + 1;
        end
        samplePos = [samplePos; [pos(pk) i*ones(numel(pk),1) pk']];
%         subplot(121);plot(-abs(aV));hold all;scatter(pk-runInds(1)+1,zeros(1,numel(pk)),'filled');hold off;title(i*10000+counter);drawnow;
%         subplot(122);plot(allX(:,max(1,counter-5):counter-1));drawnow;pause(.05);
    end
end
[~,ind] = min(diff(samplePos(:,2)));
ind = ind+1;
samplePos(:,1) = max(0,samplePos(:,1)-prctile(samplePos(:,1),1));
samplePos(:,1) = min(.999,samplePos(:,1)/prctile(samplePos(:,1),99));
samplePos(ind:end,1) = samplePos(ind:end,1)+1;samplePos(:,1) = samplePos(:,1)/2;
allX(:,counter:end) = [];ys(:,counter:end) = [];
complexAct =0;
if ~complexAct
sk = skewness(ys,0,2);
ys = bsxfun(@times,ys,sk);act = bsxfun(@times,act,sk);
%A = bsxfun(@times,A,sk');
end
% figure;
% for i = 1:size(ys,1)
% %     subplot(211);plot(act(i,:));hold all;scatter(samplePos(:,3),ys(i,:));hold off;
% %     subplot(212);
%     scatter(samplePos(:,1),samplePos(:,2),max(.1,abs(ys(i,:))/max(abs(ys(i,:)))*50),angCol(phase2Col(angle(ys(i,:))),:),'filled');pause(1);%skewness(ys(i,:))*
% end
% return
[ys ym] = remmean(ys);
allXOr = allX;
[allX allXm] = remmean(allX);
[cc,~,W] = pipeLine1(ys,allX',3,1);
W = squeeze(mean(W));
yHat = W'*allX;
yHat(end+1,:) = allXm\allXOr;ys(end+1,:) = yHat(end,:);
Wp = zeros(size(W));
for i = 1:size(Wp,2)
    Wp(:,i) = yHat(i,:)'\allX';
end
%Wp = (yHat'\allX')';
Wp = [Wp allXm];
xdim = ceil(sqrt(size(Wp,2)));ydim = ceil(size(Wp,2)/xdim);
A = complex(A(1:end/2-1,:),A(end/2+1:end-1,:));
params.tapers = [1 1];params.Fs = 1250/32*ratio;
yp = prctile(yHat,99.9,2);
f1 = figure;f2 = figure;f3 = figure;f4 = figure;
for i = 1:size(Wp,2)
    %temp = reshape(Wp(:,i)*yp(i)+Wp(:,end)*yp(end),[size(allX,1)/size(X,1) size(X,1)]);
        highResp = yHat(i,:) > prctile(yHat(i,:),98);
        yTemp = filtfilt(gausswin(5),1,yHat(i,:));
        for j = 1:max(samplePos(:,2))
            temp = yTemp;temp(samplePos(:,2) ~= j) = 0;
            [maxRun(j,1) maxRun(j,2)] = max(temp);
        end
        highResp = maxRun(maxRun(:,1) > .5*max(maxRun(:,1)),2);
    temp = reshape(mean(bsxfun(@times,allXOr(:,highResp),yHat(i,highResp)),2),[size(allX,1)/size(X,1) size(X,1)]);
%     figure(f1);subplot(xdim,ydim,i);
%     set(gca,'nextPlot','add','ColorOrder',squeeze(complexIm(A(:,min(size(W,2),i)),0,1)));
%     plot(temp);set(gca,'xticklabel',[],'yticklabel',[]);title(numel(highResp));axis tight;drawnow;%cc(min(size(W,2),i))
%     temp = reshape(mean(Wp(:,i)*yHat(i,highResp)+Wp(:,end)*yHat(end,highResp),2),[size(allX,1)/size(X,1) size(X,1)]);
    figure(f3);subplot(xdim,ydim,i);
    set(gca,'nextPlot','add','ColorOrder',squeeze(complexIm(A(:,min(size(W,2),i)),0,1)));
    plot(temp);set(gca,'xticklabel',[],'yticklabel',[]);title(mean(yHat(i,highResp)));axis tight;drawnow;
    temp = reshape(Wp(:,i),[size(allX,1)/size(X,1) size(X,1)]);
    figure(f4);subplot(xdim,ydim,i);
    set(gca,'nextPlot','add','ColorOrder',squeeze(complexIm(A(:,min(size(W,2),i)),0,1)));
    plot(temp);set(gca,'xticklabel',[],'yticklabel',[]);title(numel(highResp));axis tight;drawnow;
     temp = reshape(mean(bsxfun(@times,allX(:,highResp),yHat(i,highResp)),2),[size(allX,1)/size(X,1) size(X,1)]);
    figure(f2);subplot(xdim,ydim,i);
    set(gca,'nextPlot','add','ColorOrder',squeeze(complexIm(A(:,min(size(W,2),i)),0,1)));
    plot(temp);set(gca,'xticklabel',[],'yticklabel',[]);title(numel(highResp));axis tight;drawnow;%cc(min(size(W,2),i))
    [tempF,f] = mtspectrumc(temp,params);
    fs(i,:) = mean(tempF,2);
%     subplot(2,2,2+i);
%     for j = 1:inf
%     for k = 1:size(temp,1)
%         imagesc(reshape(temp(k,:),[8 8]),[min(temp(:)) max(temp(:))]);pause(.05);drawnow;
%     end
%     end
end
figure;plot(f,fs');
figure;plot(f,log(fs'));
for i = 1:size(fs,1)
    fs(i,:) = filtfilt(gausswin(3),1,fs(i,:));
end
figure;imagesc(f,f,bsxfun(@rdivide,fs,sqrt(sum(fs'.^2))'));
return
imagesc(reshape(W',[size(W,2) size(allX,1)/size(X,1) size(X,1) ]));
figure;imagesc(allX);
figure;plot(reshape(mean(allX,2),[size(allX,1)/size(X,1) size(X,1)]));

figure;scatter(samplePos(:,1),samplePos(:,2),max(.1,ys*50),'filled');
drawnow;
if nargout > 2
[A,W] = gfastica(allX,'lastEig',size(allX,1),'g','tanh','approach','symm','stabilization','on');
t = W*remmean(allX);
%[u,s,v] = svds(allX,10);
%figure;imagesc(allX(:,sortPos));
end
Xm = reshape(mean(allX,2),[size(allX,1)/size(X,1) size(X,1)]);
figure;imagesc(sqrt(Xm)');
% figure;plot(Xm');

function c = phase2Col(ang)
c = ceil((ang+pi)/(2*pi)*64);