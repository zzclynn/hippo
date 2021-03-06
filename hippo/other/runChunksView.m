function [u m] = runChunksView(act,pos,X,ind)

win = -100:100;
act = filtfilt(gausswin(5),1,act(ind,:));
if -min(act) > max(act)
    act = -act;
end

figure;plot(zscore(act));
[pks,locs] = findpeaks(zscore(act),'minpeakheight',3);
hold all;scatter(locs,pks,'r','filled');
Xsamp = zeros(numel(pks),size(X,1),numel(win));
for i = win
    Xsamp(:,:,i-win(1)+1) = X(:,pos(locs,3)+i)';
end
figure;
for i = 1:size(Xsamp,1)
    plot(squeeze(Xsamp(i,:,:))');axis tight;pause(5);
%    sPlot(squeeze(Xsamp(i,:,:)),[],0);pause(1);
end
sPlot(squeeze(mean(Xsamp)));
figure;plot(squeeze(mean(Xsamp))');
return
bins = 100;
[~,ind] = min(diff(pos(:,2)));
ind = ind+1;
pos(:,1) = max(0,pos(:,1)-prctile(pos(:,1),1));
pos(:,1) = min(.999,pos(:,1)/prctile(pos(:,1),99));
pos(ind:end,1) = pos(ind:end,1)+1;pos(:,1) = pos(:,1)/2;
pos(:,1) = floor(pos(:,1)*bins)+1;

figure;
bins = [bins max(pos(:,2))];
%ac = zeros(size(act,1),bins(1),bins(2));
u = zeros(size(act,1),bins(1));m = u;
for i = 1:size(act,1)
    ac = accumarray(pos,act(i,:)',bins,@mean);%[bins ]
    [u(i,:),~,~] = svds(ac,1);
    m(i,:) = mean(ac,2);
%    imagesc(squeeze(ac(i,:,:))');drawnow;
% col = max(0,act(i,:)-prctile(act(i,:),1));
% col = min(col/prctile(col,99),.999);
% col = floor(col*64)+1;
% scatter(pos(:,1),pos(:,2),[],col,'filled');pause(.2);drawnow;
end
figure;plot(u');
figure;plot(m');