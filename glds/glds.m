%
% function net=lds(X,K,cyc,tol);
% 
% Adaptive Linear Dynamical System 
%
% X - N x p data matrix
% K - size of state space (default 2)
% T - length of each sequence (N must evenly divide by T, default T=N)
% cyc - maximum number of cycles of EM (default 100)
% tol - termination tolerance (prop change in likelihood) (default 0.0001)
%
% net is a structure consisting of:
%
% A - state transition matrix
% C - observation (output) matrix 
% Q - state noise covariance 
% R - observation noise covariance
% x0 - initial state mean
% P0 - initial state covariance
% Mu - output mean
% LL - log likelihood curve
%
% Iterates until a proportional change < tol in the log likelihood 
% or cyc steps of EM

function [net net0]=glds(X,K,cyc,tol)

% net is  [A,C,Q,R,x0,P0,Mu,LL,LM]
xform = 1;
%net=struct('type','lds','A',[],'C',[],'Q',[],'R',[],'x0',[],'P0',[],'Mu',[],'LL',[],'LM',[]);
if size(X,1) < size(X,2) X = X.'; end
[T,p] = size(X);

if nargin<4   tol=0.0001; end;
if nargin<3   cyc=100; end;
if nargin<2   K=2; end;

Mu=mean(X);
X=bsxfun(@minus,X,Mu);

%  if (K<=p) 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % initialize with Factor Analysis
    
    fprintf('\nInitializing with Factor Analysis...\n');
    [L,Ph,LM]=ffa(X,K,100,0.001);
    C=L;
    R=Ph;
    Phi=diag(1./R);
    temp1=Phi*L;
    temp2=Phi-temp1/(eye(K)+L'*temp1)*temp1';
    temp1=X*temp2*L;
    x0=mean(temp1)';
    Q=cov(temp1);
    P0=Q;
    t1=temp1(1:T-1,:);
    t2=temp1(2:T,:);
    
    A=(t1'*t1+Q)\t1'*t2;
    clear temp1 temp2 Phi t1 t2;
    fprintf('FA log likelihood %f\nInitialized.\n',LM(end));
    if xform
        [V,D] = eig(Q);
        Q = eye(size(Q,1));
        C = C*(V*sqrt(D));
        A = (sqrt(D)\V')*A*(V*sqrt(D));
    end
net0.A = A;net0.R = diag(R);net0.C = C;net0.Q = Q;net0.x0 = x0;net0.P0 = P0;
[C, R, A, Q, ~,~, x0, V0, loglik,xsmooth] = kalmanMLE(X,C,diag(R),A,Q,x0,P0,0,0);
if xform
[V,D] = eig(Q);
Q = eye(size(Q,1));
C = C*(V*sqrt(D));
A = (sqrt(D)\V')*A*(V*sqrt(D));
end
net.C = C;net.R = R; net.A = A; net.Q = Q; net.x0 = x0; net.P0 = V0; net.loglik = loglik;net.xsmooth = xsmooth;