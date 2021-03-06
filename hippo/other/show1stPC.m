function show1stPC(pos,v,Xf,accumbins,thresh)

bounds = [.2 .8];
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
%[~,~,v1] = svds(Xf,4);%Xf = v1.';%
%Xf = bsxfun(@times,v1,exp(1i*-angle(v1(:,1)))).';
Xf = [bsxfun(@times,Xf,exp(1i*angle(v(:,1))).')];
inds = bwmorph(inds,'dilate',20);
Xf = filtLow(Xf,1250/32,2);
Xf = Xf(:,inds);posd = posd(inds,:);veld = veld(inds,:);vel = vel(inds);pos = pos(inds,:);
%Xf = zscore(Xf,0,2);
v = Xf.';
[~,s,v] = svd(bsxfun(@minus,Xf,mean(Xf,2)),'econ');
s = diag(s).^2;
% %%FOR 1D TRACK
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
runs = bwlabel(b > 0);
vInterp = zeros(2,max(runs),accumbins(1));
w = watershed(b==0);
%w = w-1;
%figure;plot(posd(:,1));hold all;plot(w);return
figure;
inda = [1 2 4 8];
for j = 1:4
    for k = 1:2
        runs1 = bwlabel(w>0 & mod(w,2) == k-1 & w <=2*max(runs));%b*((-1)^k)>0);
        inds = runs1 > 0;
        vInterp(k,:,:) = accumarray([runs1(inds); posd(inds,1)']',v(inds,inda(j)),[max(runs) accumbins(1)] ,@mean);
    end
    subplot(2,2,j);imagesc(complexIm(imfilter([squeeze(vInterp(1,:,:)) squeeze(vInterp(2,:,:))],fspecial('gaussian',5,.5)),0,1));
    set(gca,'fontsize',16,'xtick',[1 accumbins(1) accumbins(1)*2],'xticklabel',{'0','250','0'}...
        ,'ytick',[1 size(vInterp,2)]);ylabel('Trial #');xlabel('Position (cm)');title(['PC ' num2str(inda(j)) ' (' num2str(s(inda(j))/sum(s)*100,'%6.2g') '%)']);
    if j ~= 3
        axis off;
    end
end
% t1 = [squeeze(vInterp(1,:,:)) squeeze(vInterp(2,:,:))];
% figure;image(complexIm(imfilter(t1,fspecial('gaussian',5,0.5)),0,1));
