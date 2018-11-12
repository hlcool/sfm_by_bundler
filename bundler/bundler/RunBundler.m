function RunBundler(image_dir, output_dir, cam_K, cam_dist, imsize)
% RUNBUNDLER - Execute the Structure From Motion Bundler software.
%   RunBundler offers an easy interface to call Bundler from Matlab, and
%   retrieve the camera positions when the process has finished. Sorry, but
%   the 3D points retrieval is not implemented yet.
%
%   Usage: cam_poses = RunBundler(image_dir, output_dir, cam_K, ...
%                                 cam_dist, imsize);
%
%   Input:
%   image_dir - Path to image directory (should be JPG files), with N images
%   output_dir - Directory where to store all relevant data for a model.
%   WARNING: BOTH IMAGE_DIR and OUTPUT_DIR need to be FULL PATHS!! (or ./,
%   which is also fine).
%   cam_K - 3-by-3 intrinsic camera matrix, or 4-by-1 [fx fy cx cy] params.
%   cam_dist - 5-by-1 camera distortion parameters (same format as the
%              Bouguet's Camera Calibration Toolbox). If the input images
%              have been previously undistorted, enter zeros(5,1) or [].
%   imsize - Size of each image (must be all the same), in [width height]
%   (default: [640 480])
%
%   Output:
%   -NONE- Bundler will create a file 'bundle.out' in the output directory
%          specified, but no explicit output is given.
%
% WARNING: This file MUST be in the same folder as RunBundler.sh
% REQUIRED LIBRARIES for Bundler:
%   sudo apt-get install imagemagick libminpack-dev gfortran
%
% Alvaro Collet
% acollet@cs.cmu.edu

% Default imsize value
if nargin < 5, imsize = [640 480]; end
if nargin < 4 || isempty(cam_dist), cam_dist = zeros(5,1); end

% If output folder does not exist, create it
if ~exist(output_dir, 'dir'),
    mkdir(output_dir);
else
    delete(fullfile(output_dir,'*'));
end

%% Export intrinsic parameters to a file (cam_params.txt)
fp = fopen(fullfile(output_dir, 'cam_params.txt'), 'wt');

if numel(cam_K) == 9,
    params = [cam_K(1,1) cam_K(2,2) cam_K(1, 3) cam_K(2, 3)];
else
    params = cam_K;
end

if numel(cam_dist) == 5,
    p_dist = cam_dist;
else
    p_dist = zeros(5,1);
    p_dist(1:numel(cam_dist)) = cam_dist;
end

% Express principal point w.r.t. the CAMERA CENTER. Careful, because
% Bundler defines the Y axis as the opposite of ours.
% params(3:4) = params(3:4) - imsize/2;
params(3) = -(imsize(1)/2 - params(3));
params(4) = (imsize(2)/2 - params(4));

% There is only ONE camera 
fprintf(fp, '1\n');
% K params
fprintf(fp, '%.9f 0 %.9f 0 %.9f %.9f 0 0 1\n', params(1), params(3), params(2), params(4));
% Radial distortion
fprintf(fp, '%.9f %.9f %.9f %.9f %.9f\n', p_dist(1), p_dist(2), p_dist(3), p_dist(4), p_dist(5));
fclose(fp);

%% Run Bundler

% RunBundler.sh must be in the same folder than this script
path_bundler = fileparts(mfilename('fullpath'));

% Tell the user to execute this command
% command = sprintf('%s/RunBundler.sh %s %s', path_bundler, image_dir, output_dir);
% fprintf('Finished configuration. Now please open a terminal and type: \n%s\n', command);

eval(sprintf('!%s/RunBundler.sh %s %s', path_bundler, image_dir, output_dir));
