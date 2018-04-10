function writeASPConstraintsToFile(datasets, nvars, file)

    % Format: dataset; var1:has_been_selected, var2:has_been_selected, ..., varn:has_been_selected; var1:is_manipulated, var2:is_manipulated, ..., varn:is_manipulated;
    function addDataset(fid, selected, manipulated, error)
        s = ['dataset; ' sprintf('%d:%s,',selected{:})];
        s(end) = [];
        fprintf(fid, '%s;', s);
        s = [' ' sprintf('%d:%s,',manipulated{:})];
        s(end) = [];
        fprintf(fid, '%s;', s);
        s = [' ' sprintf('%d:%s,',error{:})];
        s(end) = [];
        fprintf(fid, '%s\n', s);
    end

    function addConstraint(fid, type, x, y, z, dataset)
        z = sprintf('%d,',z);
        z(end) = [];
        fprintf(fid, 'constraint;%s;%d;%d;%s;%d\n', type, x, y, z, dataset);
    end

    function addOutput(fid, output)
        fprintf(fid, 'output; %s\n',output);
    end

fid = fopen(file,'w+');
fprintf(fid, 'nodes; %d\n', nvars);
fprintf(fid, 'allowlatent; %s\n', 'true');
fprintf(fid, 'allowselection; %s\n', 'false');
fprintf(fid, 'allowmanipulations; %s\n', 'false');
nconstraints = 0;
for i = 1:length(datasets)
    nconstraints = nconstraints + size(datasets{i}.constraints,1);
end

fprintf(fid, 'constraints; %d\n', nconstraints);

for i = 1:length(datasets)
    addDataset(fid, datasets{i}.selected, datasets{i}.manipulated, {});
end

% Dependence and independence constraints
for i = 1:length(datasets)
    curdataset = datasets{i};
    for j = 1:size(curdataset.constraints,1)
        addConstraint(fid, curdataset.constraints{j,1}, curdataset.constraints{j,2}, curdataset.constraints{j,3}, curdataset.constraints{j,4}, i);
    end
end

% Which inferences should be written to the result file.
addOutput(fid, 'arrow');
addOutput(fid, 'notarrow');
addOutput(fid, 'connected');
addOutput(fid, 'notconnected');
addOutput(fid, 'latent');
addOutput(fid, 'notlatent');
addOutput(fid, 'ancestor');
addOutput(fid, 'notancestor');

fclose(fid);

end