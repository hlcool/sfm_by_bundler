add_modeling_paths();

OBJECT_NAME = 'walker';

img_filename = '/home/cooperzhang/modeling/examples/walker/image/walker.png';

pixels_per_meter = 13083.333;

model = sfm_bundler_planar(OBJECT_NAME, img_filename, 'walker.moped.xml', pixels_per_meter);