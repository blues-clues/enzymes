function [ P, SQs, ptools, ptool_maps, grasp_centre, action_centre ] = GetToolInfo( pcl_path, gpr_task_path, task, verbose, pcl_mass )
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
        disp('begin_log');
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
    [~, ~, weights ] = ProjectionHyperParams;
    n_weight_tries = size(weights,1);
    best_weight_ix = round(n_weight_tries/2)+1;
    if verbose
        disp('Performing projection...');
    end
    [ best_scores, best_categ_scores, best_ptools, best_ptool_maps, best_ixs, SQs_ptools, ERRORS_SQs_ptools ] = SeedProjection( P, pcl_mass, task, @TaskFunctionGPR, {gprs{end}, dims_ixs{end}}, 0, 0, 1, verbose );  
    best_score = best_scores(best_weight_ix);
    best_categ_score = best_categ_scores(best_weight_ix);
    best_ptool = best_ptools(best_weight_ix,:);
    best_ptool_map = best_ptool_maps(best_weight_ix,:);
    best_SQs = SQs_ptools{best_ixs(best_weight_ix)};
    best_ERRORS_SQs_ptools = ERRORS_SQs_ptools{best_ixs(best_weight_ix)};
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
    ptool_ix = 1;
    % align ptool
    if verbose
        disp('Extracting pcl transformation');
    end
    [SQ_grasp, SQ_action] = AlignPToolWithPCL( ptools(ptool_ix,:), P, ptool_maps(ptool_ix,:) );
    %% get action end point
    transf_lists = PtoolsTaskTranfs( ptools(ptool_ix, :), task );
    P = Apply3DTransfPCL({P},transf_lists);
    PlotPCLSegments(P);
    if verbose
        toc;
    end
    %% finish log writing
    if verbose
        disp('end_log');
    end
    %% print tool info
    disp('begin_tool_info');
    % get affordance score
    disp('affordance_score');
    disp(num2str(best_categ_score));
    % get grasp part centre
    grasp_centre = SQ_grasp(end-2:end);
    disp('grasp_center');
    disp(num2str(grasp_centre));
    % get action part centre
    action_centre = SQ_action(end-2:end);
    disp('action_center');
    disp(num2str(action_centre));
    % get tool tip
    tool_tip = [1 2 3];
    disp('tool_tip');
    disp([num2str(tool_tip)]);    
    disp('end_tool_info');    
end

