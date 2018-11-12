% Compile files

% Copyright: Carnegie Mellon University & Intel Corporation
% Author: Alvaro Collet (acollet@cs.cmu.edu)

mex rodrigues.cpp -I/usr/local/opencv2413/include/opencv -L/usr/local/opencv2413/lib -lopencv_core -lopencv_calib3d
mex quat2rot.cpp 
mex meanshift/meanShift1.c
movefile meanShift1.* meanshift
mex imundistort.cpp matlab_cv.cpp cvundistort.cpp -I/usr/local/opencv2413/include/opencv -L/usr/local/opencv2413/lib -lopencv_core -lopencv_calib3d
