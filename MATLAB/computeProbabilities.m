% Computes the probability of dependence using the input p-values.
% NOTE: Requires a reasonably sized number of p-values for accurate
% computation. See "Learning Neighborhoods of High Confidence in
% Constraint-Based Causal Discovery" by Triantafillou for more details
% about the method.
function [probabilities] = computeProbabilities(pvalues)
t = sqrt(realmin);
pvalues(pvalues <= t) = t;
pvalues(pvalues >= 1-eps/2) = 1-eps/2;

%compute the MAP-ratio for every pair of nodes
[~, ~, pi0hat] = mafdr(pvalues, 'method', 'bootstrap');
ahat = fminbnd(@(a) negLL(a, pvalues, pi0hat), 0, 1);
mr = MAPratio(pvalues,ahat,1,pi0hat);
probabilities = 1 - mr ./ (mr + 1);
end

function MAPratio = MAPratio(p, a, b, p0)
% Returns the likelihood ratio p(Ho|p)/p(H1|p) when the p-values follow the Beta(alpha, beta)
% distribution with alpha, beta =1 for H0

MAPratio = betaLikelihoodRatio(p, a, b)*(p0/(1-p0));
end

function betaLikelihoodRatio = betaLikelihoodRatio(p, a, b)
% Returns the likelihood ratio p(p|Ho)/p(p|H1) when the p-values follow the Beta(a,b)
% distribution with alpha, beta =1 for H0

num = 1;
denom = (1/(beta(a,b))).*(p.^(a-1).*(1-p).^(b-1));
betaLikelihoodRatio = num./denom;
end

function [negLL , dnegLL] = negLL(a, pvalues, pi0)
nlls = log(pi0+(1-pi0)*a*pvalues.^(a-1));

negLL = -sum(nlls);
denom = pi0+(1-pi0)*a*pvalues.^(a-1);
num = (pi0-1)*pvalues.^(a-1)+ a*(pi0-1)*pvalues.^(a-1).*log(pvalues);
dnegLL =sum((num)./(denom));
end