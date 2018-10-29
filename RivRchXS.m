function [r] = RivRchXS(RC)
% This function creates a structure containing the geometrical information
% of the HEC-RAS file specified.

% RC = actxserver('RAS500.HECRASCONTROLLER');
% Open project specified
% RC.Project_Open(ras_file)
% Get the number of rivers and their names
[r.nriv,riv_names] = RC.Geometry_GetRivers(0,0);
for i = 1:r.nriv
    %Use riv_names to populate the structure
    r.riv(i).rivnam = riv_names(i);
    
    %Get the number of reaches and their names
    [~,r.riv(i).nrch,rch_names] = RC.Geometry_GetReaches(i,0,0);   
    for j = 1:r.riv(i).nrch
       %Use rch_names to populate the structure
       r.riv(i).rch(j).rchnam = rch_names(j);
       
       %Get the number of nodes, node names and node types
       [~,~,r.riv(i).rch(j).nnode,node_names,node_type] = RC.Geometry_GetNodes ...
          (i,j,0,0,0);
       for k = 1:r.riv(i).rch(j).nnode
           %Use node_names and node_type to populate the structure
           r.riv(i).rch(j).node(k).RS = node_names(k);
           r.riv(i).rch(j).node(k).tnode = node_type(k);
       end
       
    end
    
end
end