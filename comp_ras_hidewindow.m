function [bool_run] = comp_ras_hidewindow(RC,ras_file,hidewindow)
% Open project specified
RC.Project_Open(ras_file);
% Show main window?
if hidewindow == false
	RC.ShowRas;
end
% Show computation window?
if hidewindow == true
	RC.Compute_HideComputationWindow;
end

% Compute current plan
RC.Compute_CurrentPlan(0,true(1));
run_stat = RC.Compute_Complete;
% Wait for HEC-RAS to complete the computations
while run_stat == false
    run_stat = RC.Compute_Complete;
end
bool_run = run_stat;
end