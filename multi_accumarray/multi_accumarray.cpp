/*
Fast multi-dimensional accumarray. For example, it is useful to aggregate the feature based on a segmentation map.

Input: takes a (d*n) single matrix FeatureIn, a (1*n) uint32 matrix Index, a uint32 integer MaxIndex to indicate the size of matrix Index.
Output: a (d*MaxIndex) single matrix FeatureOut.

Example usage: feature_out = multi_accumarray(feature_in, segmentation_mask, number_of_segments);

--Jianxiong Xiao http://mit.edu/jxiao/

Please cite the following paper if you use this in your project:

J. Xiao and L. Quan
Multiple View Semantic Segmentation for Street View Images
Proceedings of 12th IEEE International Conference on Computer Vision (ICCV2009)
*/

#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

float* FeatureIn = (float*) mxGetData(prhs[0]);
unsigned int d = mxGetM(prhs[0]);
unsigned int n = mxGetN(prhs[0]);
unsigned int* IndexCurrent = (unsigned int*) mxGetData(prhs[1]);
unsigned int MaxIndex = (unsigned int) mxGetScalar(prhs[2]);

//plhs[0] = mxCreateNumericMatrix(d, MaxIndex, mxSINGLE_CLASS, mxREAL);
plhs[0] = mxCreateNumericMatrix(1, d*MaxIndex, mxSINGLE_CLASS, mxREAL);

// waste of the first pointer, in order to handle matlab's starting from 1 indexing scheme.
float** OutPointers = new float* [1+MaxIndex];
OutPointers[1] = (float*) mxGetData(plhs[0]);
for (unsigned int i=2; i<=MaxIndex; ++i){
	OutPointers[i] = OutPointers[i-1] + d;
}

float* InCurrent = FeatureIn;
float* InEnd = FeatureIn+(d*n);

while(InCurrent!=InEnd){
	float* OutCurrent = OutPointers[*IndexCurrent++];
	float* OutEnd = OutCurrent + d;
	while(OutCurrent!=OutEnd){
		*OutCurrent++ += *InCurrent++;
	}
}

delete [] OutPointers;

}
