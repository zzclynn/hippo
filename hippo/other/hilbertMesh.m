function hilbertMesh(X,dims)

%makes mesh of electrode array and plots each electrode in hilbert space

X = hilbert(X')';

% image array
%imsz=10;
%im=zeros(imsz);
%[imx imy]=meshgrid(1:dims(1),1:dims(2)); % coordinates in image

range = max(abs(X(:)))/10;

figure;
while 1
    for i = 1:size(X,2)
        temp = reshape(squeeze(X(:,i)),dims);
        %mux=reshape((abs(W)'*imx(:))./sum(abs(W))',SZ,SZ);
        %muy=reshape((abs(W)'*imy(:))./sum(abs(W))',SZ,SZ);
        mux = real(temp);
        muy = imag(temp);
        plot(mux,muy,'k'), hold on
        plot(mux',muy','k'), hold off
        axis([-range range -range range]);
        %axis ij, axis([1 SZ 1 SZ])
        drawnow
    end
end