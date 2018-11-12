function [locs, desc] = read_gzipped_sift (file)
% READ_GZIPPED_SIFT - Decompress .KEY.GZ file, import SIFT data and compress
%
%   Usage: [locs, desc] = read_gzipped_sift(filename)
%
%   Input:
%   filename - gzipped SIFT filename to be read
%
%   Output:
%   locs: 4-by-K matrix, in which each row has the 4 values for a
%         keypoint location (X, Y, scale, orientation).  The 
%         orientation is in the range [-PI, PI] radians.
%   desc: a 128-by-K matrix, where each row gives an invariant
%         descriptor for one of the K keypoints.  The descriptor is a vector
%         of 128 values normalized to unit length.
%
% Alvaro Collet
% acollet@cs.cmu.edu

% Make sure it's a .key.gz file
if ~strcmpi('.key.gz',file(end-6:end)), error('File type must be .key.gz'); end

% Unzip file
eval(sprintf('!gunzip %s\n', file));

% Open file.key and check its header
g = fopen(file(1:end-3), 'r');
[header, count] = fscanf(g, '%d %d', [1 2]);
num = header(1);
len = header(2);

% Creates the two output matrices (use known size for efficiency)
locs = double(zeros(num, 4));
desc = double(zeros(num, 128));

% Parse tmp.key
for i = 1:num
    [vector, count] = fscanf(g, '%f %f %f %f', [1 4]); %row col scale ori
    if count ~= 4
        error('Invalid keypoint file format');
    end
    locs(i, :) = vector(:);

    [descriptors, count] = fscanf(g, '%d', [1 len]);
    if (count ~= 128)
        error('Invalid keypoint file value.');
    end
    
    % Normalize each input vector to unit length
    desc(i, :) = descriptors(:) ./ norm(descriptors(:));
end
fclose(g);

% Restore gzipped file
gzipcommand = ['!gzip ' file(1:end-3)];
eval(gzipcommand);



