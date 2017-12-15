function [ P, SQs, ptools, ptool_maps, grasp_centre, action_centre ] = get_tool_info( pcl_path, gpr_task_path, task, verbose, pcl_mass )
    if ~exist('pcl_mass','var')
        pcl_mass = 0.1;
    end
    if ~exist('verbose','var')
        verbose = 0;
    end
    if verbose
        tic;
    end
    %% load GPR for task
    if verbose
        disp('Loading Gaussian Process Regression object for task...');
    end
    load(gpr_task_path);
    if verbose
        toc;
    end
    %% read pcl
    if verbose
        disp('Reading pcl...');
    end
    P = ReadPointCloud(pcl_path);
    if verbose
        toc;
    end
    %% fit SQs
    if verbose
        disp('Fitting SQs...');
    end
    [SQs, ~, ERRORS_SQs] = PCL2SQ(P, 1);
    if verbose
        toc;
    end
    %% get ptools
    if verbose
        disp('Extracting ptools...');
    end
    if numel(P.segms) == 1
        [ ptools, ptool_maps, ptool_errors ] = ExtractPTool(SQs{1},SQs{1}, pcl_mass,ERRORS_SQs);
    else
        [SQs_alt, ERRORS_SQs_alt] = GetRotationSQFits( SQs, P.segms );
        [ ptools, ptool_maps, ptool_errors ] = ExtractPToolsAltSQs(SQs_alt, pcl_mass, ERRORS_SQs_alt);
    end
    if verbose
        toc;
    end
    % decide which part is grasping
    ptool_ix = 6;
    % align ptool
    if verbose
        disp('Aligning ptool with pcl...');
    end
    [SQ_grasp, SQ_action] = AlignPToolWithPCL( ptools(ptool_ix,:), P, ptool_maps(ptool_ix,:) );
    if verbose
        toc;
    end
    %% get action end point
    transf_lists = PtoolsTaskTranfs( ptools(ptool_ix, :), task );
    P = Apply3DTransfPCL({P},transf_lists);
    PlotPCLSegments(P);
    %% print tool info
    disp('begin_tool_info');
    %% get grasp part centre
    grasp_centre = SQ_grasp(end-2:end);
    disp('Grasp part center:');
    disp([num2str(grasp_centre)]);
    %% get action part centre
    action_centre = SQ_action(end-2:end);
    disp('Action part center:');
    disp([num2str(action_centre)]);
    %% get tool tip
    tool_tip = [1 2 3];
    disp('Tool tip:');
    disp([num2str(tool_tip)]);
    
    disp('end_tool_info');    
end

