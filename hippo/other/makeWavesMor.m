function ts = makeWavesMor(m,dims)
if dims == 64
    dims = sqrt(dims);
end
w1 = getMor(10,1,1250,3);
t1 = zeros(m.sources,dims(end));
for i = 1:m.sources
    w1 = getMor(5*i,1,1250,3);
    temp = conv(makeComplex(dims(end)*5,.1),w1,'same');
    t1(i,:) = temp((end-dims(end)+1):end);
    %t1(i,:) = exp(-rand)*[exp(1i*(1:dims(end))/3) + exp(1i*(1:dims(end))/3*2)/2];%mod((1:dims(end))+ceil(rand*5),5);
end
mag = rand(m.sources,1) -.5;
mag = sign(mag).* log(1- 2* abs(mag));
t1 = bsxfun(@times,t1,mag);
%sfigure(88);imagesc(abs(t1));colormap gray;drawnow;
ts = m.grid*t1;
ts = ts + randn(size(ts))*std(ts(:))/5;