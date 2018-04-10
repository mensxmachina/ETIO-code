function [constraints, probs] = createDependenceConstraintsFromData(data, maxcond, dependence_threshold, cutoff_threshold, indtest)

nvars = size(data,2);

constraints = cell(0,4);
pvalues = zeros(0,1);
df = zeros(0,1);

for i = 1:nvars
    for j = i+1:nvars
        [pvalues(end+1),~,df(end+1)] = indtest(i,j,[], data);
        constraints = [constraints; {'',i,j,[]}];
        
        remaining = setdiff(1:nvars, [i j]);
        for k = 1:maxcond
            subsets = nchoosek(remaining, k);
            for s = 1:size(subsets,1)
                [pvalues(end+1),~,df(end+1)] = indtest(i,j,subsets(s,:), data);
                constraints = [constraints; {'',i,j,subsets(s,:)}];
            end
        end
    end
end

rng(0)

% Rank dependence and independence constraints using the MAP method by
% Triantafillou
probs = computeProbabilities(pvalues);
[~,idx] = sortrows([-max(probs',1-probs'), df']);
probs = probs(idx);
constraints = constraints(idx,:);

remove = [];
for i = 1:length(probs)
    if(probs(i) > dependence_threshold) % Dependent
        if(probs(i) > cutoff_threshold) % Keep
            constraints{i,1} = 'dep';
        else % Cut off
            remove(end+1) = i;
        end
    else %Independent
        if(1-probs(i) > cutoff_threshold) % Keep
            constraints{i,1} = 'indep';
        else  % Cut off
            remove(end+1) = i;
        end
    end
end
constraints(remove,:) = [];
probs(remove) = [];

end