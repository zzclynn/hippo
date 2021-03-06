function clips = trackMouse(obj,lr)

file = ['/media/work/hippocampus/' obj '/' obj '.mpg'];
temp = mmread(file,0);

% if ischar(obj)
%     obj = VideoReader(['/media/work/hippocampus/' obj '/' obj '.mpg']);
% end

intThresh = 4;
areaThresh = 100;
rad = 10;
nFrames = 100;
totalFrames = abs(temp.nrFramesTotal);
spacing = 100;% floor(totalFrames/nFrames); 

if ~exist('lr','var')
    a = 0;
    for i = 1:1000:totalFrames
        a = max(a,getIm(file,i));%read(obj,i));
    end
    a = max(a,[],3);
    figure;plot(max(a));
    lr(1) = input('input left point');
    lr(2) = input('input right point');
end
clips = zeros(nFrames,2*rad+1,rad*2+1,3);
counter = 1;
for i= 1000:spacing:totalFrames
    a = getIm(file,i,1);%read(obj,i);
    a = double(a(:,lr(1):lr(2),:));
    a = imfilter(a,fspecial('gaussian',5,2));
    ma = squeeze(mean(double(a),3));
    thrIm = ma > intThresh;
    thrIm = bwmorph(thrIm,'open');
    stats = regionprops(thrIm,ma,'Area','WeightedCentroid');
    stats([stats.Area] < areaThresh) = [];
    for j = 1:numel(stats)
        ctr = round(stats(j).WeightedCentroid);
        clips(counter,:,:,:) = a(ctr(2)+(-rad:rad),ctr(1)+(-rad:rad),:);
        counter = counter + 1;
        if counter > nFrames
            break
        end
        imagesc(a(ctr(2)+(-rad:rad),ctr(1)+(-rad:rad),:)/255);drawnow;pause(.1);
    end
    if counter > nFrames
        break
    end
end
clips = clips(:,:);
[a b proj] = svds(clips,2);proj = b*proj';
gm = gmdistribution.fit(a,2);
k = cluster(gm,a);
output(:,1) = mean(clips,2).*(2*(k == 1)-1);
ridge = eye(size(clips,2))*100000;
filts = (clips'*clips+ridge)\(clips'*output);
figure;
for i = 1:2
    filtsa(:,i) = ((-1)^i)*filts;
    filtsa(:,i) = filtsa(:,i)/max(filtsa(:,i));
     subplot(2,1,i);imagesc(max(0,reshape(filtsa(:,i),2*rad+1,2*rad+1,3)));
end
% 
% figure;hold all;
% temp = clips*filts;
% for j = 1:size(output,2)
%     scatter(temp(:,j),output(:,j));
tempIm = reshape(filts,2*rad+1,2*rad+1,3);%(j,:,:,:)
% end
figure;
for i= 1000:1:totalFrames
    a = double(getIm(file,i,0))/255;%read(obj,i))/255;
    a = a(:,lr(1):lr(2),:);
%    subplot(211);
    image(a.^.5);
    temp = zeros(size(a,1),size(a,2));% myIm(:) = 0;
    for k = 1:3
        temp = temp + imfilter(a(:,:,k),squeeze(tempIm(:,:,k)),'same');
    end
%     myIm(:,:,1) = temp;myIm(:,:,2) = -temp;myIm(:,:,3) = 0;
%     myIm = max(0,myIm);
%     myIm = myIm/max(myIm(:));
%     subplot(2,1,2);imagesc(max(myIm,0));
    [r c] = find(temp == max(temp(:)));
    hold on;scatter(c,r,'r','filled');
    [r c] = find(temp == min(temp(:)));
    hold on;scatter(c,r,'g','filled');
    drawnow
end
% figure;
% areaThresh = 30;
% for i= 1:10:obj.NumberOfFrames
%     a = double(read(obj,i));
%     a = a(:,lr(1):lr(2),:);
%     a = imfilter(a,fspecial('gaussian',5,2));
%     ma = squeeze(mean(a,3));
%     thrIm = ma > intThresh;
%     thrIm = bwmorph(thrIm,'open');
%     stats = regionprops(thrIm,ma,'Area','WeightedCentroid');
%     stats([stats.Area] < areaThresh) = [];
%     [~,ind] = sort([stats.Area],'descend');
%     imagesc((a/255).^.5);hold all;
%     for j = 1:min(2,numel(stats))
%         ctr = round(stats(ind(j)).WeightedCentroid);
%         temp = a(ctr(2)+(-rad:rad),ctr(1)+(-rad:rad),:);
%         if cluster(gm,((proj*proj')\proj*temp(:))') == 1
%             scatter(ctr(1),ctr(2),'r','filled');
%         else
%             scatter(ctr(1),ctr(2),'g','filled');
%         end
%         %a(ctr(2)+(-rad:rad),ctr(1)+(-rad:rad),:) = 255;
% %        clips(counter,:,:,:) = a(ctr(2)+(-rad:rad),ctr(1)+(-rad:rad),:);
%     end
%     hold off;drawnow;pause(.2);
% end
% return
% for i= 1:1000:obj.NumberOfFrames
%     a = double(read(obj,i))/255;
%     a = a(:,lr(1):lr(2),:);
%     subplot(211);image(a);
%     %im1 = squeeze(mean(imfilter(a,squeeze(tempIm(1,:,:,:)),'same'),3));
%     %im2 = squeeze(mean(imfilter(a,squeeze(tempIm(2,:,:,:)),'same'),3));
%     %subplot(312);imagesc(im1./im2);
%     myIm = a; myIm(:) = 0;
%      for j = 1:2
%          temp = zeros(size(a,1),size(a,2));
%          for k = 1:3
%              myIm(:,:,j) = myIm(:,:,j) + imfilter(a(:,:,k),squeeze(tempIm(j,:,:,k)),'same');
%          end
%          myIm(:,:,j) = myIm(:,:,j)/max(max(squeeze(myIm(:,:,j))));
%          %mean(imfilter(a,squeeze(tempIm(j,:,:,:)),'same'),3));%temp);%
%      end
%      subplot(2,1,2);imagesc(max(myIm,0));
%     drawnow
% end
% return
% %k = kmeans(a,2);
% figure;hold all;
% for i = 1:2
%     scatter(a(k == i,1),a(k == i,2));
% end

function im = getIm(file,frame,seek) 
if ~exist('seek','var')
    seek = 1;
end
tic;
im = mmread(file,frame,[],0,1,'',seek,0);
im = im.frames.cdata;
toc