


// Convert from 3x3 (row-major) rotaton matrix to quaternion representation (w,x,y,z)
void rot2quat(ComputeT* rot, ComputeT* quat) {
  ComputeT trace = rot[0 * 3 + 0] + rot[1 * 3 + 1] + rot[2 * 3 + 2];
  if ( trace > 0 ) { 
    ComputeT s = 0.5f / sqrtf(trace + 1.0f);
    quat[0] = 0.25f / s;
    quat[1] = ( rot[2 * 3 + 1] - rot[1 * 3 + 2] ) * s;
    quat[2] = ( rot[0 * 3 + 2] - rot[2 * 3 + 0] ) * s;
    quat[3] = ( rot[1 * 3 + 0] - rot[0 * 3 + 1] ) * s;
  } else {
    if ( rot[0 * 3 + 0] > rot[1 * 3 + 1] && rot[0 * 3 + 0] > rot[2 * 3 + 2] ) {
      ComputeT s = 2.0f * sqrtf( 1.0f + rot[0 * 3 + 0] - rot[1 * 3 + 1] - rot[2 * 3 + 2]);
      quat[0] = (rot[2 * 3 + 1] - rot[1 * 3 + 2] ) / s;
      quat[1] = 0.25f * s;
      quat[2] = (rot[0 * 3 + 1] + rot[1 * 3 + 0] ) / s;
      quat[3] = (rot[0 * 3 + 2] + rot[2 * 3 + 0] ) / s;
    } else if (rot[1 * 3 + 1] > rot[2 * 3 + 2]) {
      ComputeT s = 2.0f * sqrtf( 1.0f + rot[1 * 3 + 1] - rot[0 * 3 + 0] - rot[2 * 3 + 2]);
      quat[0] = (rot[0 * 3 + 2] - rot[2 * 3 + 0] ) / s;
      quat[1] = (rot[0 * 3 + 1] + rot[1 * 3 + 0] ) / s;
      quat[2] = 0.25f * s;
      quat[3] = (rot[1 * 3 + 2] + rot[2 * 3 + 1] ) / s;
    } else {
      ComputeT s = 2.0f * sqrtf( 1.0f + rot[2 * 3 + 2] - rot[0 * 3 + 0] - rot[1 * 3 + 1] );
      quat[0] = (rot[1 * 3 + 0] - rot[0 * 3 + 1] ) / s;
      quat[1] = (rot[0 * 3 + 2] + rot[2 * 3 + 0] ) / s;
      quat[2] = (rot[1 * 3 + 2] + rot[2 * 3 + 1] ) / s;
      quat[3] = 0.25f * s;
    }
  }
}

__global__ void Kernel_genLabels(ComputeT * objLoc, ComputeT * objQuat, 
                                 ComputeT voxXMin, ComputeT voxYMin, ComputeT voxZMin,
                                 ComputeT outXSize, ComputeT outYSize, ComputeT outZSize,
                                 ComputeT recFieldXSize, ComputeT recFieldYSize, ComputeT recFieldZSize,
                                 ComputeT recFieldXGap, ComputeT recFieldYGap, ComputeT recFieldZGap,
                                 StorageT * rotLabels, StorageT * transLabels) {
  size_t N = size_t(outXSize) * size_t(outYSize) * size_t(outZSize);
  const size_t idxBase = size_t(CUDA_NUM_THREADS) * size_t(blockIdx.x) + size_t(threadIdx.x);
  if (idxBase >= N) return;

  // Get location in voxel grid coordinates
  int xGrid = floor(idxBase / (outYSize * outZSize));
  int yGrid = floor((idxBase - (xGrid * outYSize * outZSize)) / outZSize);
  int zGrid = idxBase - (xGrid * outYSize * outZSize) - (yGrid * outZSize);

  // Compute receptive field limits
  ComputeT recFieldXMin = voxXMin + xGrid * recFieldXGap;
  ComputeT recFieldYMin = voxYMin + yGrid * recFieldYGap;
  ComputeT recFieldZMin = voxZMin + zGrid * recFieldZGap;

  // Get center of receptive field
  ComputeT recFieldXLoc = recFieldXMin + recFieldXSize/2;
  ComputeT recFieldYLoc = recFieldYMin + recFieldYSize/2;
  ComputeT recFieldZLoc = recFieldZMin + recFieldZSize/2;

  //printf("%d %d %d %f %f %f %f %f %f\n", xGrid, yGrid, zGrid, voxYMin, recFieldYGap, objLoc[1], recFieldYMin, recFieldYSize, recFieldYLoc);

  // Compute and assign translation
  transLabels[0 * N + idxBase] = GPUCompute2StorageT(objLoc[0] - recFieldXLoc);
  transLabels[1 * N + idxBase] = GPUCompute2StorageT(objLoc[1] - recFieldYLoc);
  transLabels[2 * N + idxBase] = GPUCompute2StorageT(objLoc[2] - recFieldZLoc);

  // Assign rotation
  rotLabels[0 * N + idxBase] = GPUCompute2StorageT(objQuat[0]);
  rotLabels[1 * N + idxBase] = GPUCompute2StorageT(objQuat[1]);
  rotLabels[2 * N + idxBase] = GPUCompute2StorageT(objQuat[2]);
  rotLabels[3 * N + idxBase] = GPUCompute2StorageT(objQuat[3]);
}

void genLabels(ComputeT * objPose, 
               ComputeT voxXMin, ComputeT voxYMin, ComputeT voxZMin, 
               ComputeT outXSize, ComputeT outYSize, ComputeT outZSize,
               ComputeT recFieldXSize, ComputeT recFieldYSize, ComputeT recFieldZSize,
               ComputeT recFieldXGap, ComputeT recFieldYGap, ComputeT recFieldZGap,
               StorageT * rotLabels, StorageT * transLabels) {

  // Convert object pose to location/quaternion representation
  ComputeT objLocCPU[3] = {objPose[0 * 4 + 3], objPose[1 * 4 + 3], objPose[2 * 4 + 3]};
  ComputeT objRot[3 * 3] = {objPose[0 * 4 + 0], objPose[0 * 4 + 1], objPose[0 * 4 + 2],
                            objPose[1 * 4 + 0], objPose[1 * 4 + 1], objPose[1 * 4 + 2],
                            objPose[2 * 4 + 0], objPose[2 * 4 + 1], objPose[2 * 4 + 2]};
  ComputeT objQuatCPU[4];
  rot2quat(objRot, objQuatCPU);

  // Copy location/quaternion to GPU
  ComputeT * objLocGPU; 
  checkCUDA(__LINE__, cudaMalloc(&objLocGPU, 3 * sizeofComputeT));
  checkCUDA(__LINE__, cudaMemcpy(objLocGPU, objLocCPU, 3 * sizeofComputeT, cudaMemcpyHostToDevice));
  ComputeT * objQuatGPU; 
  checkCUDA(__LINE__, cudaMalloc(&objQuatGPU, 4 * sizeofComputeT));
  checkCUDA(__LINE__, cudaMemcpy(objQuatGPU, objQuatCPU, 4 * sizeofComputeT, cudaMemcpyHostToDevice));
  
  // Call kernel function to get labels
  size_t N = outXSize * outYSize * outZSize;
  Kernel_genLabels<<<CUDA_GET_BLOCKS(N), CUDA_NUM_THREADS>>>(objLocGPU, objQuatGPU,
                                                             voxXMin,       voxYMin,       voxZMin, 
                                                             outXSize,      outYSize,      outZSize,
                                                             recFieldXSize, recFieldYSize, recFieldZSize,
                                                             recFieldXGap,  recFieldYGap,  recFieldZGap,
                                                             rotLabels, transLabels);
  checkCUDA(__LINE__, cudaGetLastError());
}
































