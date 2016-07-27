#include "mex.h"
#include <cmath>
#include <cstdio>
#include <iostream>
#include "ceres/ceres.h"
//#include "ceres/rotation.h"

double fx, fy, px, py, w;


struct AlignmentError2D {
  AlignmentError2D(double* observed_in): observed(observed_in) {}

  template <typename T>
  bool operator()(const T* const camera_extrinsic,
                  const T* const point,
                  T* residuals) const {
                  
    // camera_extrinsic[0,1,2] are the angle-axis rotation.
    T p[3];
    
    //ceres::AngleAxisRotatePoint(camera_extrinsic, point, p);
    T x = camera_extrinsic[0];
    T y = camera_extrinsic[1];
    T z = camera_extrinsic[2];
    T x2 = x*x;
    T y2 = y*y;
    T z2 = z*z;    
    T w2 = T(1.0) - x2 - y2 - z2;
    T w  = sqrt(w2);
    
    p[0] = point[0]*(w2 + x2 - y2 - z2) - point[1]*(T(2.0)*w*z - T(2.0)*x*y) + point[2]*(T(2.0)*w*y + T(2.0)*x*z);
    p[1] = point[1]*(w2 - x2 + y2 - z2) + point[0]*(T(2.0)*w*z + T(2.0)*x*y) - point[2]*(T(2.0)*w*x - T(2.0)*y*z);
    p[2] = point[2]*(w2 - x2 - y2 + z2) - point[0]*(T(2.0)*w*y - T(2.0)*x*z) + point[1]*(T(2.0)*w*x + T(2.0)*y*z);
    
    // camera_extrinsic[3,4,5] are the translation.
    p[0] += camera_extrinsic[3];
    p[1] += camera_extrinsic[4];
    p[2] += camera_extrinsic[5];
    
    // project it
    p[0] = T(fx) * p[0] / p[2] + T(px);
    p[1] = T(fy) * p[1] / p[2] + T(py);
    
    // reprojection error
    residuals[0] = p[0] - T(observed[0]);
    residuals[1] = p[1] - T(observed[1]);     
    
    return true;
  }
  
  double* observed;

};


struct AlignmentError2D3D {
  AlignmentError2D3D(double* observed_in): observed(observed_in) {}

  template <typename T>
  bool operator()(const T* const camera_extrinsic,
                  const T* const point,
                  T* residuals) const {
                  
    // camera_extrinsic[0,1,2] are the angle-axis rotation.
    T p[3];
    
    //ceres::AngleAxisRotatePoint(camera_extrinsic, point, p);
    T x = camera_extrinsic[0];
    T y = camera_extrinsic[1];
    T z = camera_extrinsic[2];
    T x2 = x*x;
    T y2 = y*y;
    T z2 = z*z;    
    T w2 = T(1.0) - x2 - y2 - z2;
    T w  = sqrt(w2);
    
    p[0] = point[0]*(w2 + x2 - y2 - z2) - point[1]*(T(2.0)*w*z - T(2.0)*x*y) + point[2]*(T(2.0)*w*y + T(2.0)*x*z);
    p[1] = point[1]*(w2 - x2 + y2 - z2) + point[0]*(T(2.0)*w*z + T(2.0)*x*y) - point[2]*(T(2.0)*w*x - T(2.0)*y*z);
    p[2] = point[2]*(w2 - x2 - y2 + z2) - point[0]*(T(2.0)*w*y - T(2.0)*x*z) + point[1]*(T(2.0)*w*x + T(2.0)*y*z);
    
    // camera_extrinsic[3,4,5] are the translation.
    p[0] += camera_extrinsic[3];
    p[1] += camera_extrinsic[4];
    p[2] += camera_extrinsic[5];
    
    // The error is the difference between the predicted and observed position.
    residuals[2] = (p[0] - T(observed[2]))*w;
    residuals[3] = (p[1] - T(observed[3]))*w;
    residuals[4] = (p[2] - T(observed[4]))*w;

    // project it
    p[0] = T(fx) * p[0] / p[2] + T(px);
    p[1] = T(fy) * p[1] / p[2] + T(py);
    
    // reprojection error
    residuals[0] = p[0] - T(observed[0]);
    residuals[1] = p[1] - T(observed[1]);     
    
    return true;
  }
  
  double* observed;

};

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    
  // usage: extrinsicBA3D(cameraQuatT,pointCloud, pointObserved)
  int nCam    = mxGetN(prhs[0]);
  int nPts    = mxGetN(prhs[1]);
  
  plhs[0] = mxCreateNumericMatrix(6, nCam, mxDOUBLE_CLASS, mxREAL);
  double* cameraQuatT = (double*)mxGetData(plhs[0]);
  
  plhs[1] = mxCreateNumericMatrix(3, nPts, mxDOUBLE_CLASS, mxREAL);
  double* pointCloud = (double*)mxGetData(plhs[1]);
  
  memcpy((void *)cameraQuatT, (void *)mxGetData(prhs[0]), 6*nCam*sizeof(double));
  memcpy((void *)pointCloud,  (void *)mxGetData(prhs[1]), 3*nPts*sizeof(double));
  
  double* pointObserved = mxGetPr(prhs[2]);
  
  
  double* camera_intrinsic = mxGetPr(prhs[3]);
  fx = *camera_intrinsic++;
  fy = *camera_intrinsic++;
  px = *camera_intrinsic++;
  py = *camera_intrinsic++;
  w  = *camera_intrinsic;

  // Create residuals for each observation in the bundle adjustment problem. The
  // parameters for cameras and points are added automatically.
  ceres::Problem problem;
  
  //ceres::LossFunction* loss_function = NULL; // squared loss
  ceres::LossFunction* loss_function = new ceres::HuberLoss(1.0);
  
  for (int ptID=0; ptID < nPts; ++ptID){
      for (int camID=0; camID < nCam; ++camID){
          double* cameraPtr = cameraQuatT + camID * 6;
          double* pointPtr  = pointCloud + ptID * 3;
          double* observePtr = pointObserved + 5*nCam*ptID + 5*camID;
                  
          if ( !(isnan(*cameraPtr) || isnan(*pointPtr) || isnan(*observePtr))){
          
              ceres::CostFunction* cost_function;
                      
              if (isnan(observePtr[2])){
                  cost_function = new ceres::AutoDiffCostFunction<AlignmentError2D,   2, 6, 3>(new AlignmentError2D(observePtr));
              }else{
                  cost_function = new ceres::AutoDiffCostFunction<AlignmentError2D3D, 5, 6, 3>(new AlignmentError2D3D(observePtr));
              }

              problem.AddResidualBlock(cost_function,
                                       loss_function,
                                       cameraPtr,
                                       pointPtr);
          }
      }
  }

  // Make Ceres automatically detect the bundle structure. Note that the
  // standard solver, SPARSE_NORMAL_CHOLESKY, also works fine but it is slower
  // for standard bundle adjustment problems.
  ceres::Solver::Options options;
  options.max_num_iterations = 200;  
  options.linear_solver_type = ceres::DENSE_SCHUR;
  options.ordering_type = ceres::SCHUR;
  options.minimizer_progress_to_stdout = true;

  //ceres::Solve(options, &problem, NULL);
  ceres::Solver::Summary summary;
  ceres::Solve(options, &problem, &summary);
  //std::cout << summary.FullReport() << std::endl;
}
