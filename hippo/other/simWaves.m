function t = simWaves(space,time)

sh = 10;
ang = pi/4;
decay = .9;
t1 = arsim(0,decay,1,time)';
t1 = t1/std(t1);
t2 = real(arsim(0,decay*exp(1i*ang),1,time))';
t2 = t2/std(t2);
%figure;plot(log(abs(fft(t1))));hold all;plot(log(abs(fft(t2))));
t1 = repmat(t1,[space 1]);
t2(2:space,:) = 0;
for i = 2:space
    t2(i,:) = circshift(t2(i-1,:),[0 sh]);
end
%figure;subplot(211);imagesc(t1);subplot(212);imagesc(t2);
t = t1 + t2;
t = t + randn(size(t))*(std(t(:))/2);

f = fft(t,[],2);
fc = f(1,:).*conj(f(2,:));
figure;plot(fftshift(ifft(fc./abs(fc),[],2)));