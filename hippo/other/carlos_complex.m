function [weights signal zpweights] = carlos_complex(X,sources)
tic;
X = reshape(X,[size(X,1)*size(X,2) size(X,3)]);
X = X - repmat(mean(X,2),[1 size(X,2)]);
X = X./repmat(std(X,1,2),[1 size(X,2)]);
X = hilbert(X')';


%%[weights sphere] = runica(signal,'maxsteps',50);%,'interupt','on'

[n,T]	= size(X);
if ~exist('sources','var')
    m=20;
else
    m = sources;
end
%%% whitening
if m<n, %assumes white noise
 	[U,D] 	= eig((X*X')/T); 
	[puiss,k]=sort(diag(D));
 	ibl 	= sqrt(puiss(n-m+1:n)-mean(puiss(1:n-m)));
 	bl 	= ones(m,1) ./ ibl ;
 	W	= diag(bl)*U(1:n,k(n-m+1:n))';
 	IW 	= U(1:n,k(n-m+1:n))*diag(ibl);
    ZP = U(1:n,k(n-m+1:n))*diag(bl)*U(1:n,k(n-m+1:n))';
else    %assumes no noise
 	IW 	= sqrtm((X*X')/T);
 	W	= inv(IW);
    ZP = eye(m);
end;
X	= W*X;
%fast!
[weights signal] = jade_complex(X,m);%
%also slow but converges, noncirc VERY slow
%[weights signal] = ACMNsym(X,'mle_circ');

%also slow; none converge; does converge on whitened?
%[weights signal] = nonCircComplexFastICAsym(X,'sqrt');

%%medium speed; doesnt converge;
%[weights signal] = fast_complex(X);

%%ICA_EBM - slow and doesnt converge
%[weights shat signal] = complex_ICA_EBM(X);

%%%estimation of the mixing matrix and signal separation
signal = weights'*signal;
weights = IW*weights;
zpweights = ZP*weights;
toc