function im = superImpC(x,frames,rad,maxVal,meanAng)
%%SUPERIMP combines multiple components into 1 image, assigning each
%%component a different color, for each pixel, choosing the component with
%%the largest magnitude at that location. All components are normalized.
%%INPUTS:   c = all 2-d image components
%%          frames = which components to combine in image (choose ones with well-defined features)
%%          rad = width of gaussian smoothing kernel
%%          maxVal = if you want to normalize all components by a fixed value (default: normalize maximum of each component to 1)
%  if exist('frames','var') && ~isempty(frames)
%      x = x(frames(randperm(numel(frames))),:,:);
%  else
%      x = x(randperm(size(x,1)),:,:);
%  end
if exist('frames','var') && ~isempty(frames)
    x = x(frames,:,:);
end
vs = zeros(size(x,1),size(x,3));
f = fspecial('gaussian',5,rad);
%f([1 2 4 5],:) = 0;f = f/sum(f(:));
for i = 1:size(x,1)
    [u,s,v] = svds(squeeze(x(i,:,:)),1);
    vs(i,:) = mean(u)/abs(mean(u))*s*v';
    if exist('rad','var') && rad
        x(i,:,:) = imfilter(squeeze(x(i,:,:)),f);
    end
    if ~exist('maxVal','var')
        x(i,:,:) = x(i,:,:)/max(max(max(abs(x(i,:,:)))));
    else
        x(i,:,:) =  x(i,:,:)/maxVal;
    end
end
[~,peakLoc] = max(abs(vs)');
x = abs(x);
x = min(1,max(0,x));
[a b]= max(x);
a = squeeze(a); b = squeeze(b);
im = zeros(3,size(a,1),size(a,2));
scale = 4;angCol = colormap('hsv');
figure;
if ~exist('meanAng','var')
    for i = 1:size(vs,1)
        meanAng(i) = 0;%angle(vs(i,peakLoc(i)));
    end
end
c = mod(peakLoc*scale/size(x,3),1);%rand(1,numel(peakLoc));%
cc = angCol(max(1,ceil(c*64)),:);
subplot(5,1,3);set(gca,'nextPlot','add','ColorOrder',cc,'Color',[0 0 0],'xticklabel',[],'yticklabel',[],'fontsize',16);
plot(abs(vs)','linewidth',2);axis tight;%+abs(circshift(vs,[0 size(vs,2)/2]))'
subplot(5,1,[4 5]);hold on;
for i = 1:size(x,1);
    im(1,b == i) = c(i);%i/size(x,1);
    im(2,b == i) = 1;
    im(3,b == i) = a(b == i);
%     scatter(1:size(x,3),angle(vs(i,:)*exp(-1i*angle(vs(i,peakLoc(i))))),...
%         abs(vs(i,:))*100/max(abs(vs(i,:))),cc(i,:),'filled');
inds = 1:size(vs,2);%[max(1,peakLoc(i)-10):min(size(x,3),peakLoc(i)+10) find(abs(vs(i,:)) > .3*max(abs(vs(i,:))))];
    if ~exist('maxVal','var')
        s = abs(vs(i,inds))*50/max(abs(vs(i,:)));
    else
        s =  abs(vs(i,inds))*10/maxVal;
    end
    scatter(inds,angle(vs(i,inds)*exp(-1i*meanAng(i))),...
        s,cc(i,:),'filled');%,'ytick',[-3 0 3],'yticklabel',{'-pi','0','pi'}
%        sqrt(min(1,abs(vs(i,:))'/prctile(abs(vs(i,:)),99)))),'filled');
end
set(gca,'Color',[0 0 0],'xtick',[1 size(x,3)/2 size(x,3)],'xticklabel',[0 250 0],'fontsize',16);
ylabel phase;xlabel('position (cm)');
axis tight;
im = max(0,im);
im = permute(im,[2 3 1]);
im = hsv2rgb(im);
subplot(5,1,[1 2]);image(im);set(gca,'xtick',[],'fontsize',16);
ylabel('trial #');