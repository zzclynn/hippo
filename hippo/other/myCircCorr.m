function [rho] = myCircCorr(alpha1, alpha2)
%
% [rho pval ts] = circ_corrcc(alpha1, alpha2)
%   Circular correlation coefficient for two circular random variables.
%
%   Input:
%     alpha1	sample of angles in radians
%     alpha2	sample of angles in radians
%
%   Output:
%     rho     correlation coefficient
%
% References:
%   Topics in circular statistics, S.R. Jammalamadaka et al., p. 176
%
% PHB 6/7/2008
%
% Circular Statistics Toolbox for Matlab

if size(alpha1,2) < size(alpha1,1)
	alpha1 = alpha1';
end

if size(alpha2,2) < size(alpha2,1)
	alpha2 = alpha2';
end

% compute mean directions
%n = length(alpha1);
alpha1_bar = circ_mean(alpha1);
alpha2_bar = circ_mean(alpha2);
alpha1 = bsxfun(@minus,alpha1,alpha1_bar);
alpha2 = bsxfun(@minus,alpha2,alpha2_bar);
alpha1 = sin(alpha1)';
alpha2 = sin(alpha2);
num = sum(bsxfun(@times,alpha1,alpha2));
den = sqrt(bsxfun(@times,sum(alpha1.^2),sum(alpha2.^2)));
rho = num ./ den;
% 
% % compute correlation coeffcient from p. 176
% num = sum(sin(alpha1) .* sin(alpha2));
% den = sqrt(sum(sin(alpha1).^2) .* sum(sin(alpha2).^2));
% rho = num / den;