#program init(n,m).

% Define n nodes and m datasets
nodes(n).
datasets(m).
dataset(X) :- datasets(M), X = 1..M.
node(X) :- nodes(N), X = 1..N.

% Define the presence/absence of an arrow (directed edge) 
{ arrow(X,Y) } :- node(X), node(Y), X != Y.
:- arrow(X,Y), arrow(Y,X).
notarrow(X,Y) :- not arrow(X,Y), node(X), node(Y), X != Y.

% Define the presence/absence of an ancestral relation
ancestor(X,Y) :- arrow(X,Y).
ancestor(X,Y) :- ancestor(X,W), ancestor(W,Y), X != Y.
:- ancestor(X,Y), arrow(Y,X).
notancestor(X,Y) :- not ancestor(X,Y), node(X), node(Y), X != Y.

% Define the presence/absence of a direct connection (i.e., X and Y are connected if X->Y or X<-Y)
connected(X,Y) :- arrow(X,Y).
connected(X,Y) :- connected(Y,X).
notconnected(X,Y) :- not connected(X,Y), node(X), node(Y), X != Y.

% Output all inferences. Comment out the ones that are not of interest.
% If the Lua script is used, the ones that should be output have to be specified separately.
#show arrow/2.
#show notarrow/2.
#show connected/2.
#show notconnected/2.
#show latent/2.
#show notlatent/2.
#show ancestor/2.
#show notancestor/2.
#show selected/2.
#show notselected/2.
#show manipulated/2.
#show notmanipulated/2.

% Used only if the presence of latent confounders is possible. 
% If latent variables are allowed, then a connection between two variables may also be due to a latent confounder.
#program fun_latent.
{ latent(X,Y) } :- node(X), node(Y), X < Y.
latent(Y,X) :- latent(X,Y).
notlatent(X,Y) :- not latent(X,Y), node(X), node(Y), X < Y.
connected(X,Y) :- latent(X,Y).

% Used only if selection bias is possible in dataset d (see the paper for the types of selection bias currently handled).
#program fun_selected(d).
{ selected(X,d) } :- node(X), dataset(d).
notselected(X,d) :- not selected(X,d), node(X), dataset(d).

% Used only if hard manipulations are possible in dataset d.
#program fun_manipulated(d).
{ manipulated(X,d) } :- node(X), dataset(d).
notmanipulated(X,d) :- not manipulated(X,d), node(X), dataset(d).

%%% External Grounding
%%% Those functions are used by the Lua script to add specific constraints.
%%% Currently, the functions for adding structural prior knowledge are not supported by the Lua script.

% Used for incremental grounding of d-connection / d-separation constraints. 
% z corresponds to a specific conditioning set, while d to a specific dataset. 
% Grounding is only performed if a <z,d> combination is used.
#program fun_context(z,d).
#external context(z,d).
dconn(X,Y,context(z,d)) :- not inside_set(X,z), not inside_set(Y,z), into(X,Y,context(z,d)), X < Y.
dconn(X,Y,context(z,d)) :- not inside_set(X,z), not inside_set(Y,z), outof(X,Y,context(z,d)), X < Y.

% Basic Bayes-Ball algorithm without latent variables or selection bias.
outof(X,X,context(z,d)) :- not inside_set(X,z), node(X), context(z,d).
into(X,W,context(z,d)) :- outof(X,Y,context(z,d)), not inside_set(Y,z), arrow(Y,W), not manipulated(W,d).
outof(X,W,context(z,d)) :- outof(X,Y,context(z,d)), not inside_set(Y,z), arrow(W,Y), not manipulated(Y,d).
outof(X,W,context(z,d)) :- into(X,Y,context(z,d)), inside_set(Y,z), arrow(W,Y), not manipulated(Y,d).
into(X,W,context(z,d)) :- into(X,Y,context(z,d)), not inside_set(Y,z), arrow(Y,W), not manipulated(W,d).

% Bayes-Ball with latent variables.
into(X,W,context(z,d)) :- outof(X,Y,context(z,d)), not inside_set(Y,z), latent(Y,W), not manipulated(Y,d), not manipulated(W,d).
into(X,W,context(z,d)) :- into(X,Y,context(z,d)), inside_set(Y,z), latent(Y,W), not manipulated(Y,d), not manipulated(W,d).

% Bayes-Ball with selection bias.
outof(X,W,context(z,d)) :- outof(X,Y,context(z,d)), not inside_set(Y,z), selected(Y,d), selected(W,d).
outof(X,W,context(z,d)) :- into(X,Y,context(z,d)), not inside_set(Y,z), selected(Y,d), selected(W,d).

% Specifies that x is in the set z.
#program fun_inside(x,z).
inside_set(x,z).

% Adds a specific d-connection constraint DCONN(x,y|z;d) (x d-connected with y given z in dataset d)
#program fun_dep(x,y,z,d).
#external dep(x,y,z,d).
:- dep(x,y,z,d), not dconn(x,y,context(z,d)).

% Adds a specific d-separation constraint DSEP(x,y|z;d) (x d-separated with y given z in dataset d)
#program fun_indep(x,y,z,d).
#external indep(x,y,z,d).
:- indep(x,y,z,d), dconn(x,y,context(z,d)).

% Adds a constraint about the presence of a spurious association due to selection bias between x and y in dataset d.
#program in_selected(x,d).
:- not selected(x,d).

% Adds a constraint about the absence of a spurious association due to selection bias between x and y in dataset d.
#program in_notselected(x,d).
:- selected(x,d).

% Adds a constraint about the presence of a hard manipulation of x in dataset d.
#program in_manipulated(x,d).
:- not manipulated(x,d).

% Adds a constraint about the absence of a hard manipulation of x in dataset d.
#program in_notmanipulated(x,d).
:- manipulated(x,d).

%%% Rules for adding different types of structural prior knowledge. Currently not supported by the Lua script.

% Adds a constraint about the presence of the arrow x->y
#program in_arrow(x,y).
:- not arrow(x,y).

% Adds a constraint about the absence of the arrow x->y
#program in_notarrow(x,y).
:- arrow(x,y).

% Adds a constraint about the presence of a latent confounder between x and y
#program in_latent(x,y).
:- not latent(x,y).

% Adds a constraint about the absence of a latent confounder between x and y
#program in_notlatent(x,y).
:- latent(x,y).

% Adds a constraint about the presence of a direct connection between x and y
#program in_connected(x,y).
:- not connected(x,y).

% Adds a constraint about the absence of a direct connection between x and y
#program in_notconnected(x,y).
:- connected(x,y).

% Adds a constraint about the presence of a causal path from x to y.
#program in_ancestor(x,y).
:- not ancestor(x,y).

% Adds a constraint about the absence of a causal path from x to y.
#program in_notancestor(x,y).
:- ancestor(x,y).

% Adds a constraint that variable x is a root node (i.e., has no incoming edges and is not confounded).
#program in_rootnode(x).
:- arrow(Y,x), node(Y).
:- latent(Y,x), node(Y).

% Adds a constraint that variable x is a leaf node (i.e., has no outgoing edges).
#program in_leafnode(x).
:- arrow(x,Y), node(Y).

% Adds a constraint about the maximum in-degree k of variable x.
#program in_indegree(x,k).
{arrow(Y,x) : node(Y); latent(Y,x) : node(Y)} <= k.

% Adds a constraint about the maximum out-degree k of variable x.
#program in_outdegree(x,k).
{arrow(x,Y) : node(Y)} <= k.