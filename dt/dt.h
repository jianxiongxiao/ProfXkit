// distance transform adapted from Pedro Felzenszwalb's code


#ifndef DT_H_
#define DT_H_

#define DT_INF 1E20


#define ref2D(array, x, y) (im[y][x])
#define ref3D(array, x, y, z) (im[z][y][x])


float *dt(float *f, int n);
void dt2D(float **im, int width, int height);
void dt3D(float ***im, int width, int height, int zSize);

#endif  // DT_H_
