% we use ceres-solver-1.2.3

mex extrinsicBA2D3D.cpp -I/usr/local/include -I/usr/include/eigen3 -Iceres/ceres-solver-1.2.3/include/ -Lceres/ceres-bin/internal/ceres/ -lceres -lpthread -lglog -lgflags -lcholmod -lccolamd -lcamd -lcolamd -lamd -llapack -lblas -lcxsparse -lgomp -lprotobuf
