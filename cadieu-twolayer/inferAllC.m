function [posAccum posAccumC y] = inferAllC(Xf,v,pos,sess,m,p)

if isempty(sess)
    sess = ones(size(v));
end
pos(size(Xf,2)+1:end,:) = [];
for i = 1:2
    posd(:,i) = pos(:,i) - min(pos(:,i)) + eps;
end
posd = ceil(posd);
junk = any(isnan(posd'));
posd(junk,:) = [];
Xf(:,junk) = [];v(junk) = [];sess(junk) = [];
y = zeros(m.N,size(Xf,2));
posAccum = zeros(m.N,max(posd(:,1)),max(posd(:,2)),max(sess));
posAccumC = posAccum;
myInds = meshgrid(1:m.N,1:p.imszt);
for j = 1:max(sess)
    base = find(sess == j,1)-1;
for i = 1:floor(sum(sess == j)/p.imszt)
    inds = base+(i-1)*p.imszt+(1:p.imszt);
    X = crop_chunk(Xf(:,inds),m,p);
    atest1 = infer_Z(X,m,p).';
    posAccum(:,:,:,j) = posAccum(:,:,:,j) + accumarray([myInds(:) repmat(posd(inds,:),[m.N 1])],abs(atest1(:)),[m.N max(posd)],@sum);
    atest1 = bsxfun(@times,atest1,exp(1i*-angle(v(inds))));
    y(:,inds) = atest1.';
    posAccumC(:,:,:,j) = posAccumC(:,:,:,j) + accumarray([myInds(:) repmat(posd(inds,:),[m.N 1])],(atest1(:)),[m.N max(posd)],@sum);
end
end
posAccum = squeeze(posAccum);
posAccumC = squeeze(posAccumC);