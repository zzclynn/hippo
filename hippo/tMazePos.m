function [lActs rActs] = tMazePos(pos,act)

bounds = [20 160 160 300];
thresh = 3;
dec = 8;%round(size(pos,1)/size(act,2));
for i =1:2
    posd(:,i) = decimate(pos(:,i),dec);
end
for i = size(act,1):-1:1
    actd(i,:) = decimate(abs(act(i,:)),dec);
end
%act = actd; clear actd;
posd = posd(1:size(actd,2),:);
bounded = posd(:,1) > bounds(1) & posd(:,1) < bounds(2) & ...
    posd(:,2) > bounds(3) & posd(:,2) < bounds(4);
numExp = 13*8/dec;
bounded = bwmorph(bounded,'dilate',numExp);
for i =1:numExp
    bounded = bounded - bwmorph(bounded,'endpoints');
end
bounded = logical(bounded);
bounded = bwlabel(bounded);
[posMean posSeq] = sideSeq(bounded,posd,mean(bounds(3:4)));

actf = filtLow(abs(act),1250/32,2)*2;
act = abs(act);
bounded1 = round(resample(bounded,dec,1));
buffer = round(1250/32*[-.5 .5]);%[-100 100]/2;
c = jet(range(buffer)+1);
pos = pos(1:numel(bounded1),:);
bounds([1 3]) = bounds([1 3]) - 10;
bounds([2 4]) = bounds([2 4]) + 10;
figure;
for i = 1:max(bounded)
    for j = 1:size(act,1)
        %if max(actf(j,:)) > 3
        [~,m] = max(actf(j,:).*(bounded1' == i));
        inds = m+buffer(1):m+buffer(2);
        useInds = act(j,inds) > 1.5;% & bounded1(inds)' == i;
        if sum(useInds)
        if posSeq(i) > 0
        subplot(4,4,2*j-1);set(gca,'color','k','xlim',bounds(1:2),'ylim',bounds(3:4));
        hold all;scatter(pos(inds(useInds),1),pos(inds(useInds),2),act(j,inds(useInds)),c(useInds,:),'filled');
        else
        subplot(4,4,2*j);set(gca,'color','k','xlim',bounds(1:2),'ylim',bounds(3:4));
        hold all;scatter(pos(inds(useInds),1),pos(inds(useInds),2),act(j,inds(useInds)),c(useInds,:),'filled');
        end
        end
    end
    drawnow;
end

%f1 = figure;
%f2 = figure;
%lTimes = [];rTimes = [];
%buffer = [-100 100];
%lActs = zeros(size(act,1),sum(posSeq > 0),range(buffer)+1);
%rActs = zeros(size(act,1),sum(posSeq < 0),range(buffer)+1);

%vel = angVel(pos);
%vel = filtLow(vel(:,1),1250/32,1);
% vel = max(eps,vel)*10;
% numFeat = 12;
% c = hist(bounded,0:max(bounded))/3;
% c = jet(max(c(2:end))*dec);
% c1 = jet(numFeat);
% for i = 2:max(bounded)-1
%     if sign(posSeq(i)) ~= sign(posSeq(i-1))
%     f = [find(bounded == i,1,'first') find(bounded == i,1,'last')];
%     f = f*dec;
%     temp = pos(f(1):f(2),1:2);
%     temp(temp(:,1)<bounds(1) | temp(:,1) > bounds(2),1) = nan;
%     temp(temp(:,2)<bounds(3) | temp(:,2) > bounds(4),2) = nan;
%     if posSeq(i) > 0
%         lTimes= [lTimes find(bounded == i,1,'last')];
%         %lActs(:,numel(lTimes),:) = act(:,lTimes(end)+(buffer(1):buffer(2)));
%         if numel(lTimes) <= numFeat
%             figure(f1);subplot(4,numFeat/2,numel(lTimes));%hold all;scatter(posd(bounded == i,1),posd(bounded == i,2),[],jet(sum(bounded == i)));drawnow
%             scatter(pos(f(1):f(2),1),pos(f(1):f(2),2),vel(f(1):f(2)),c(max(1,end-range(f):end),:),'filled');%c(min(size(c,1),1:range(f)+1),:)
%             figure(f2);subplot(221);plot(-range(f):0,temp(:,1),'color',c1(numel(lTimes),:),'linewidth',2);hold all;
%             subplot(222);plot(-range(f):0,temp(:,2),'color',c1(numel(lTimes),:),'linewidth',2);hold all;
%         end
%     else
%         rTimes= [rTimes find(bounded == i,1,'last')];
%         %rActs(:,numel(rTimes),:) = act(:,rTimes(end)+(buffer(1):buffer(2)));
%         if numel(rTimes) <= numFeat
%             figure(f1);subplot(4,numFeat/2,numel(rTimes)+numFeat);%hold all;scatter(posd(bounded == i,1),posd(bounded == i,2),[],jet(sum(bounded == i)));drawnow;
%             scatter(pos(f(1):f(2),1),pos(f(1):f(2),2),vel(f(1):f(2)),c(max(1,end-range(f):end),:),'filled');
%             figure(f2);subplot(223);plot(-range(f):0,temp(:,1),'color',c1(numel(rTimes),:),'linewidth',2);hold all;
%             subplot(224);plot(-range(f):0,temp(:,2),'color',c1(numel(rTimes),:),'linewidth',2);hold all;
%         end
%     end
%     figure(f1);set(gca,'xlim',bounds(1:2),'ylim',bounds(3:4),'xtick',[],'ytick',[]);drawnow;axis square;
%     end
% end

%figure;superImp(lActs);
%figure;superImp(rActs);

function [runDir posSeq] = sideSeq(runInds,pos,ref)
posSeq = zeros(1,max(runInds)+1);
runDir = zeros(size(runInds));
for i = 1:max(runInds)+1
    if i == 1
        inds = 1:find(runInds == 1,1)-1;
    elseif i == max(runInds)+1
        inds = find(runInds == i-1, 1, 'last' )+1:size(pos,1);
    else
        inds = (find(runInds == i-1)+1):(find(runInds == i)-1);
    end
    temp = [max(pos(inds,2))-ref min(pos(inds,2))-ref];
    if abs(temp(1)) > abs(temp(2))
        posSeq(i) = temp(1);
    else
        posSeq(i) = temp(2);
    end
    runDir(runInds == i) = posSeq(i) > 0;
end