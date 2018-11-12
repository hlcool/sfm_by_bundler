function [cam_poses, model] = ReadCamsBundler(file, readPts, imsize)
% READCAMSBUNDLER - Import the camera data portion from bundle.out.
% 
%   Usage: cam_poses = ReadCamsBundler(file, readPts);
%
%   Input:
%   file - Full path and filename of the bundler output file.
%   readPts - (optional) if true, read also the reconstructed 3D points
%   imsize - (optional) If readPts is set to true, imsize is used to 
%            re-align pts2D from image center to the lowest left corner.
%            If not given, no realignment is done.
%   
%
%   Output:
%   cam_poses - 6-by-K array of 6DOF camera poses [r1 r2 r3 t1 t2 t3]'
%               where [r1 r2 r3] is a rodrigues rotation vector. This
%               is a WORLD TO CAMERA transformation: x = K[R t]X.
%   model - Structure that contains all output data after running the sfm
%           algorithm. See sfm_model.m for details.
%
% Alvaro Collet
% acollet@cs.cmu.edu

if nargin < 3, imsize = [0 0]; end
if nargin < 2, readPts = false; end

if ~exist(file, 'file'),
    error('File does not exist');
end

% Open file
fp = fopen(file, 'rt');

% Read first line (uninteresting)
garbage = fgets(fp);

% Read #images and #points
var = fscanf(fp, '%d', 2);
nImgs = var(1); nPoints = var(2);

% Create matrix of camera poses
cam_poses = zeros(6, nImgs);

% Mirror matrix
Q = [1 0 0; 0 -1 0; 0 0 -1];

% Start extracting the camera positions
for i = 1:nImgs,
    cam_data = fscanf(fp, '%f', 15);
    % First three values of cam_data are estimation of some intrinsics (don't care)
    R = reshape(cam_data(4:12), [3 3])';
    T = cam_data(13:15);
    
    % Bundler uses -Z as the camera position (need to mirror it!)
    R = Q * R;
    T = Q * T;

    cam_poses(:,i) = format_rot('rod', R, T);
end

% Extract 3D points too
model = sfm_model;
model.cam_poses = cam_poses;
if readPts,
    pts3D = zeros(3, nPoints);
    color3D = zeros(3, nPoints);
    pts2D = zeros(2, nPoints, nImgs);
    keys = zeros(nPoints, nImgs);
    nViews = zeros(1, nPoints);
    for i = 1:nPoints,
        pt_data = fscanf(fp, '%f', 7); 
        pts3D(:, i) = pt_data(1:3);
        color3D(:,i) = pt_data(4:6);
        num_views = pt_data(7);
        nViews(i) = num_views;
        for j = 1:num_views,
            view_data = fscanf(fp, '%f', 4); % view, key, x, y
            % view and key are both zero-based, and (x=0,y=0) is the image
            % center
            pts2D(1, i, view_data(1)+1) = view_data(3) + imsize(1)/2;
            pts2D(2, i, view_data(1)+1) = imsize(2)/2 - view_data(4);
            keys(i, view_data(1)+1) = view_data(2)+1;
        end
    end
    model.pts3D = pts3D;
    model.color3D = color3D;
    model.pts2D = pts2D;
    model.keys = keys;
    model.num_views = nViews;
end
fclose(fp);
