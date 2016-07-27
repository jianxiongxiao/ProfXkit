// Written by Jianxiong Xiao July 24, 2013
// Cite SUN3D paper if you use this code

#include "mex.h" 
#include <math.h>

// compilation
// mex -O raycast.cpp

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    mexPrintf("raycast\n"); 
    

    float* tMap = (float*) mxGetData(prhs[0]);
    float* raycastingDirectionW = (float*) mxGetData(prhs[1]); unsigned int  num_directions = mxGetN(prhs[0]);
    float* tnear = (float*) mxGetData(prhs[2]);
    float* tfar = (float*) mxGetData(prhs[3]);

    float* camCenterWgrid = (float*) mxGetData(prhs[4]);
    
    float* tsdf_value = (float*) mxGetData(prhs[5]);           
    unsigned int Xs = (unsigned int)mxGetScalar(prhs[6]);
    unsigned int Ys = (unsigned int)mxGetScalar(prhs[7]);
    float step = (float)mxGetScalar(prhs[8]);
    float largestep = (float)mxGetScalar(prhs[9]);
    
    //camCenterWgrid[0] = camCenterWgrid[0] -1;
    //camCenterWgrid[1] = camCenterWgrid[1] -1;
    //camCenterWgrid[2] = camCenterWgrid[2] -1;

    for (unsigned int i=0; i<num_directions; ++i){
                
        if (tnear[i]<tfar[i]){
            
            float* direction_by_unit = raycastingDirectionW+3*i;

            float t = tnear[i];
            
            // first walk with largesteps until we found a hit
            float stepsize = largestep;
            float f_t ;
            
            // f_t = interpolateTrilineary(camCenterWgrid + direction_by_unit * t);    
            {
                float X = camCenterWgrid[0] + direction_by_unit[0] * t;
                float Y = camCenterWgrid[1] + direction_by_unit[1] * t;
                float Z = camCenterWgrid[2] + direction_by_unit[2] * t;
                unsigned int X0=floor(X);    unsigned int X1=X0+1;
                unsigned int Y0=floor(Y);    unsigned int Y1=Y0+1;
                unsigned int Z0=floor(Z);    unsigned int Z1=Z0+1;
                float Xd = X-X0;      float Xdi=1-Xd;
                float Yd = Y-Y0;      float Ydi=1-Yd;
                float Zd = Z-Z0;      float Zdi=1-Zd;
                float c00 = tsdf_value[X0+Xs*(Y0+Ys*Z0)]*Xdi + tsdf_value[X1+Xs*(Y0+Ys*Z0)]*Xd;
                float c10 = tsdf_value[X0+Xs*(Y1+Ys*Z0)]*Xdi + tsdf_value[X1+Xs*(Y1+Ys*Z0)]*Xd;
                float c01 = tsdf_value[X0+Xs*(Y0+Ys*Z1)]*Xdi + tsdf_value[X1+Xs*(Y0+Ys*Z1)]*Xd;
                float c11 = tsdf_value[X0+Xs*(Y1+Ys*Z1)]*Xdi + tsdf_value[X1+Xs*(Y1+Ys*Z1)]*Xd;
                float c0 = c00*Ydi + c10*Yd;
                float c1 = c01*Ydi + c11*Yd;

                f_t = c0*Zdi + c1*Zd;            
            }

            if (f_t > 0){     // ups, if we were already in it, then don't render anything here
                float f_tt = 0;
                
                float tf = tfar[i];
                
                while (t < tf){
                    //f_tt = interpolateTrilineary(camCenterWgrid + direction_by_unit * t);
                    {
                        float X = camCenterWgrid[0] + direction_by_unit[0] * t;
                        float Y = camCenterWgrid[1] + direction_by_unit[1] * t;
                        float Z = camCenterWgrid[2] + direction_by_unit[2] * t;
                        unsigned int X0=floor(X);    unsigned int X1=X0+1;
                        unsigned int Y0=floor(Y);    unsigned int Y1=Y0+1;
                        unsigned int Z0=floor(Z);    unsigned int Z1=Z0+1;
                        float Xd = X-X0;      float Xdi=1-Xd;
                        float Yd = Y-Y0;      float Ydi=1-Yd;
                        float Zd = Z-Z0;      float Zdi=1-Zd;
                        float c00 = tsdf_value[X0+Xs*(Y0+Ys*Z0)]*Xdi + tsdf_value[X1+Xs*(Y0+Ys*Z0)]*Xd;
                        float c10 = tsdf_value[X0+Xs*(Y1+Ys*Z0)]*Xdi + tsdf_value[X1+Xs*(Y1+Ys*Z0)]*Xd;
                        float c01 = tsdf_value[X0+Xs*(Y0+Ys*Z1)]*Xdi + tsdf_value[X1+Xs*(Y0+Ys*Z1)]*Xd;
                        float c11 = tsdf_value[X0+Xs*(Y1+Ys*Z1)]*Xdi + tsdf_value[X1+Xs*(Y1+Ys*Z1)]*Xd;
                        float c0 = c00*Ydi + c10*Yd;
                        float c1 = c01*Ydi + c11*Yd;

                        f_tt = c0*Zdi + c1*Zd;            
                    }
                    
                    // got it, jump out of inner loop
                    if (f_tt < 0) break;
                    
                    // coming closer, reduce stepsize
                    if (f_tt < 0.8f) stepsize = step;

                    f_t = f_tt;
                    t += stepsize;
                }
                // got it, calculate accurate intersection
                if (f_tt < 0) 
                    tMap[i] = t + stepsize * f_tt / (f_t - f_tt);
            }
        }
    }  
}

