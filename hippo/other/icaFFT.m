function temp = icaFFT(X,dec)

params.Fs = 1250;
if exist('dec','var')
    params.Fs = params.Fs/dec;
end
win = [.5 .1];
params.tapers = [1/win(1) win(1) 1];
%params.fpass = [0 70];
[S,t,f,sa] = mtspecgramc(X,win,params);
ft = exp(-1i*t'*f*(2*pi));
figure;subplot(311);image(t,f,complexIm((sa(2:end,:).*exp(-1i*angle(sa(1:end-1,:)))).',0,.5));
%ft = sa.*ft;
temp = sa.*ft;
ref = 8;comp = ref-1;
subplot(312);image(t,f,complexIm(temp.',0,.5));
ft = exp(-1i*angle(mean(sa(:,5:8),2))*ones(size(f)));%%f./f(ref)
% ft = zeros(size(ft));
% for i = 1:size(ft,2)
%     ft(:,i) = power(exp(-1i*angle(sa(:,ref))),f(i)/f(ref));%
% end
temp = sa.*ft;
% figure;subplot(311);imagesc(hist3(angle(temp(:,[12 13])),[30 30]));
% subplot(312);imagesc(hist3([abs(temp(:,12)) angle(temp(:,12))],[30 30]));
% subplot(313);imagesc(hist3([abs(temp(:,13)) angle(temp(:,13))],[30 30]));return
subplot(313);image(t,1:numel(f),complexIm(temp.',0,.5));hold all;
figure;subplot(211);imagesc(abs(corr(temp)));subplot(212);imagesc(abs(corr(sa)));return
%figure;plot(abs(temp(:,[ref ref+comp]))*10);hold all;plot(real(temp(:,[ref ref+comp]))*10);plot(imag(temp(:,[ref ref+comp]))*10);plot(angle(temp(:,ref+comp)));
h = hist3([abs(temp(:,ref+comp)) angle(temp(:,ref+comp))],[30 30]);
figure;subplot(211);imagesc(h);
h = bsxfun(@rdivide,h,sum(h));
subplot(212);imagesc(h);
figure;imagesc(hist3([abs(temp(:,ref+comp)) abs(temp(:,ref))],[30 30]));
figure;imagesc(sqrt(hist3([real(temp(:,ref+comp)) imag(temp(:,ref+comp))],[30 30])));

% Nwin=round(params.Fs*win(1)); % number of samples in window
% Nstep=round(win(2)*params.Fs); 
% winstart=1:Nstep:numel(X)-Nwin+1;
% nw=length(winstart); 
% ind = zeros(1,nw);
% for n=1:nw
%    indx=winstart(n):winstart(n)+Nwin-1;
%    temp = xcorr(X(indx));
%    [~,ind(n)]=min(temp((numel(temp)-1)/2:end));
%    %scatter(n,ind,'filled');
% end
% figure;plot(ind);return
% scatter(1:nw,ind/30,'filled');

% win = .5;
% fs = 1250;
% base = 8.4;
% scales = 5;
% Fb = 1/500;
% wX = zeros(scales,numel(X));
% for i = 1:scales
%     [wave(i,:) x] =cmorwavf(-win,win,fs/(2*win),Fb,base*i);
%     wX(i,:) = conv(X,wave(i,:),'same');
%    if i > 1
%    wX(i,:) = wX(i,:).*exp(1i*-angle(wX(1,:))*i);
%    end
% end
% %figure;imagesc(hist3([angle(wX(1,:))' angle(wX(2,:))'],[1000 50]));
% wX(1,2:end) = wX(1,2:end).*exp(1i*-angle(wX(1,1:end-1)));
% wX = bsxfun(@rdivide,wX,mean(abs(wX),2));
% params.Fs = fs;params.tapers = [3 5];
% [S,f] = mtspectrumc(real(wave)',params);%[real(wX)' X'],params);
% %figure;plot(f,S);
% figure;image(complexIm(wX,0,1));
% % 
% figure;imagesc(hist3([abs(wX(2,:))' angle(wX(2,:))'],[30 30]));
% figure;imagesc(sqrt(hist3([real(wX(2,:))' imag(wX(2,:))'],[30 30])));
% 
% figure;plot(t,temp(:,ref+8));hold all;plot(linspace(0,size(wX,2)/fs,size(wX,2)),wX(2,:)/5);