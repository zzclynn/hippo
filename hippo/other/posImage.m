function m = posImage(eeg,eegInd,skip,shanks) %pos

hil = 0;

eeg = eeg(:,eegInd(1):skip:eegInd(end));

minMax = [-1000 1000];
make3d = 0;
eeg = circshift(eeg,[-1 0]);
eeg(64,:) = eeg(62,:);
l = shanks(1); w = shanks(2);
eegRef = 1250;
posRef = 39.06;
%figure;plot(eeg([1 10 65 75],:)');

if hil
    minMax = 3*[-pi pi];%[0 2*pi];
    %colormap hsv;
    eegNew = angle(hilbert(eeg'))';
    eeg(1:64,:) = eegNew(65:end,:);
    for i = 1:size(eeg,2)
        eeg(1:64,i) = eeg(1:64,i) - eeg(28,i);
    %    eeg(65:128,i) = eeg(65:end,i) - eeg(65,i);
    end
    eeg(eeg < -pi) = eeg(eeg < -pi) + 2*pi;
    eeg(eeg > pi) = eeg(eeg > pi) - 2*pi;
    eeg(1:64,:) = eeg(1:64,:)*4;%/100;
    eeg(65:128,:) = eeg(65:128,:)/100;%*4;
    figure;plot(eeg([1 10 65 75],:)');figure;%
end
%eeg = abs(hilbert(eeg'))';
%plot(mean(abs(diff(eeg(1:63,:)))));figure;

c = colormap;

if make3d
[x y] = meshgrid(1:w,1:l);
end
%xlims = [min(makeflat(pos(pos(:,[1]) > -1,[1 3]))) max(makeflat(pos(:,[1 3])))];
%ylims = [min(makeflat(pos(pos(:,[2]) > -1,[2 4]))) max(makeflat(pos(:,[2 4])))];
%pos(:,[1 3]) = (pos(:,[1 3]) - xlims(1))/(xlims(2)-xlims(1));
%pos(:,[2 4]) = (pos(:,[2 4]) - ylims(1))/(ylims(2)-ylims(1));
%pos(pos < 0) = .5;

%figure;plot(pos(ceil(eegInd*posRef/eegRef),1));hold on;plot(pos(ceil(eegInd*posRef/eegRef),2),'r');
tic;
for i = 1:size(eeg,2)
    temp = reshape(eeg(:,i),l,w);
    if ~make3d
        %subplot(3,1,1);imagesc(log(fftshift(abs(fft2(temp)))));axis off;
        %subplot(3,1,2);imagesc(fftshift(angle(fft2(temp))));axis off;
        %subplot(3,1,3);
        imagesc(temp,minMax);axis off;
        %imagesc(temp,minMax);hold on;
    else
        surfc(x,y,temp);
    end
set(gca,'Zlim',minMax);
%ind = ceil(eegInd(i)*posRef/eegRef);
%scatter(pos(ind,1)*w,pos(ind,2)*l,'filled','k');
%annotation('arrow',[pos(ind,3) pos(ind,1)],[pos(ind,4) pos(ind,2)],'LineWidth',5);
%hold off;axis image;
drawnow;
%m((i-1)/skip + 1) = im2frame(imresize(reNorm(temp,minMax,64),10),c);
end
toc

function im = reNorm(im,bounds,slots)
    im = im - bounds(1);
    im = im/(bounds(2)-bounds(1));
    im = max(min(.999,im),0);
    im = floor(im*slots) + 1;