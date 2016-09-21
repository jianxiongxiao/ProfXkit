#!/bin/bash

if uname | grep -q Darwin; then
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cudnn/v5/lib
elif uname | grep -q Linux; then
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cudnn/v5/lib64
fi


./marvin test apc.json apc_snapshot_40.marvin cls_pred,r_pred,t_pred testout/cls_pred.tensor,testout/r_pred.tensor,testout/t_pred.tensor 1

