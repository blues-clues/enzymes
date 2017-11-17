% Return the closest edge of P from point
function [ edges, min_dists, SQ ] = EdgeDetector( P, points, dump_edges, plot_fig, colours)
    %% check inputs
    try
        CheckIsPointCloudStruct(P);
    catch
        if ischar(P)
            P = ReadPointCloud(P);
        else
            PointCloud(P);
        end
    end
    try
        CheckNumericArraySize(points,[Inf 3]);
    catch
       % try to parse points string
       points_spilt = strsplit(points(2:end-1),';');
       points = zeros(numel(points_spilt),2);
       for i=1:numel(points_spilt)
           point_str = strsplit(points_spilt{i},' ');
           points(i,1) = str2double(point_str(1));
           points(i,2) = str2double(point_str(2));
           points(i,3) = str2double(point_str(3));
       end
    end
    disp('Points:');
    disp(points);
    disp('');
    if ~exist('dump_edges','var') || dump_edges < 0
        dump_edges = 0;
    end  
    if ischar(dump_edges)
        dump_edges = str2double(dump_edges);
    end
    if ~exist('plot_fig','var') || plot_fig < 0  || (ischar(plot_fig) && str2double(plot_fig) < 0)
        plot_fig = 0;
    end
    if ~exist('colours','var') || colours < 0 || (ischar(colours) && str2double(colours) < 0)
        colours = {'.g', '.b', '.y', '.c'};
    end          
    %% get SQ from pcl
    if plot_fig 
       clf; 
    end
    SQ = PCL2SQ(P,4,plot_fig);
    if plot_fig 
        hold on;        
    end
    SQ = SQ{1};
    %% get superellipse pcl 
    pcl_superellipse = superellipse( SQ(1), SQ(2), SQ(5) );
    pcl_superellipse = [pcl_superellipse zeros(size(pcl_superellipse,1),1)];
    % rotate pcl
    rot_mtx = GetEulRotMtx(SQ(6:8));    
    pcl_superellipse = [rot_mtx*pcl_superellipse']';
    pcl_superellipse = pcl_superellipse + SQ(end-2:end);
    pcl_superellipse(:,3) = pcl_superellipse(:,3) + SQ(3);    
    if plot_fig
        scatter3(pcl_superellipse(:,1),pcl_superellipse(:,2),pcl_superellipse(:,3),100,'.m');
    end
    %% calculate closest point
    dists = pdist2(pcl_superellipse,points);
    [min_dists,min_dist_ixs] = min(dists,[],1);    
    edges = pcl_superellipse(min_dist_ixs,:);
    for i=1:size(points,1)        
        if plot_fig
            scatter3(points(i,1),points(i,2),points(i,3),2000,colours{min(i,numel(colours))});
            scatter3(edges(i,1),edges(i,2),edges(i,3),2000,colours{min(i,numel(colours))});
        end
    end
    if plot_fig
        hold off;
    end
    if dump_edges
        disp('Edges:');
        disp(edges); 
    end
end
