################################################################################
#                                                                              
# Bundler.py
#
# Copyright: Carnegie Mellon University & Intel Corp.
# Author: Alvaro Collet (acollet@cs.cmu.edu)
#
################################################################################
""" Bundler.py: Simple interface to run Bundler from python

    REMINDER: REQUIRED LIBRARIES for Bundler:
      sudo apt-get install imagemagick gfortran
"""
import numpy as np
import tf_format
import os

# --------------------------------------------------------------------------- #
def run(image_dir, output_dir, cam_K, cam_dist = None, imsize = None):
    """Execute the Structure From Motion Bundler software.
      This module offers an easy interface to call Bundler from Python, and
      retrieve the camera positions when the process has finished. Sorry, but
      the 3D points retrieval is not implemented yet.
   
      Usage: Bundler.run(image_dir, output_dir, cam_K, cam_dist, imsize);
   
      Input:
      image_dir - Path to image directory (should be JPG files), with N images
      output_dir - Directory where to store all relevant data for a model.
      WARNING: BOTH IMAGE_DIR and OUTPUT_DIR need to be FULL PATHS!! (or ./,
      which is also fine).
      cam_K - 3-by-3 intrinsic camera matrix, or 4-by-1 [fx fy cx cy] params.
      cam_dist - 5-by-1 camera distortion parameters (same format as the
                 Bouguet's Camera Calibration Toolbox). If the input images
                 have been previously undistorted, enter zeros(5,1) or [].
      imsize - Size of each image (must be all the same), in (width, height)
      (default: (640, 480))
   
      Output:
      -NONE- Bundler will create a file 'bundle.out' in the output directory
             specified, but no explicit output is given.
   
    WARNING: This file MUST be in the same folder as RunBundler.sh

   """

    # Default imsize value
    imsize = (640, 480) if imsize is None else imsize
    cam_dist = np.zeros((5,1)) if cam_dist is None else cam_dist

    # If output folder does not exist, create it
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
    else:
        os.system('rm ' + os.path.join(output_dir, '*')) 

    if cam_K.size == 9:
        params = np.array((cam_K[0,0], cam_K[1,1], cam_K[0, 2], cam_K[1, 2]))
    else:
        params = cam_K

    if cam_dist.size == 5:
        p_dist = cam_dist
    else:
        p_dist = np.zeros((5,1))
        p_dist[:cam_dist.size] = p_dist

    # Export intrinsic parameters to a file (cam_params.txt)
    with open(os.path.join(output_dir, 'cam_params.txt'), 'wt') as fp:
        # Express principal point w.r.t. the CAMERA CENTER. Careful, because
        # Bundler defines the Y axis as the opposite of ours.
        params[2] = -(imsize[0]/2 - params[2]);
        params[3] = (imsize[1]/2 - params[3]);

        # There is only ONE camera 
        fp.write('1\n');
        # K params
        fp.write('{0:.9f} 0 {1:.9f} 0 {2:.9f} {3:.9f} 0 0 1\n'.format( \
                 params[0], params[2], params[1], params[3]) );

        # Radial distortion
        fp.write('{0:.9f} {1:.9f} {2:.9f} {3:.9f} {4:.9f}\n'.format(p_dist[0],\
                 p_dist[1], p_dist[2], p_dist[3], p_dist[4]) );

    # RunBundler.sh must be in the same folder as this script
    path_bundler = os.path.dirname( os.path.realpath( __file__ ) ) 
    
    # Now run bundler
    os.system('{0:s}/RunBundler.sh {1:s} {2:s}'.format(path_bundler, \
                                                       image_dir, output_dir))
    return

# --------------------------------------------------------------------------- #
def read_data(file, imsize = None, read_pts = True, read_images = True):
    """ Import camera and scene data from bundle.out.
    
      Usage: data = ReadCamsBundler(file, read_pts=False, imsize)
      
      Input:
      file - Full path and filename of the bundler output file (usually,
             bundle.out). If only a path is given, we assume the file is
             bundle.out. Also, we look for the file 'list.txt' in that same
             folder to extract the image names.
      imsize{(0, 0)} - (optional) If read_pts is set to true, imsize is used to 
               re-align pts2D from image center to the lowest left corner.
               If not given, no realignment is done.
      read_pts{True} - (optional) if True, read also reconstructed 3D points
      read_images{True} - (optional) if True, read also image names involved
            in bundle adjustment.
      Output:
      cam_poses - 6-by-K array of 6DOF camera poses [r1 r2 r3 t1 t2 t3]'
                  where [r1 r2 r3] is a rodrigues rotation vector. This
                  is a WORLD TO CAMERA transformation: x = K[R t]X.
      scene - Structure that contains all output data after running the sfm
              algorithm. See sfm_model.m for details.
      image_names - List of image names used in this bundle adjustment. It is
        an ordered list, so image_names[i] corresponds to cam_poses[:,i].
    """
    imsize = (0,0) if imsize is None else imsize

    if not os.path.exists(file):
        raise "File does not exist!"

    path, name = os.path.split(file)
    images_file = os.path.join(path, 'list.txt')

    # Open file
    with open(file, 'rt') as fp:

        # Read first line (uninteresting)
        fp.readline()

        # Read #images and #points
        line = fp.readline().split()
        nImgs = int(line[0])
        nPoints = int(line[1])

        # Create matrix of camera poses
        cam_poses = np.zeros((6, nImgs))

        # Mirror matrix
        Q = np.c_[[1, 0, 0], [0, -1, 0], [0, 0, -1]];

        # Start extracting the camera positions
        for i in range(nImgs):
            R = np.zeros((3,3))
            # First three values of cam_data are estimation of some intrinsics (don't care)
            cam_data = np.fromstring(fp.readline(), sep = ' ')
            # Read R line by line
            R[0,:] = np.fromstring(fp.readline(), sep = ' ')
            R[1,:] = np.fromstring(fp.readline(), sep = ' ')
            R[2,:] = np.fromstring(fp.readline(), sep = ' ')
            T = np.fromstring(fp.readline(), sep = ' ')
            # Bundler uses -Z as the positive depth, we don't (need to mirror it!)
            R = np.dot(Q, R)
            T = np.dot(Q, T)
            cam_poses[:,i] = tf_format.tf_format('rod', R, T);
            
        # Extract 3D points too
        scene = dict()
        if read_pts:
            pts3D = np.zeros((3, nPoints))
            color3D = np.zeros((3, nPoints), dtype=np.uint8)
            pts2D = np.zeros((2, nPoints, nImgs))
            keys = np.zeros((nPoints, nImgs))
            nViews = np.zeros((nPoints,))
            for i in range(nPoints):
                pts3D[:, i] = np.fromstring(fp.readline(), sep = ' ')
                color3D[:,i] = np.fromstring(fp.readline(), sep = ' ')
                buffer = np.fromstring(fp.readline(), sep=' ')
                num_views = int(buffer[0])
                nViews[i] = num_views
                for j in range(num_views):
                    # Values: view, key, x, y for each point
                    view_data = buffer[1+j*4:5+j*4]
                    # view and key are both zero-based, and (x=0,y=0) is the 
                    # image center
                    pts2D[0, i, view_data[0]] = view_data[2] + imsize[0]/2
                    pts2D[1, i, view_data[0]] = imsize[1]/2 - view_data[3]
                    keys[i, view_data[0]] = view_data[1]
            
            scene['pts3D'] = pts3D
            scene['color3D'] = color3D
            scene['pts2D'] = pts2D
            scene['keys'] = keys
            scene['num_views'] = nViews
    
    # Now read image names
    image_names = list()
    if read_images:
        with open(images_file, 'rt') as fp:
            for image_line in fp:
                # There are three fields, we only want the first
                image_names.append(image_line.split()[0])

    # If we don't want scene data, 'scene' is empty
    # If we don't want image names, 'image_names' is empty
    return cam_poses, scene, image_names


# --------------------------------------------------------------------------- #
def read_image_names(file, read_pts = False, imsize = None):
    """ Import camera and scene data from bundle.out.
    
      Usage: data = ReadCamsBundler(file, read_pts=False, imsize)
      
      Input:
      file - Full path and filename of the bundler output file (usually,
             bundle.out)
      read_pts{False} - (optional) if True, read also reconstructed 3D points
      imsize{(0, 0)} - (optional) If read_pts is set to true, imsize is used to 
               re-align pts2D from image center to the lowest left corner.
               If not given, no realignment is done.
      
      Output:
      cam_poses - 6-by-K array of 6DOF camera poses [r1 r2 r3 t1 t2 t3]'
                  where [r1 r2 r3] is a rodrigues rotation vector. This
                  is a WORLD TO CAMERA transformation: x = K[R t]X.
      scene - Structure that contains all output data after running the sfm
              algorithm. See sfm_model.m for details.
    """
