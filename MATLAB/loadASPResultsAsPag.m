% file: File containing the output of the Lua script
% nvars: number of variables in the graph
% IDToVariableIndex: a mapping from variable IDs
function graph = loadASPResultsAsPag(file, nvars)

fid = fopen(file,'r');
results = textscan(fid, '%s %d %d %d');
fclose(fid);

connected = zeros(nvars, nvars);
arrow = zeros(nvars, nvars);
latent = zeros(nvars, nvars);
graph = zeros(nvars, nvars) - 1;

for i = 1:size(results{1},1)
    if(strcmp(results{1}{i}, 'connected'))
        connected(results{2}(i), results{3}(i)) = 2 * results{4}(i) - 1;
        connected(results{3}(i), results{2}(i)) = 2 * results{4}(i) - 1;
    end
    if(strcmp(results{1}{i}, 'latent'))
        latent(results{2}(i), results{3}(i)) = 2 * results{4}(i) - 1;
        latent(results{3}(i), results{2}(i)) = 2 * results{4}(i) - 1;
    end
    if(strcmp(results{1}{i}, 'arrow'))
        arrow(results{2}(i), results{3}(i)) = 2 * results{4}(i) - 1;
    end
end

for i = 1:nvars
    for j = 1:nvars
        if(i == j)
            graph(i,j) = 0;
            graph(j,i) = 0;
            continue;
        end
        
        % No direct connection (i.e., conditional independence)
        if(connected(i,j) == -1)
            graph(i,j) = 0;
            graph(j,i) = 0;
            continue;
        end
        
        % Otherwise, variables are connected
        graph(i,j) = 1;
        graph(j,i) = 1;
        
        % ->
        if(arrow(i,j) == 1)
            graph(i,j) = 2;
            graph(j,i) = 3;
            continue;
        end
        
        % <-
        if(arrow(j,i) == 1)
            graph(i,j) = 3;
            graph(j,i) = 2;
            continue;
        end
        
        % <->
        if(latent(i,j) == 1)
            graph(i,j) = 2;
            graph(j,i) = 2;
            continue;
        end
        
        if(arrow(i,j) == -1)
            graph(j,i) = 2;
        end
        
        if(arrow(j,i) == -1)
            graph(i,j) = 2;
        end
    end
end

end