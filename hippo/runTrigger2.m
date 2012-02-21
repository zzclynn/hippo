function runTrigger2(pos,v,thresh,back)

vel = angVel(pos);
vel = filtLow(vel(:,1),1250/32,2);
vel(isnan(vel)) = 0;
plot(vel);hold all;
vel = toeplitz(vel,nan*ones(back,1));
x = find(vel(:,1) > thresh & ~any(vel(:,2:end)' > thresh)');
%plot(vel(:,1));hold all;scatter(x,vel(x,1),'r');
vel = vel(:,1);
vAll = zeros(numel(x),2*back+1,2);
velAll = zeros(numel(x),2*back+1);
for i = 1:numel(x)
    vAll(i,:,:) = v(x(i)+(-back:back),:);
    velAll(i,:) = vel(x(i)+(-back:back));
end
figure;imagesc(velAll);
v1 = (vAll(:,:,1).*conj(vAll(:,:,1))./abs(vAll(:,:,1)));
v11 = (vAll(:,2:end,1).*conj(vAll(:,1:end-1,1))./abs(vAll(:,1:end-1,1)));
v12 = (vAll(:,:,2).*conj(vAll(:,:,1))./abs(vAll(:,:,1)));
figure;imagesc(v1);
figure;plot(mean(velAll));
figure;plot(mean(v1));hold all;plot(imag(mean(v11)));plot(real(mean(v11)));
plot(imag(mean(v12)));plot(real(mean(v12)));
%
%figure;imagesc(vel(x+floor(back/2),:));
%figure;plot(mean(vel(x+floor(back/2),:)));