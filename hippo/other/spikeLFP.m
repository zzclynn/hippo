function [times cellNum currZ histLFP] = spikeLFP(fname,path,spikes)

tic;
chunkSize = 100000;
cMor = getMor(9,1,1250,5);
figure;plot(real(cMor));
[~,~,nSamples] = LoadBinary([fname '.eeg'],1:64,[],[],[],[],[1 2]);
nSamples = [64 nSamples];
%info = hdf5info([path 'hippo.h5']);
%nSamples = info.GroupHierarchy.Datasets(1).Dims;
if ~exist('spikes','var');
    [times cellNum] = LoadCluRes(fname);
    times = floor(times/16)+1;
else
    times = spikes(:,1);cellNum = spikes(:,2);
end
currZ = [];
toc
range = 10000;
bound{1} = linspace(-range,range,50);
bound{2} = bound{1};
histLFP = zeros(numel(bound{1}));
figure;
for i = 1:ceil(nSamples(2)/chunkSize)
    startInd = chunkSize*(i-1);
    numLen = min(nSamples(2) - startInd -1,chunkSize);
    chunk = LoadBinary([fname '.eeg'],1:64,[],[],[],[],[1 numLen]+startInd);
%     chunk = complex(double(h5varget([path 'hippo.h5'],'/hReal',[0 startInd],[nSamples(1) numLen])),...
%             double(h5varget([path 'hippo.h5'],'/hImag',[0 startInd],[nSamples(1) numLen])));
    chunkMean1 = mean(chunk)';
%     L = numel(chunkMean1);
%     NFFT = 2^nextpow2(L); % Next power of 2 from length of y
%     f = 1250/2*linspace(0,1,NFFT/2+1);
%     Y = abs(fft(chunkMean1,NFFT))/L;
%     plot(f,2*Y(1:NFFT/2+1));return
    chunkMean = conv(chunkMean1,cMor,'same');
    histLFP = histLFP + hist3([real(chunkMean),imag(chunkMean)],bound);
    theseTimes = times - startInd;
    theseTimes = theseTimes(theseTimes > 0 & theseTimes <= numLen);
    currZ = [currZ; chunkMean(theseTimes)];
    if mod(i,10) == 0
        i
        plot(real(chunkMean(1:5000)));hold on;plot(imag(chunkMean(1:5000)),'r');
        plot(chunkMean1(1:5000)*10,'k');hold off;
        drawnow;
    end
end
size(currZ)
toc