%% Calculates the MOI by fitting SQs to the pcl
% If SQs is a path or a struct it will be considered a pcl path or P struct
%   and the function will fit SQs to the this pcl
% If SQs is a cell array it will be considered as a list of SQs
%
% The outputs are:
%   centre of mass
%   The I inertial matrix)
%   inertial (6x1 array) holding both centre of mass and inertia diagonal
%   the read pcl P is SQs was a path to a pcl file or a P struct 
%
% Currently this is a very crude approximation sicne it does not consider
% bending, tpaering nor superparaboloids. In the future I hope I have time 
% to add these :(
%
% Thanks to Benjamin Nougier who contribute to the code
%% By Paulo Abelha
function [ I, centre_mass, volume ] = CalcCompositeMomentInertia( Param1, mass)
    %% deal with first argument being a PCL
    try
        CheckIsPointCloudStruct(Param1);
        SQs = PCL2SQ(Param1);
    catch 
        %% deal with SQs param
        SQs = Param1;
        % deal with when param is a single SQ
        if ~iscell(SQs) && size(SQs,1) == 1
            SQs = {SQs};
        end
    end
    %% get centre of mass
    centre_mass = CentreOfMass( SQs );
    %% start MOI calculation
    %% calculate the individual moments of inertia for each SQ
    Iparts = zeros(numel(SQs),3,3);
    for i=1:numel(SQs)
        density = mass/VolumeSQ(SQs{1});
        Iparts(i,:,:)=MomentInertiaSQ(SQs{i})*density;
    end    
    %% Get projection distances of SQs centers on axis passing by center of mass
    d = zeros(size(SQs,2),3);
    for i=1:numel(SQs) % == length(SQs)
        SQ_center_coord = SQs{i}(end-2:end);
        for proj_axis=1:3 
            % ( if 1 = "x axis" for example, then 2 = y axis, and 3 = z axis)
            % To get the distance to the axis, we use Pythagoras theorem. 
            % This distance is then given by : (on x axis for example)
            %
            % dist_to_x_axis_passing_by_centerOfMass = sqrt(SQ_coord(y)^2+SQ_coord(z)^2)
            % 
            % In order to be generic, we use the modulo to get the next
            % axis id (1, 2 or 3). for example, if axis_1 has the value 2,
            % next axis (axis_2) will get 3 and the last one will get 1.
            % Since the modulo 3 gives us 0,1 or 2, we first apply the
            % modulo then add 1 to the resulting id.
            axis_1 = proj_axis;
            axis_2 = mod(axis_1,3)+1;
            axis_3 = mod(axis_1+1,3)+1;
            d(i, axis_1) = sqrt( (SQ_center_coord(axis_2)^2) + (SQ_center_coord(axis_3)^2) );
        end
    end
    %% Get total volume
    total_volume = 0;
    for  i=1:numel(SQs)
        total_volume = total_volume + VolumeSQ(SQs{i});
    end
    %% Get MOI
    % For each axis, sum moment of inertia of each SQ projected on this axis
    I=zeros(3,3);
    for proj_axis=1:3
        sum=0; 
        for i=1:numel(SQs)
            SQ_volume = VolumeSQ(SQs{i});
            SQ_vol_contribution = (SQ_volume/total_volume);
            sum=sum+Iparts(i,proj_axis,proj_axis)+(SQ_vol_contribution*(d(i,proj_axis)^2));
        end
        I(proj_axis,proj_axis) = sum;
    end
end