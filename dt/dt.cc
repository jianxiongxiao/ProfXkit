#include "dt.h"
//#include <algorithm>
//using namespace std;

template <class T>
inline T square(const T &x) { return x*x; };



/* dt of 1d function using squared distance */
float *dt(float *f, int n) {
	float *d = new float[n];
	int *v = new int[n];
	float *z = new float[n+1];
	int k = 0;
	v[0] = 0;
	z[0] = -DT_INF;
	z[1] = +DT_INF;
	for (int q = 1; q <= n-1; q++) {
		float s  = ((f[q]+square(q))-(f[v[k]]+square(v[k])))/(2*q-2*v[k]);
		while (s <= z[k]) {
			k--;
			s  = ((f[q]+square(q))-(f[v[k]]+square(v[k])))/(2*q-2*v[k]);
		}
		k++;
		v[k] = q;
		z[k] = s;
		z[k+1] = +DT_INF;
	}

	k = 0;
	for (int q = 0; q <= n-1; q++) {
		while (z[k+1] < q)
			k++;
		d[q] = square(q-v[k]) + f[v[k]];
	}

	delete [] v;
	delete [] z;
	return d;
}

/* dt of 2d function using squared distance */
void dt2D(float **im, int width, int height) {
	float *f = new float[width+height];

	// transform along columns
	for (int x = 0; x < width; x++) {
		for (int y = 0; y < height; y++) {
			f[y] = ref2D(im, x, y);
		}
		float *d = dt(f, height);
		for (int y = 0; y < height; y++) {
			ref2D(im, x, y) = d[y];
		}
		delete [] d;
	}

	// transform along rows
	for (int y = 0; y < height; y++) {
		for (int x = 0; x < width; x++) {
			f[x] = ref2D(im, x, y);
		}
		float *d = dt(f, width);
		for (int x = 0; x < width; x++) {
			ref2D(im, x, y) = d[x];
		}
		delete [] d;
	}
	delete f;
}

/* dt of 3d function using squared distance */
void dt3D(float ***im, int width, int height, int zSize) {
	float *f = new float[width+height+zSize];

	for(int z = 0; z < zSize; z++){
		for (int x = 0; x < width; x++) {
			for (int y = 0; y < height; y++) {
				f[y] = ref3D(im, x, y, z);
			}
			float *d = dt(f, height);
			for (int y = 0; y < height; y++) {
				ref3D(im, x, y, z) = d[y];
			}
			delete [] d;
		}
	}

	for(int z = 0; z < zSize; z++){
		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				f[x] = ref3D(im, x, y, z);
			}
			float *d = dt(f, width);
			for (int x = 0; x < width; x++) {
				ref3D(im, x, y, z) = d[x];
			}
			delete [] d;
		}
	}

	for (int x = 0; x < width; x++) {
		for (int y = 0; y < height; y++) {
			for (int z = 0; z < zSize; z++) {
				f[z] = ref3D(im, x, y, z);
			}
			float *d = dt(f, zSize);
			for (int z = 0; z < zSize; z++) {
				ref3D(im, x, y, z) = d[z];
			}
			delete [] d;
		}
	}

	delete f;
}




