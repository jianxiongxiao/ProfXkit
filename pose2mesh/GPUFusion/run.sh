#!/bin/bash

if uname | grep -q Darwin; then
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib
elif uname | grep -q Linux; then
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64
fi

./GPUfusion depthRaw.tensor camera.intrinsics.depth.tensor cameraRtW2C.depth.tensor outTSDF.tensor -0.05 0.03 -0.15 0.03 0.33 0.42 0.002 0.006
