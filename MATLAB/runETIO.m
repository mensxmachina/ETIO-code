% The runETIO function uses ETIO to infer a pag from a single observational
% dataset. It is a wrapper function that uses the lua script to learn a pag
% incrementally using ETIO. Alternatively, the constraints can be written
% directly in ASP format and clingo can be called using those constraints
% and the main ETIO program (causal_discovery.lp).
% 
% It:
% - takes as input a dataset 'data'
% - performs all independence tests using the function 'indtest' up to a 
% maximum conditioning size of 'maxcond',
% - ranks the constraints by computing the probability of dependence or
% independence of each constraints
% - writes them to a file using a specific format,
% - calls the lua script which uses clingo to make inferences
% - loads the results and converts them to a pag
%
% Input
% data: a MxN matrix, with columns corresponding to features
% maxcond: the maximum conditioning size to consider.
% indtest: a function of the form [pvalue,stat,df] = TEST(x, y, cs, data),
% which performs a test that x and y are conditionally independent given cs
% using the dataset 'data'.
% constraintfile: the name of a temporary file where constraints are
% written to.
% resultfile: the name of a temporary file where the inferences are written
% to.
%
% Output
% A pag, containing a graph (pag.G) with 0/1/2/3 entries, where a 0 
% corresponds to no edge, a 1 corresponds to a circle endpoint, a 2 to an 
% arrowhead endpoint and a 3 to a tail endpoint. For example, Xo->Y would 
% contain the entries pag.G(X,Y) = 2 and pag.G(Y,X) = 1.
% The pag contains a field 'sepSet', which is a logical matrix indicating
% which set separates two variables. For instance, if X and Y are separated
% given Z, then pag.sepSet(X,Y,Z) would equal 1, while all remaining
% entries in pavg.sepSet(X,Y,_) would be 0.
% 
% NOTE: This wrapper only uses a single, observational dataset to infer a
% pag without selection / manipulated variables. The ASP and lua code do 
% support multiple datasets, selection bias and hard manipulations.
% Furthermore, the ASP code also support several types of structural prior
% knowledge.
function pag = runETIO(data, maxcond, indtest, constraintfile, resultfile)

pathtoclingo = which('clingo.exe');
if(isempty(pathtoclingo))
    error('clingo.exe not in MATLAB path');
end

pathtoasp = which('ETIO.lp');
if(isempty(pathtoasp))
    error('ETIO.lp not in MATLAB path');
end

pathtolua = which('ETIO-lua-incremental.lp');
if(isempty(pathtolua))
    error('ETIO-lua-incremental not in MATLAB path');
end

nvars = size(data,2);
dependence_threshold = 0.5; % Dependence/Independence threshold
cutoff_threshold = 0; % Cutting off probabilities less than this threshold

[dependence_constraints, ~] = createDependenceConstraintsFromData(data, maxcond, dependence_threshold, cutoff_threshold, indtest);
dataset_constraints = createDatasetConstraints(dependence_constraints,[],[],1:nvars);
writeASPConstraintsToFile({dataset_constraints},nvars,constraintfile);

% Call the lua script to perform inferences incrementally.
command = [pathtoclingo ' ' pathtoasp ' ' pathtolua ' --outf=1 --quiet=2 --verbose=0 -c input=' constraintfile ' -c output=' resultfile];
system(command);

% Create output pag. Note that, in case other results are available (e.g.
% ancestral relations) those will not be present in the pag.
pag = loadASPResultsAsPag(resultfile, nvars);
end 