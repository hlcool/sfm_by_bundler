add_modeling_paths();

OBJECT_NAME = 'water';

load('camera_matrix.mat');
load('distortion_coefficients.mat');

img_dir = '/home/cooperzhang/modeling/examples/water/image';
out_dir = '/home/cooperzhang/modeling/examples/water/model';

imundistort_folder(img_dir, KK, kc);

draw_mask(img_dir);

cd (img_dir); 

model = sfm_bundler(OBJECT_NAME, img_dir, out_dir, KK, zeros(5,1), [2048 1536]);

sfm_view(model, 'all');

save(['model_' OBJECT_NAME '.mat'], 'model');

%sfm_alignment_gui(model);

%sfm_export_xml('/home/cooperzhang/modeling/examples/water/out/OBJECT_NAME.moped.xml', model);