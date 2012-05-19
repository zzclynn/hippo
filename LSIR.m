function [S, vopts] = LSIR(X, Y, d, s)

% Input: 
% X: p X n input data matrix
% Y: response variable
% d: number of LSIR directions
% s: regularization parameter
% opts: structrue containing parameters
%       [H]: number of slices, defalt: 10 for 'r'
%       [numNN]: number of nearest neighbors
% Output:
% S:   a structure containing
%      [edrs] : edr directions
%      [Xmean]: mean of the samples
%      [Xv]: centered LSIR variates for input data X
%      [Cov]: Covariance matrix of inverse regression
%      [Sigma]: Covariance matrix of X
% vopts: structure of parameters used
% last modified: 9/16/2008 (documentation)

[dim n] = size(X);
if nargin<5
    opts=[];
end

J=zeros(n);
opts.H = 5;
opts.numNN = 50;
[~, YI] = sort(Y);
Hn = round(n/opts.H);
for i = 1:opts.H
    if i<opts.H
        ind = YI((i-1)*Hn+1:i*Hn);
    else
        ind =YI((opts.H-1)*Hn+1:n);
    end
    scatter(X(1,ind),X(2,ind));hold all;
    ni = length(ind);
    numNNi = min(ni, opts.numNN);
    Xi = X(:,ind);
    for j=1:ni
        dist2j = sum((Xi-repmat(Xi(:,j),1,ni)).^2);
        [~, dI] = sort(dist2j);
        J(ind(dI(1:numNNi)),ind(j)) = 1/numNNi;
    end
    scatter(X(1,ind(dI(1:numNNi))),X(2,ind(dI(1:numNNi))),'k','filled');hold all;drawnow;
end

J = J'*J;
Xmean = mean(X, 2);
cX = X - repmat(Xmean, 1, n);
eigopts.issym = true;
eigopts.isreal = true;
eigopts.disp = 0;
Sigma = cX*J*cX';
Sigma = .5*(Sigma + Sigma');
Cov = cX*cX';
Cov = .5*(Cov + Cov');
[B L] = eig(Sigma, Cov + s*eye(dim));
B
L
[~, LI] = sort(diag(L),'descend');
B = B(:,LI(1:d));
for i = 1:d
    B(:,i) = B(:,i)/norm(B(:,i));
    [~, maxi] = max(abs(B(:,i)));
    B(:,i) = B(:,i)*sign(B(maxi,i));
end

S.edrs = B;
S.Xmean = Xmean;
S.Xv = B'*cX;
S.Cov = Cov;
S.Sigma = Sigma;

vopts = opts;
vopts.d = d;
vopts.s = s;
vopts.J = J;