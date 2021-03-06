function minVVar(pos,u,s,v)%,sp)
%% find static superposition of 1st 2 activations that reduces the variance of the demodulated activation
v = v*s;
bounds = [.1 .9];
pos(pos == -1) = nan;
sV = size(v,1);
pos = pos(1:sV,:);
for i = 1:2
    pos(:,i) = interp1(find(~isnan(pos(:,i))),pos(~isnan(pos(:,i)),i),1:size(pos,1));
end
nanInds = isnan(pos(:,1));
pos = pos(~nanInds,:);v = v(~nanInds,:);

pos = bsxfun(@minus,pos,mean(pos));
[pos,~,~] = svd(pos(:,1:2),'econ');
pos(:,1) = pos(:,1)-min(pos(:,1));pos(:,1) = pos(:,1)/max(pos(:,1));
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
%v(:,2) = v(:,2).*exp(1i*-angle(v(:,1)));
vals = zeros(20);
range = linspace(-1,1,size(vals,1));
for i = 1:size(vals,1)%range
    for j = 1:size(vals,1)
        alpha = range(i)+1i*range(j);
        vNew = v(:,1) + alpha*v(:,2);
        temp = vNew(1:end-1).*conj(vNew(2:end))./abs(vNew(2:end));
        vals(i,j) = std(temp(b>0));
    end
end
Xf = u*v';Xf = Xf(:,1:end-1);
Xf1 = Xf(:,1:end-1).*conj(Xf(:,2:end))./abs(Xf(:,2:end));
[a b1] = find(vals == min(vals(:)));
val = range(a)+1i*range(b1)
figure;imagesc(range,range,vals);
figure;subplot(311);imagesc(reshape(std(Xf1,0,2)./std(Xf,0,2),[8 8]));
subplot(312);imagesc(reshape(std(Xf1(:,b>0),0,2)./std(Xf(:,b>0),0,2),[8 8]));
subplot(313);imagesc(reshape(abs(u(:,2)./u(:,1) - val),[8 8]));