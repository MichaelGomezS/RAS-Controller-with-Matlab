%*************************************************************************
%This script runs a RAS project in a sequencial manner using the controller
%to run and retrieve the output to a structure(r) and editing the input text
%files to change the simulation time window and the hot start file. Calls 
%the RivRchXS function. Calls the comp_ras_hidewindow function.

% Written by: Michael Gómez S.
% Date: 11/22/2016

%*************************************************************************
clear
% Create OLE automation server for the RASController
tic
RC = actxserver('RAS500.HECRASCONTROLLER');
% Path of the project
ras_file = 'C:\Users\MVG5545\Documents\Research\RAS_runs\obs\test.prj';
% Path of plan text file
planfile = 'C:\Users\MVG5545\Documents\Research\RAS_runs\obs\test.p01';
%planfile = 'C:\Users\MVG5545\Desktop\New folder\test.p01';
tempplanfile = 'C:\Users\MVG5545\Documents\Research\RAS_runs\obs\test_temp.p01';
%tempplanfile = 'C:\Users\MVG5545\Desktop\New folder\test_temp.p01';
% Path of flow text file
flowfile = 'C:\Users\MVG5545\Documents\Research\RAS_runs\obs\test.u02';
%flowfile = 'C:\Users\MVG5545\Desktop\New folder\test.u02';
tempflowfile = 'C:\Users\MVG5545\Documents\Research\RAS_runs\obs\test_temp.u02';
%tempflowfile = 'C:\Users\MVG5545\Desktop\New folder\test_temp.u02';
% Starting and ending of simulation
start_day = 9; start_month = 10; start_year = 2007;
end_day = 31; end_month = 12; end_year = 2013;

% Enter the time window in days
time_window = 1;

% Generate date vector
date = datetime(start_year,start_month,start_day):time_window:datetime(end_year,end_month,end_day);
formatOut = 'ddmmmyyyy';
str_date = datestr(date(1:end),formatOut);

% Workspace
numdays = length(date);
ws = cell(numdays,1);
save_folder = 'obs';
for i = 1 : length(date)
    ws{i} = [save_folder,'/','s',num2str(i)];
end

%% Run the first model and create restart file

%**************************** TEXT FILE EDIT ******************************
% Edit original and temporary plan files
% Open plan file
fid1 = fopen(planfile,'r');
fid2 = fopen(tempplanfile,'wt');

% Strings to look for
str_simdate = 'Simulation Date='; str_writeIC = 'Write IC File='; 
str_ICtime = 'IC Time=';
% New strings 
starting_date = str_date(1,:); starting_hour = '2400'; 
ending_date = str_date(2,:); ending_hour = '2400';

% Copy line by line the original text file into the temporary file, making
% the necessary adjustments.
tline = fgetl(fid1);
fprintf(fid2,'%s\n',tline);

while ischar(tline)
    tline = fgetl(fid1);
    if strfind(tline,str_simdate) > 0 % change the simulation date
        fprintf(fid2,'%s\n',[str_simdate,starting_date,',',starting_hour,',',...
            ending_date,',',ending_hour]);
    elseif strfind(tline,str_writeIC) > 0 % turn on hte write IC option
        fprintf(fid2,'%s\n',[str_writeIC,' 1']);
    elseif strfind(tline,str_ICtime) > 0 % change the date of the restart file 
        fprintf(fid2,'%s\n',[str_ICtime,',',ending_date,',',ending_hour]);
    else
        fprintf(fid2,'%s\n',tline);
    end           
end

% Close text handles
fclose(fid1);
fclose(fid2);

% Replace original file with temporary one and delete the temporary file
copyfile(tempplanfile,planfile);
delete(tempplanfile);

%***************************** RUN THE MODEL ******************************
% Call comp_ras function. Run the model
bool_run = comp_ras(RC,ras_file);
% Get number of profiles and their names
[nprof,prof] = RC.Output_GetProfiles(0,0);
% Call RivRchXS function. Get the geometric data and store it in a structure
r = RivRchXS(RC);

% Retrieve the stage and flow for each time profile at each cross section 
% and store it in the structure created by the RivRchXS function
% Profiles
for l = 2 : nprof
    % Rivers
    for i = 1 : r.nriv
        % Reaches
        for j = 1 : r.riv(i).nrch
            % Stations
            for k = 1 : r.riv(i).rch(j).nnode
                [r.riv(i).rch(j).node(k).stage(l),~,~,~,~,~] =...
                    RC.Output_NodeOutput(i, j, k, 2, l, 2);
                [r.riv(i).rch(j).node(k).flow(l),~,~,~,~,~] =...
                    RC.Output_NodeOutput(i, j, k, 2, l, 9);
            end
        end
    end
end
save(ws{1},'r','prof')
RC.QuitRas;
% !taskkill /im ras.exe
%% Run the model for second time window

for d = 2 : length(date) - 1
    %**************************** TEXT FILE EDIT **************************
    %******PLAN FILE*******************************************************
    % Open plan file
    fid1 = fopen(planfile,'r');
    fid2 = fopen(tempplanfile,'wt');

    % Strings to look for
    str_simdate = 'Simulation Date='; str_writeIC = 'Write IC File='; 
    str_ICtime = 'IC Time=';
    % New strings 
    starting_date = str_date(d,:); starting_hour = '2400'; 
    ending_date = str_date(d+1,:); ending_hour = '2400';

    % Copy line by line the original text file into the temporary file, making
    % the necessary adjustments.
    tline = fgetl(fid1);
    fprintf(fid2,'%s\n',tline);

    while ischar(tline)
        tline = fgetl(fid1);
        if strfind(tline,str_simdate) > 0 % change the simulation date
            fprintf(fid2,'%s\n',[str_simdate,starting_date,',',starting_hour,',',...
                ending_date,',',ending_hour]);
        elseif strfind(tline,str_writeIC) > 0 % turn on the write IC option
            fprintf(fid2,'%s\n',[str_writeIC,' 1']);
        elseif strfind(tline,str_ICtime) > 0 % change the date of the restart file 
            fprintf(fid2,'%s\n',[str_ICtime,',',ending_date,',',ending_hour]);
        else
            fprintf(fid2,'%s\n',tline);
        end           
    end

    % Close text handles
    fclose(fid1);
    fclose(fid2);

    % Replace original file with temporary one and delete the temporary file
    copyfile(tempplanfile,planfile);
    delete(tempplanfile);
    
    %******FLOW FILE*******************************************************
    % Open flow file
    fid1 = fopen(flowfile,'r');
    fid2 = fopen(tempflowfile,'wt');
    
    % Strings to look for
    str_use_rst = 'Use Restart=';
    str_rst_flname = 'Restart Filename=';
    % New strings for the flow file
    str_nameprj = 'test';              % CHANGE THIS FOR DIFFERENT PROJECTS
    str_nameplan = '.p01.';            % CHANGE THIS FOR DIFFRENT PLANS
    restart_file = [str_rst_flname,str_nameprj,str_nameplan,...
        starting_date,' ',starting_hour,'.rst'];
    
    % Copy line by line the original text file into the temporary file, making
    % the necessary adjustments.
    tline = fgetl(fid1);
    fprintf(fid2,'%s\n',tline);

    while ischar(tline)
        tline = fgetl(fid1);
        if strfind(tline,str_use_rst) > 0  % turn on the use restart option
            fprintf(fid2,'%s\n','Use Restart=-1'); 
            fprintf(fid2,'%s\n',restart_file);
        elseif strfind(tline,str_rst_flname) > 0 % delete old restart filename 
            % don't copy line
        else
            fprintf(fid2,'%s\n',tline);
        end           
    end
    % Close text handles
    fclose(fid1);
    fclose(fid2);

    % Replace original file with temporary one and delete the temporary file
    copyfile(tempflowfile,flowfile);
    delete(tempflowfile);
    
    %***************************** RUN THE MODEL **************************
    % Call comp_ras function. Run the model
    bool_run = comp_ras(RC,ras_file);
    % Get number of profiles and their names
    [nprof,prof] = RC.Output_GetProfiles(0,0);
    % Call RivRchXS function. Get the geometric data and store it in a structure
    r = RivRchXS(RC);

    % Retrieve the stage and flow for each time profile at each cross section 
    % and store it in the structure created by the RivRchXS function
    % Profiles
    for l = 2 : nprof
        % Rivers
        for i = 1 : r.nriv
            % Reaches
            for j = 1 : r.riv(i).nrch
                % Stations
                for k = 1 : r.riv(i).rch(j).nnode
                    [r.riv(i).rch(j).node(k).stage(l),~,~,~,~,~] =...
                        RC.Output_NodeOutput(i, j, k, 2, l, 2);
                    [r.riv(i).rch(j).node(k).flow(l),~,~,~,~,~] =...
                        RC.Output_NodeOutput(i, j, k, 2, l, 9);
                end
            end
        end
    end
    save(ws{d},'r','prof')
    RC.QuitRas;
    
end
!taskkill /im ras.exe
toc

%% Check results at Philly
% load([ws{1},'.mat'])
% stage = r.riv(3).rch(7).node(14).stage';
% n = length(stage);
% tot_stage = zeros(n+(n-2)*26,1);
% tot_stage(1:n) = stage;
% w1 = 3 ; w2 = n;
% 
% for i = 2 : 27
%     w1 = w1 + 360; w2 = w2 + 360;
%     load([ws{i},'.mat'])
%     stage = r.riv(3).rch(7).node(14).stage(3:end)';
%     tot_stage(w1:w2) = stage;
% end