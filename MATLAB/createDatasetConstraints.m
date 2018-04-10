% dependence_constraints: computed using 'createDependenceConstraintsFromData'
% selected: array of variables (index in the current dataset) that are
% known to have been selected.
% manipulated: array of variables (index in the current dataset) that are
% known to have been manipulated.
% variableIndexToID: A mapping from the variable indices present in the
% given dataset to an ID. This is necessary to do if multiple datasets with
% overlapping variables are used. In this case, the k-th variable in two
% different datasets may be different and thus a global mapping is
% required.
function dataset = createDatasetConstraints(dependence_constraints, selected, manipulated, variableIndexToID)
nnodes = max(variableIndexToID);
selected = variableIndexToID(selected);
manipulated = variableIndexToID(manipulated);
notselected = setdiff(1:nnodes, selected);
notmanipulated = setdiff(1:nnodes, manipulated);

dataset.constraints = dependence_constraints;
dataset.selected = {};
for i = 1:length(selected)
    dataset.selected{1,end+1} = (selected(i));
    dataset.selected{2,end} = 'true';
end
for i = 1:length(notselected)
    dataset.selected{1,end+1} = (notselected(i));
    dataset.selected{2,end} = 'false';
end

dataset.manipulated = {};
for i = 1:length(manipulated)
    dataset.manipulated{1,end+1} = (manipulated(i));
    dataset.manipulated{2,end} = 'true';
end
for i = 1:length(notmanipulated)
    dataset.manipulated{1,end+1} = (notmanipulated(i));
    dataset.manipulated{2,end} = 'false';
end
end