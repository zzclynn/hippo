function [vals sorted] = alignRuns(pos,u,s,v,spT,spId,spf)
%% use dynamic time warp to align traces
%v = v*s;
figure;
bounds = [.1 .9];
pos(pos == -1) = nan;
sV = size(v,1);
vel = angVel(pos);
vel = filtLow(vel',1250/32,1)';
pos = pos(1:sV,:);vel = vel(1:sV,:);
for i = 1:2
    pos(:,i) = interp1(find(~isnan(pos(:,i))),pos(~isnan(pos(:,i)),i),1:size(pos,1));
    vel(:,i) = interp1(find(~isnan(vel(:,i))),vel(~isnan(vel(:,i)),i),1:size(vel,1));
end
nanInds = isnan(pos(:,1));
pos = pos(~nanInds,:);v = v(~nanInds,:);vel = vel(~nanInds,:);
spf = spf(:,1:sV);
spf = spf(:,~nanInds);
nanInds = find(nanInds);
spT = spT - max(nanInds(nanInds < size(pos,1)/2));
inds = spT < 1 | spT > max(size(pos,1)); spT(inds) = [];spId(inds) = [];
pos = bsxfun(@minus,pos,mean(pos));
[pos,~,~] = svd(pos(:,1:2),'econ');
pos(:,1) = pos(:,1)-min(pos(:,1));pos(:,1) = pos(:,1)/max(pos(:,1));
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
spf = bsxfun(@times,spf,exp(1i*angle(v(:,1))).');
v(:,2) = v(:,2).*exp(1i*angle(-v(:,1)));
for k = 1:2
    runs = bwlabel(b*((-1)^k)>0);
    runs(vel(:,1)' < .1) = 0;
    mem = ismember(floor(spT),find(runs>0)) | ismember(ceil(spT),find(runs>0));
    subTimes = spT(mem);subId = spId(mem);
    [~,spSort] = sort(hist(subId,1:max(spId)),'descend');%sum(abs(spf(:,runs > 0)),2)
    for i = 1:max(runs)-1
        %subplot(131);
        r1 = runs == i; r2 = runs == i+1;
        [d,w] = dtwG(spf(:,r1),spf(:,r2),0);
        [~,w1] = dtwG(pos(r1,1)',pos(r2,1)',0);
        [~,w2] = dtwG(v(r1,2)',v(r2,2)',0);
        [im d] = imRescale(spf(spSort,r1),spf(spSort,r2),w);
        subplot(131);imagesc(im);title(d);
        [im d] = imRescale(spf(spSort,r1),spf(spSort,r2),w1);
        subplot(132);imagesc(im);title(d);
        [im d] = imRescale(spf(spSort,r1),spf(spSort,r2),w2);
        subplot(133);imagesc(im);title(d);
        %imagesc(d);hold on;plot(w(:,2),w(:,1),'-w','linewidth',2);
        %plot(w1(:,2),w1(:,1),'-k','linewidth',2);
        %plot(w2(:,2),w2(:,1),'-r','linewidth',2);
        drawnow;pause(1);
        %imagesc(pdist2(spf(:,runs == i)',spf(:,runs == i+1)',@myDist));drawnow;
    end
%    
%    allHist = zeros(max(spId),100);
%    for i = 1:max(spId)
%        allHist(i,:) = hist(pos(round(subTimes(subId == spSort(i))),1),linspace(0,1,size(allHist,2)));
%    end
%    subplot(2,1,k);plot(sqrt(allHist)');%imagesc(log(allHist));
%     sorted(k,:) = spSort(1:size(vals,2));
%     posHist = hist(pos(runs > 0,1),binsp{2});
%     for l = 1:size(vals,2)%size(spf,1)
%         tempTimes = subTimes(subId == spSort(l));%tempTimes = tempTimes(ismember(floor(tempTimes),find(runs>0)) | ismember(ceil(tempTimes),find(runs>0)));
%         hp = hist3([angle(weighted(tempTimes,temp(spSort(l),:).')) weighted(tempTimes,pos(:,1))],binsp);
%         hp = bsxfun(@rdivide,hp,posHist);
%         vals(k,l,i,j) = ent(hp);
%         %subplot(2,2,(k-1)*2+l);imagesc(hp);title(num2str(vals(k,l,i,j)));drawnow;
%     end
end

function [temp d] = imRescale(sp1,sp2,w)
temp(:,:,1) = sp1(:,w(:,1));temp(:,:,2) = sp2(:,w(:,2));temp(:,:,3) = 0;
d = sqrt(sum(sum(abs(squeeze(temp(:,:,1)-temp(:,:,2))))));
for i = 1:2
    temp(:,:,i) = sqrt(abs(temp(:,:,i))/max(max(max(abs(temp(:,:,i))))));
end

function d = myDist(a,b)
d = sqrt(sum(abs(bsxfun(@minus,b,a)).^2,2));