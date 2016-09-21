#include "render.hpp"
#include "label.hpp"

__global__ void Kernel_integrate(
        bool flipVertical4render,
        unsigned int xSize, unsigned int ySize, unsigned int zSize, 
        ComputeT xMin, ComputeT yMin, ComputeT zMin, 
        ComputeT unit, ComputeT margin, 
        unsigned int width, unsigned int height, 
        const float* depth, const ComputeT* pose, const ComputeT* intrinsics, StorageT *tsdf, uint8_t *weight, StorageT *label) {

    unsigned int x = blockIdx.x;
    unsigned int y = threadIdx.x;

    ComputeT xWorld = xMin + x * unit;
    ComputeT yWorld = yMin + y * unit;
    ComputeT zWorld = zMin;

    ComputeT xCamera = pose[0] * xWorld + pose[1] * yWorld + pose[2] *zWorld + pose[3];
    ComputeT yCamera = pose[4] * xWorld + pose[5] * yWorld + pose[6] *zWorld + pose[7];
    ComputeT zCamera = pose[8] * xWorld + pose[9] * yWorld + pose[10] *zWorld + pose[11];

    ComputeT xDelta = pose[2] * unit;
    ComputeT yDelta = pose[6] * unit;
    ComputeT zDelta = pose[10] * unit;

    unsigned int idx_offset = (x * ySize + y) * zSize;

    for (unsigned int z = 0; z < zSize; ++z, xCamera += xDelta, yCamera += yDelta, zCamera += zDelta){

        ComputeT xOzCamera = xCamera / zCamera;
        ComputeT yOzCamera = yCamera / zCamera;

        int px = roundf(intrinsics[0] * xOzCamera + intrinsics[2]);
        int py = roundf(intrinsics[4] * yOzCamera + intrinsics[5]);

        if (px < 0 || px >= width || py < 0 || py >= height) continue;

        float p_depth = *(depth + (flipVertical4render? (height-1 - py): py) * width + px);

        if (p_depth == 0.0) continue;

        ComputeT diff = ((ComputeT)p_depth - zCamera) * sqrtf(1.0 + xOzCamera * xOzCamera + yOzCamera * yOzCamera);

        if(diff > -margin){
            ComputeT v_new = fminf(1.0, diff/margin); //tsdf

            unsigned int idx = idx_offset + z;

            if (diff <= 0) label = GPUCompute2StorageT(1.0);

            v_new = 1.0 - fabs(v_new); // 1-tdf // comment this out if you want to use tsdf

            uint8_t w  = weight[idx];
            ComputeT v = GPUStorage2ComputeT(tsdf[idx]);

            tsdf[idx] = GPUCompute2StorageT(fmin(fmax((ComputeT(w)*v + v_new)/(ComputeT(w + 1)), -1.f), 1.f));
            weight[idx] = min(w+1,254);
        }
    }
}



__global__ void Kernel_label(
                StorageT *tsdfGPU, 
                unsigned int xOutRes, unsigned int yOutRes, unsigned int zOutRes,
                unsigned int xSize, unsigned int ySize, unsigned int zSize,
                unsigned int xRF, unsigned int yRF, unsigned int zRF,
                unsigned int xRG, unsigned int yRG, unsigned int zRG,
                unsigned int xObjSize, unsigned int yObjSize, unsigned int zObjSize,
                StorageT *cls_labelGPU, 
                StorageT *r_weightGPU, 
                StorageT *t_weightGPU,
                StorageT *objCoord_weightGPU){

    unsigned int x = blockIdx.x;
    unsigned int y = threadIdx.x;
    unsigned int i_base = ( x * yOutRes + y ) * zOutRes;
    unsigned int offset = xOutRes * yOutRes * zOutRes;
    for (unsigned int z = 0; z < zOutRes; ++z){
        unsigned int count = 0;
        for (unsigned int xO=xRG*x; xO<xRG*x+xRF; ++xO){
            for (unsigned int yO=yRG*y; yO<yRG*y+yRF; ++yO){
                for (unsigned int zO=zRG*z; zO<zRG*z+zRF; ++zO){
                    unsigned int iO = (xO * ySize + yO) * zSize + zO;
                    count += GPUStorage2ComputeT(tsdfGPU[iO])>(0);
                }
            }
        }
        // if (count>0) printf("%d ",count); //good debuging to output histogram for cutting
        // StorageT result = (count*1000>xRF*yRF*zRF)? (GPUCompute2StorageT(1)) : (GPUCompute2StorageT(0));
        StorageT result = (count>1000)? (GPUCompute2StorageT(1)) : (GPUCompute2StorageT(0));
        unsigned int i_base_z = i_base+z;
        if (cls_labelGPU!=NULL) cls_labelGPU[i_base_z] = result;

        StorageT r_weight_val = (count>1000)? (GPUCompute2StorageT(100)) : (GPUCompute2StorageT(0));
        r_weightGPU[i_base_z] = r_weight_val;
        r_weightGPU[i_base_z+offset] = r_weight_val;
        r_weightGPU[i_base_z+offset+offset] = r_weight_val;
        r_weightGPU[i_base_z+offset+offset+offset] = r_weight_val;

        StorageT objCoord_weight_val = (count>1000)? (GPUCompute2StorageT(50)) : (GPUCompute2StorageT(0));
        for (int tmp_i = 0; tmp_i < (xObjSize*yObjSize*zObjSize); tmp_i++) {
            objCoord_weightGPU[i_base_z + offset*tmp_i] = objCoord_weight_val;
        }

        // StorageT t_weight_val = (count*1000>xRF*yRF*zRF)? (GPUCompute2StorageT(50)) : (GPUCompute2StorageT(0));
        StorageT t_weight_val = (count>1000)? (GPUCompute2StorageT(1000)) : (GPUCompute2StorageT(0));
        t_weightGPU[i_base_z] = t_weight_val;
        t_weightGPU[i_base_z+offset] = t_weight_val;
        t_weightGPU[i_base_z+offset+offset] = t_weight_val;
    }
}

__global__ void Kernel_labelObjCoords(
                int xOutRes, int yOutRes, int zOutRes,
                float xOutRF, float yOutRF, float zOutRF,
                float xOutRG, float yOutRG, float zOutRG,
                int xObjSize, int yObjSize, int zObjSize,
                float xMin, float yMin, float zMin,
                float * objCoordsGPU,
                StorageT * objCoord_labelGPU) {

    unsigned int x = blockIdx.x;
    unsigned int y = threadIdx.x;
    for (unsigned int z = 0; z < zOutRes; z++) {

        float xCoord = xMin + xOutRG * x + xOutRF/2;
        float yCoord = yMin + yOutRG * y + yOutRF/2;
        float zCoord = zMin + zOutRG * z + zOutRF/2;

        // Find closest object coord and set label
        int objCoordLabel = 0;
        float closestDist = 100;
        for (int i = 0; i < xObjSize * yObjSize * zObjSize; i++) {

            float xObjCoord = objCoordsGPU[0 * xObjSize * yObjSize * zObjSize + i];
            float yObjCoord = objCoordsGPU[1 * xObjSize * yObjSize * zObjSize + i];
            float zObjCoord = objCoordsGPU[2 * xObjSize * yObjSize * zObjSize + i];

            float currDist = sqrtf((xCoord - xObjCoord) * (xCoord - xObjCoord) + 
                                   (yCoord - yObjCoord) * (yCoord - yObjCoord) + 
                                   (zCoord - zObjCoord) * (zCoord - zObjCoord));
            if (currDist < closestDist) {
                objCoordLabel = i;
                closestDist = currDist;
            }
        }
        objCoord_labelGPU[( x * yOutRes + y ) * zOutRes + z] = GPUCompute2StorageT(objCoordLabel);

    }
}

__global__ void Kernel_genObjCoords(
                float xObjMin, float yObjMin, float zObjMin,
                float xObjMax, float yObjMax, float zObjMax,
                int xObjSize, int yObjSize, int zObjSize,
                float * objectRtGPU, float * objCoordsGPU) {

    unsigned int x = blockIdx.x;
    unsigned int y = threadIdx.x;
    for (unsigned int z = 0; z < zObjSize; z++) {
        int objCoordIDX = ( x * yObjSize + y ) * zObjSize + z;

        float xUnit = (xObjMax - xObjMin)/((float) xObjSize);
        float yUnit = (yObjMax - yObjMin)/((float) yObjSize);
        float zUnit = (zObjMax - zObjMin)/((float) zObjSize);

        float xCoord = (((float) x) + 0.5f) * xUnit + xObjMin;
        float yCoord = (((float) y) + 0.5f) * yUnit + yObjMin;
        float zCoord = (((float) z) + 0.5f) * zUnit + zObjMin;

        objCoordsGPU[0 * xObjSize * yObjSize * zObjSize + objCoordIDX] = xCoord * objectRtGPU[0] + yCoord * objectRtGPU[1] + zCoord * objectRtGPU[2] + objectRtGPU[3];
        objCoordsGPU[1 * xObjSize * yObjSize * zObjSize + objCoordIDX] = xCoord * objectRtGPU[4] + yCoord * objectRtGPU[5] + zCoord * objectRtGPU[6] + objectRtGPU[7];
        objCoordsGPU[2 * xObjSize * yObjSize * zObjSize + objCoordIDX] = xCoord * objectRtGPU[8] + yCoord * objectRtGPU[9] + zCoord * objectRtGPU[10] + objectRtGPU[11];
    }
}

void quaternion2matrix(float* quaternion_wxyz, float* rotation_matrix, int numofcol){
    rotation_matrix[0 * numofcol + 0] = 1.0f - 2.0f * quaternion_wxyz[2] * quaternion_wxyz[2] - 2.0f * quaternion_wxyz[3] * quaternion_wxyz[3];
    rotation_matrix[0 * numofcol + 1] = 2.0f * quaternion_wxyz[1] * quaternion_wxyz[2] - 2.0f * quaternion_wxyz[3] * quaternion_wxyz[0];
    rotation_matrix[0 * numofcol + 2] = 2.0f * quaternion_wxyz[1] * quaternion_wxyz[3] + 2.0f * quaternion_wxyz[2] * quaternion_wxyz[0];
    rotation_matrix[1 * numofcol + 0] = 2.0f * quaternion_wxyz[1] * quaternion_wxyz[2] + 2.0f * quaternion_wxyz[3] * quaternion_wxyz[0];
    rotation_matrix[1 * numofcol + 1] = 1.0f - 2.0f * quaternion_wxyz[1] * quaternion_wxyz[1] - 2.0f * quaternion_wxyz[3] * quaternion_wxyz[3];
    rotation_matrix[1 * numofcol + 2] = 2.0f * quaternion_wxyz[2] * quaternion_wxyz[3] - 2.0f * quaternion_wxyz[1] * quaternion_wxyz[0];
    rotation_matrix[2 * numofcol + 0] = 2.0f * quaternion_wxyz[1] * quaternion_wxyz[3] - 2.0f * quaternion_wxyz[2] * quaternion_wxyz[0];
    rotation_matrix[2 * numofcol + 1] = 2.0f * quaternion_wxyz[2] * quaternion_wxyz[3] + 2.0f * quaternion_wxyz[1] * quaternion_wxyz[0];
    rotation_matrix[2 * numofcol + 2] = 1.0f - 2.0f * quaternion_wxyz[1] * quaternion_wxyz[1] - 2.0f * quaternion_wxyz[2] * quaternion_wxyz[2];
}

void concat2Rt(float* RtA, float* RtB, float* res){
    res[0] = RtA[0] * RtB[0] + RtA[1] * RtB[4] + RtA[2] * RtB[8];   res[1] = RtA[0] * RtB[1] + RtA[1] * RtB[5] + RtA[2] * RtB[9];   res[2] = RtA[0] * RtB[2] + RtA[1] * RtB[6] + RtA[2] * RtB[10];
    res[4] = RtA[4] * RtB[0] + RtA[5] * RtB[4] + RtA[6] * RtB[8];   res[5] = RtA[4] * RtB[1] + RtA[5] * RtB[5] + RtA[6] * RtB[9];   res[6] = RtA[4] * RtB[2] + RtA[5] * RtB[6] + RtA[6] * RtB[10];
    res[8] = RtA[8] * RtB[0] + RtA[9] * RtB[4] + RtA[10]* RtB[8];   res[9] = RtA[8] * RtB[1] + RtA[9] * RtB[5] + RtA[10]* RtB[9];   res[10]= RtA[8] * RtB[2] + RtA[9] * RtB[6] + RtA[10]* RtB[10];

    res[3] = RtA[3] + RtA[0] * RtB[3] + RtA[1] * RtB[7] + RtA[2] * RtB[11];
    res[7] = RtA[7] + RtA[4] * RtB[3] + RtA[5] * RtB[7] + RtA[6] * RtB[11];
    res[11]= RtA[11]+ RtA[8] * RtB[3] + RtA[9] * RtB[7] + RtA[10]* RtB[11];
}

void concatKRt(float* K, float* Rt, float* res){
    res[0] = K[0] * Rt[0] + K[1] * Rt[4] + K[2] * Rt[8];    res[1] = K[0] * Rt[1] + K[1] * Rt[5] + K[2] * Rt[9];    res[2] = K[0] * Rt[2] + K[1] * Rt[6] + K[2] * Rt[10];    res[3] = K[0] * Rt[3] + K[1] * Rt[7] + K[2] * Rt[11];
    res[4] = K[3] * Rt[0] + K[4] * Rt[4] + K[5] * Rt[8];    res[5] = K[3] * Rt[1] + K[4] * Rt[5] + K[5] * Rt[9];    res[6] = K[3] * Rt[2] + K[4] * Rt[6] + K[5] * Rt[10];    res[7] = K[3] * Rt[3] + K[4] * Rt[7] + K[5] * Rt[11];
    res[8] = K[6] * Rt[0] + K[7] * Rt[4] + K[8] * Rt[8];    res[9] = K[6] * Rt[1] + K[7] * Rt[5] + K[8] * Rt[9];    res[10]= K[6] * Rt[2] + K[7] * Rt[6] + K[8] * Rt[10];    res[11]= K[6] * Rt[3] + K[7] * Rt[7] + K[8] * Rt[11];
}

void transpose3x4(float* projection){
    float q[12];
    for (int i=0;i<12;++i) q[i] = projection[i];

    projection[0] = q[0]; projection[1] = q[4]; projection[2] = q[8]; 
    projection[3] = q[1]; projection[4] = q[5]; projection[5] = q[9]; 
    projection[6] = q[2]; projection[7] = q[6]; projection[8] = q[10]; 
    projection[9] = q[3]; projection[10]= q[7]; projection[11]= q[11]; 
}

class APCDataLayer : public DataLayer {

    std::future<void> lock;
    int epoch_prefetch;

    unsigned int xSize;
    unsigned int ySize;
    unsigned int zSize;


    StorageT* cacheGPU;
    StorageT* cls_labelGPU;
    StorageT* r_labelGPU;
    StorageT* r_weightGPU;
    StorageT* t_labelGPU;
    StorageT* t_weightGPU;
    StorageT* objCoord_labelGPU;
    StorageT* objCoord_weightGPU;

    uint8_t* weightGPU;
    float* depthGPU;

    Mesh3D* pModel;
    Tensor<ComputeT>* intrinsicsCPU;
    Tensor<ComputeT>* extrinsicsCPU;

    ComputeT* intrinsicsGPU;
    ComputeT* extrinsicsGPU;

    std::uniform_real_distribution<ComputeT>* uDistribution;
public:
    bool fixedRotation;
    bool fixedTranslation;
    bool saveFiles;
    std::string model;
    std::string intrinsics;
    std::string extrinsics;
    int batch_size;
    ComputeT xMin;
    ComputeT xMax;
    ComputeT yMin;
    ComputeT yMax;
    ComputeT zMin;
    ComputeT zMax;
    ComputeT unit;
    ComputeT margin;
    unsigned int width;
    unsigned int height;

    int xOutRes;
    int yOutRes;
    int zOutRes;
    float xOutRF;
    float yOutRF;
    float zOutRF;
    float xOutRG;
    float yOutRG;
    float zOutRG;

    const int xObjSize = 2;
    const int yObjSize = 3;
    const int zObjSize = 5;
    float xObjMin;
    float xObjMax;
    float yObjMin;
    float yObjMax;
    float zObjMin;
    float zObjMax;
    float* objCoordsGPU; 
    float* objectRtGPU; 

    int numofitems(){
        return 1000000;
    };

    APCDataLayer(std::string name_, Phase phase_, int batch_size_): DataLayer(name_), batch_size(batch_size_){
        phase = phase_;
        init();
    };
    APCDataLayer(JSON* json){
        SetOrDie(json, name)
        SetValue(json, phase,      Training)
        SetOrDie(json, model  )
        SetOrDie(json, intrinsics  )
        SetOrDie(json, extrinsics  )
        SetValue(json, batch_size, 2)

        SetValue(json, random, true)
        SetValue(json, saveFiles, false)
        SetValue(json, fixedRotation, false)
        SetValue(json, fixedTranslation, false)

        SetValue(json, xMin,  1.48)
        SetValue(json, xMax,  1.85)
        SetValue(json, yMin, -0.15)
        SetValue(json, yMax,  0.13)
        SetValue(json, zMin,  0.82)
        SetValue(json, zMax,  1.00)
        SetValue(json, unit,  0.0025)
        SetValue(json, margin,0.0100)
        SetValue(json, width, 640)
        SetValue(json, height,480)

        SetOrDie(json, xOutRes)
        SetOrDie(json, yOutRes)
        SetOrDie(json, zOutRes)
        SetOrDie(json, xOutRF)
        SetOrDie(json, yOutRF)
        SetOrDie(json, zOutRF)
        SetOrDie(json, xOutRG)
        SetOrDie(json, yOutRG)
        SetOrDie(json, zOutRG)

        init();
    };
    ~APCDataLayer(){
        if (pModel != NULL) delete pModel;
        if (intrinsicsCPU != NULL) delete intrinsicsCPU;
        if (extrinsicsCPU != NULL) delete extrinsicsCPU;

        // if (xLabelCenters!=NULL) delete [] xLabelCenters;
        // if (yLabelCenters!=NULL) delete [] yLabelCenters;
        // if (zLabelCenters!=NULL) delete [] zLabelCenters;

        if (cacheGPU!=NULL) checkCUDA(__LINE__, cudaFree(cacheGPU));

        if (weightGPU!=NULL) checkCUDA(__LINE__, cudaFree(weightGPU));
        if (depthGPU!=NULL) checkCUDA(__LINE__, cudaFree(depthGPU));
        if (extrinsicsGPU!=NULL) checkCUDA(__LINE__, cudaFree(extrinsicsGPU));
        if (intrinsicsGPU!=NULL) checkCUDA(__LINE__, cudaFree(intrinsicsGPU));

        if (cls_labelGPU!=NULL) checkCUDA(__LINE__, cudaFree(cls_labelGPU));
        if (r_labelGPU!=NULL) checkCUDA(__LINE__, cudaFree(r_labelGPU));
        if (r_weightGPU!=NULL) checkCUDA(__LINE__, cudaFree(r_weightGPU));
        if (t_labelGPU!=NULL) checkCUDA(__LINE__, cudaFree(t_labelGPU));
        if (t_weightGPU!=NULL) checkCUDA(__LINE__, cudaFree(t_weightGPU));  
        if (objCoord_labelGPU!=NULL) checkCUDA(__LINE__, cudaFree(objCoord_labelGPU));
        if (objCoord_weightGPU!=NULL) checkCUDA(__LINE__, cudaFree(objCoord_weightGPU));       
    };

    void init(){
        epoch_prefetch  = 0;

        cacheGPU = NULL;
        cls_labelGPU = NULL;
        r_labelGPU = NULL;
        r_weightGPU = NULL;
        t_labelGPU = NULL;
        t_weightGPU = NULL;
        objCoord_labelGPU = NULL;
        objCoord_weightGPU = NULL;

        weightGPU = NULL;

        depthGPU = NULL;
        extrinsicsGPU = NULL;
        intrinsicsGPU = NULL;

        pModel = NULL;
        intrinsicsCPU = NULL;
        extrinsicsCPU = NULL;

        train_me = false;
        std::cout<<"APCDataLayer "<<name<<" loading data: "<<std::endl;
        
        pModel = new Mesh3D();
        pModel->readOFF(model);

        getObjLimits(pModel);

        intrinsicsCPU = new Tensor<ComputeT>(intrinsics);
        extrinsicsCPU = new Tensor<ComputeT>(extrinsics);

        uDistribution = new std::uniform_real_distribution<ComputeT>(0,1);
    };    

    void clearTSDF(size_t batchID){
        //GPU_set_negones(xSize*ySize*zSize, cacheGPU+batchID*xSize*ySize*zSize*sizeofStorageT);
        GPU_set_zeros(xSize*ySize*zSize, cacheGPU+batchID*xSize*ySize*zSize);
        GPU_set_zeros(xSize*ySize*zSize, cls_labelGPU+batchID*xSize*ySize*zSize);
        checkCUDA(__LINE__, cudaMemset(weightGPU, 0, sizeof(uint8_t) * xSize*ySize*zSize));
    };

    void integrateTSDF(bool flipVertical4render,size_t batchID, size_t poseID){
        Kernel_integrate<<<xSize,ySize>>>(flipVertical4render,xSize, ySize, zSize, xMin, yMin, zMin, unit, margin, width, height, depthGPU, extrinsicsGPU+3*4*poseID, intrinsicsGPU, cacheGPU+batchID*xSize*ySize*zSize, weightGPU, cls_labelGPU+batchID*xSize*ySize*zSize);
    };


    void getObjLimits(Mesh3D * pModel) {

        // Get bounding box of object (assume object is zero centered)
        xObjMin = 0;
        xObjMax = 0;
        yObjMin = 0;
        yObjMax = 0;
        zObjMin = 0;
        zObjMax = 0;
        for (int i = 0; i < pModel->vertex.size(); ++i) {
            if (pModel->vertex[i].x < xObjMin) xObjMin = pModel->vertex[i].x;
            if (pModel->vertex[i].x > xObjMax) xObjMax = pModel->vertex[i].x;
            if (pModel->vertex[i].y < yObjMin) yObjMin = pModel->vertex[i].y;
            if (pModel->vertex[i].y > yObjMax) yObjMax = pModel->vertex[i].y;
            if (pModel->vertex[i].z < zObjMin) zObjMin = pModel->vertex[i].z;
            if (pModel->vertex[i].z > zObjMax) zObjMax = pModel->vertex[i].z;
        }
        std::cout << xObjMin << " " << xObjMax << std::endl;
        std::cout << yObjMin << " " << yObjMax << std::endl;
        std::cout << zObjMin << " " << zObjMax << std::endl;

        // // Divide bounding box into 5x5x5 grid (specify unit dimensions)
        // float xBboxUnit = (xObjMax - xObjMin)/xObjSize;
        // float yBboxUnit = (yObjMax - yObjMin)/yObjSize;
        // float zBboxUnit = (zObjMax - zObjMin)/zObjSize;

        // // Compute voxel centers of 5x5x5 grid
        // for (int i = 0; i < 5; i++) {
        //     xLabelCenters[i] = xObjMin + (((float) i) + 0.5f) * xBboxUnit;
        //     yLabelCenters[i] = yObjMin + (((float) i) + 0.5f) * yBboxUnit;
        //     zLabelCenters[i] = zObjMin + (((float) i) + 0.5f) * zBboxUnit;
        // }

        // // Visualize 5x5x5 grid labels of points in model (save to point cloud)
        // FILE *fp = fopen("test.ply", "w");
        // fprintf(fp, "ply\n");
        // fprintf(fp, "format binary_little_endian 1.0\n");
        // fprintf(fp, "element vertex %d\n", (int)(pModel->vertex.size()));
        // fprintf(fp, "property float x\n");
        // fprintf(fp, "property float y\n");
        // fprintf(fp, "property float z\n");
        // fprintf(fp, "property uchar red\n");
        // fprintf(fp, "property uchar green\n");
        // fprintf(fp, "property uchar blue\n");
        // fprintf(fp, "end_header\n");

        // for (int i = 0; i < pModel->vertex.size(); ++i) {
        //     float float_x = pModel->vertex[i].x;
        //     float float_y = pModel->vertex[i].y;
        //     float float_z = pModel->vertex[i].z;
        //     fwrite(&float_x, sizeof(float), 1, fp);
        //     fwrite(&float_y, sizeof(float), 1, fp);
        //     fwrite(&float_z, sizeof(float), 1, fp);

        //     float labelx = floor((float_x - xObjMin)/xBboxUnit);
        //     float labely = floor((float_y - yObjMin)/yBboxUnit);
        //     float labelz = floor((float_z - zLimitMin)/zBboxUnit);
        //     // float objCoordLabel = labelz * 5 * 5 + labely * 5 + labelx;
        //     unsigned char r = (unsigned char) round(255.0f/xBboxDiv * (labelx + 0.5f));
        //     unsigned char g = (unsigned char) round(255.0f/yBboxDiv * (labely + 0.5f));
        //     unsigned char b = (unsigned char) round(255.0f/zBboxDiv * (labelz + 0.5f));
        //     fwrite(&r, sizeof(unsigned char), 1, fp);
        //     fwrite(&g, sizeof(unsigned char), 1, fp);
        //     fwrite(&b, sizeof(unsigned char), 1, fp);
        // }
        // fclose(fp);

    }


    void prefetch(){
        checkCUDA(__LINE__,cudaSetDevice(GPU));

        for (size_t batchID=0;batchID<batch_size;++batchID){

            // tic();

            clearTSDF(batchID);

            float objectRt[12];
            // generate object pose: assume object is centered at (0,0,0), gravity = +y, i.e. object is pointing up to -y

            float quaternion[4];
            float norm = 0;
            for(int i=0;i<4;++i){
                quaternion[i] = (*uDistribution)(rng);
                norm += quaternion[i] * quaternion[i];
            }
            norm = sqrt(norm);
            for(int i=0;i<4;++i){
                quaternion[i] /= norm;
            }


            float xMinNow = xMin + 0.05;
            float xMaxNow = xMax - 0.05;
            objectRt[3] = (*uDistribution)(rng)*(xMaxNow-xMinNow)+xMinNow;

            float yMinNow = yMin + 0.05;
            float yMaxNow = yMax - 0.05;
            objectRt[7] = (*uDistribution)(rng)*(yMaxNow-yMinNow)+yMinNow;

            float zMinNow = zMin + 0.05;
            float zMaxNow = zMax - 0.05;
            objectRt[11]= (*uDistribution)(rng)*(zMaxNow-zMinNow)+zMinNow;


            //debug: never rotate or move
            if (fixedRotation){
                quaternion[0] = 1;
                quaternion[1] = 0;
                quaternion[2] = 0;
                quaternion[3] = 0;
            }
            if (fixedTranslation){
                objectRt[3] = 0.5*(xMaxNow-xMinNow)+xMinNow;
                objectRt[7] = 0.5*(yMaxNow-yMinNow)+yMinNow;
                objectRt[11]= 0.5*(zMaxNow-zMinNow)+zMinNow;
            }

            quaternion2matrix(quaternion, objectRt, 4);


            //debug
            // std::cout<<"objectRt:"<<std::endl;
            // for(int r=0;r<3;++r){
            //     for(int c=0;c<4;++c){
            //         std::cout<<objectRt[r*4+c]<<" ";
            //     }
            //     std::cout<<std::endl;
            // }

            // toc();
            // tic();
            // render and integrate

            for (size_t poseID=0;poseID<extrinsicsCPU->dim[0] ;++poseID){
            // for (size_t poseID=0;poseID<1 ;++poseID){

                //size_t poseID = 6;

                // rendering
                float projection[12];
                float concatRt[12];
                concat2Rt(extrinsicsCPU->CPUmem+3*4*poseID, objectRt, concatRt);
                concatKRt(intrinsicsCPU->CPUmem, concatRt, projection);

                /*
                std::cout<<"extrinsics:"<<std::endl;
                for(int r=0;r<3;++r){
                    for(int c=0;c<4;++c){
                        std::cout<<extrinsicsCPU->CPUmem[3*4*poseID+r*4+c]<<" ";
                    }
                    std::cout<<std::endl;
                }

                std::cout<<"projection:"<<std::endl;
                for(int r=0;r<3;++r){
                    for(int c=0;c<4;++c){
                        std::cout<<projection[r*4+c]<<" ";
                    }
                    std::cout<<std::endl;
                }
                */

                transpose3x4(projection);

                float* depthCPU = renderDepth(pModel, projection, width, height);
                checkCUDA(__LINE__, cudaMemcpy(depthGPU, depthCPU, width*height*sizeof(float), cudaMemcpyHostToDevice) );
                delete [] depthCPU;

                
                //debug
                if (saveFiles)
                {
                    std::vector<int> dimDepth;
                    dimDepth.push_back(1);
                    dimDepth.push_back(height);
                    dimDepth.push_back(width);
                    Tensor<float>* t = new Tensor<float>(dimDepth);
                    t->readGPU(depthGPU);
                    std::string fname = "debug/"+std::to_string(counter)+"_depth_"+std::to_string(batchID)+"_"+std::to_string(poseID)+".tensor";
                    FILE* fp = fopen(fname.c_str(),"wb");
                    t->write(fp);
                    fclose(fp);
                    delete t;
                }
                
                // integrate
                integrateTSDF(true, batchID, poseID);
            }

            // toc();
            // tic();
            // Get size of object in TSDF volume
            // StorageT* cacheCPU = new StorageT[batch_size * xSize * ySize * zSize];
            // cudaMemcpy(cacheCPU, cacheGPU, batch_size * xSize * ySize * zSize * sizeof(StorageT), cudaMemcpyDeviceToHost);
            // checkCUDA(__LINE__, cudaGetLastError());
            // unsigned int objSize = 0;
            // for (int cache_i = batchID * xSize * ySize * zSize; cache_i < (batchID + 1) * xSize * ySize * zSize; cache_i++) {
            //     if (CPUStorage2ComputeT(cacheCPU[cache_i]) > 0.8)
            //         objSize++;
            // }
            // std::cout << objSize << std::endl;
            // unsigned int objSize = 500;
            // delete [] cacheCPU;

            // toc();
            // tic();


            checkCUDA(__LINE__, cudaMemcpy(objectRtGPU, objectRt, 12 * sizeof(float), cudaMemcpyHostToDevice));

            Kernel_genObjCoords<<<xObjSize, yObjSize>>>(
                xObjMin, yObjMin, zObjMin,
                xObjMax, yObjMax, zObjMax,
                xObjSize, yObjSize, zObjSize,
                objectRtGPU, objCoordsGPU);


            if (counter == 0) {
                float * objCoordsCPU = new float[xObjSize * yObjSize * zObjSize * 3];
                cudaMemcpy(objCoordsCPU, objCoordsGPU, xObjSize * yObjSize * zObjSize * 3 * sizeof(float), cudaMemcpyDeviceToHost);
                checkCUDA(__LINE__, cudaGetLastError());
                std::string fname = "objCoords.ply";
                FILE *fp = fopen(fname.c_str(), "w");
                fprintf(fp, "ply\n");
                fprintf(fp, "format binary_little_endian 1.0\n");
                fprintf(fp, "element vertex %d\n", xObjSize * yObjSize * zObjSize);
                fprintf(fp, "property float x\n");
                fprintf(fp, "property float y\n");
                fprintf(fp, "property float z\n");
                fprintf(fp, "property uchar red\n");
                fprintf(fp, "property uchar green\n");
                fprintf(fp, "property uchar blue\n");
                fprintf(fp, "end_header\n");
                for (int x = 0; x < xObjSize; x++) {
                    for (int y = 0; y < yObjSize; y++) {
                        for (int z = 0; z < zObjSize; z++) {
                            int coordIDX = ( x * yObjSize + y ) * zObjSize + z;
                            float float_x = objCoordsCPU[0 * xObjSize * yObjSize * zObjSize + coordIDX];
                            float float_y = objCoordsCPU[1 * xObjSize * yObjSize * zObjSize + coordIDX];
                            float float_z = objCoordsCPU[2 * xObjSize * yObjSize * zObjSize + coordIDX];
                            fwrite(&float_x, sizeof(float), 1, fp);
                            fwrite(&float_y, sizeof(float), 1, fp);
                            fwrite(&float_z, sizeof(float), 1, fp);

                            unsigned char r = (unsigned char) round(255.0f/xObjSize * (x + 0.5f));
                            unsigned char g = (unsigned char) round(255.0f/yObjSize * (y + 0.5f));
                            unsigned char b = (unsigned char) round(255.0f/zObjSize * (z + 0.5f));
                            fwrite(&r, sizeof(unsigned char), 1, fp);
                            fwrite(&g, sizeof(unsigned char), 1, fp);
                            fwrite(&b, sizeof(unsigned char), 1, fp);
                        }
                    }
                }
                fclose(fp);
                delete [] objCoordsCPU;
            }

            Kernel_labelObjCoords<<<xOutRes, yOutRes>>>(
                xOutRes, yOutRes, zOutRes,
                xOutRF, yOutRF, zOutRF,
                xOutRG, yOutRG, zOutRG,
                xObjSize, yObjSize, zObjSize,
                xMin, yMin, zMin,
                objCoordsGPU,
                objCoord_labelGPU+batchID*1*xOutRes*yOutRes*zOutRes);

            genLabels(
                objectRt,
                xMin, yMin, zMin, 
                xOutRes, yOutRes, zOutRes,
                xOutRF, yOutRF, zOutRF, 
                xOutRG, yOutRG, zOutRG, 
                r_labelGPU+batchID*4*xOutRes*yOutRes*zOutRes,
                t_labelGPU+batchID*3*xOutRes*yOutRes*zOutRes);


            Kernel_label<<<xOutRes, yOutRes>>>(
                cacheGPU + batchID * xSize * ySize * zSize, 
                xOutRes, yOutRes, zOutRes,
                xSize, ySize, zSize,
                xOutRF/unit, yOutRF/unit, zOutRF/unit,
                xOutRG/unit, yOutRG/unit, zOutRG/unit,
                xObjSize, yObjSize, zObjSize,
                NULL, //cls_labelGPU+batchID*1*xOutRes*yOutRes*zOutRes, 
                r_weightGPU+batchID*4*xOutRes*yOutRes*zOutRes,
                t_weightGPU+batchID*3*xOutRes*yOutRes*zOutRes,
                objCoord_weightGPU+batchID*(xObjSize*yObjSize*zObjSize)*xOutRes*yOutRes*zOutRes);

            // toc();

            counter++;
        }//end for (size_t i=0;i<batch_size;++i)

        if (saveFiles)
        {
            {
                // debug save tsdf
                Response* r = out[0];
                Tensor<StorageT>* t = new Tensor<StorageT>(r->dim);
                t->readGPU(cacheGPU);
                std::string fname = "debug/"+std::to_string(counter-1)+"_tsdf.tensor";
                FILE* fp = fopen(fname.c_str(),"wb");
                t->write(fp);
                fclose(fp);
                delete t;
            }
            {
                // debug save class label
                Response* r = out[1];
                Tensor<StorageT>* t = new Tensor<StorageT>(r->dim);
                t->readGPU(cls_labelGPU);
                std::string fname = "debug/"+std::to_string(counter-1)+"_cls.tensor";
                FILE* fp = fopen(fname.c_str(),"wb");
                t->write(fp);
                fclose(fp);
                delete t;
            }
            {
                // debug save class label
                Response* r = out[2];
                Tensor<StorageT>* t = new Tensor<StorageT>(r->dim);
                t->readGPU(r_labelGPU);
                std::string fname = "debug/"+std::to_string(counter-1)+"_r_label.tensor";
                FILE* fp = fopen(fname.c_str(),"wb");
                t->write(fp);
                fclose(fp);
                delete t;
            }
            {
                // debug save class label
                Response* r = out[3];
                Tensor<StorageT>* t = new Tensor<StorageT>(r->dim);
                t->readGPU(r_weightGPU);
                std::string fname = "debug/"+std::to_string(counter-1)+"_r_weight.tensor";
                FILE* fp = fopen(fname.c_str(),"wb");
                t->write(fp);
                fclose(fp);
                delete t;
            }
            {
                // debug save class label
                Response* r = out[4];
                Tensor<StorageT>* t = new Tensor<StorageT>(r->dim);
                t->readGPU(t_labelGPU);
                std::string fname = "debug/"+std::to_string(counter-1)+"_t_label.tensor";
                FILE* fp = fopen(fname.c_str(),"wb");
                t->write(fp);
                fclose(fp);
                delete t;
            }
            {
                // debug save class label
                Response* r = out[5];
                Tensor<StorageT>* t = new Tensor<StorageT>(r->dim);
                t->readGPU(t_weightGPU);
                std::string fname = "debug/"+std::to_string(counter-1)+"_t_weight.tensor";
                FILE* fp = fopen(fname.c_str(),"wb");
                t->write(fp);
                fclose(fp);
                delete t;
            }
            {
                // debug save class label
                Response* r = out[6];
                Tensor<StorageT>* t = new Tensor<StorageT>(r->dim);
                t->readGPU(objCoord_labelGPU);
                std::string fname = "debug/"+std::to_string(counter-1)+"_objCoord_label.tensor";
                FILE* fp = fopen(fname.c_str(),"wb");
                t->write(fp);
                fclose(fp);
                delete t;
            }
            {
                // debug save class label
                Response* r = out[7];
                Tensor<StorageT>* t = new Tensor<StorageT>(r->dim);
                t->readGPU(objCoord_weightGPU);
                std::string fname = "debug/"+std::to_string(counter-1)+"_objCoord_weight.tensor";
                FILE* fp = fopen(fname.c_str(),"wb");
                t->write(fp);
                fclose(fp);
                delete t;
            }
        }

        //exit(0); //debug

    };

    size_t Malloc(Phase phase_){
        if (phase == Training && phase_==Testing) return 0;
        
        if (!in.empty()){   std::cout<<"APCDataLayer shouldn't have any in's"<<std::endl; FatalError(__LINE__); }
        if (out.empty()){   std::cout<<"APCDataLayer should have some out's" <<std::endl; FatalError(__LINE__); }

        xSize = round((xMax-xMin)/unit);
        ySize = round((yMax-yMin)/unit);
        zSize = round((zMax-zMin)/unit);

        size_t memoryBytes = 0;
        std::cout<< (train_me? "* " : "  ");
        std::cout<<name<<std::endl;

        checkCUDA(__LINE__, cudaMalloc(&cacheGPU, batch_size*xSize*ySize*zSize*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&cls_labelGPU, batch_size*xSize*ySize*zSize*sizeofStorageT) ); //batch_size*1*xOutRes*yOutRes*zOutRes*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&r_labelGPU, batch_size*4*xOutRes*yOutRes*zOutRes*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&r_weightGPU, batch_size*4*xOutRes*yOutRes*zOutRes*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&t_labelGPU, batch_size*3*xOutRes*yOutRes*zOutRes*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&t_weightGPU, batch_size*3*xOutRes*yOutRes*zOutRes*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&objCoord_labelGPU, batch_size*1*xOutRes*yOutRes*zOutRes*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&objCoord_weightGPU, batch_size*(xObjSize*yObjSize*zObjSize)*xOutRes*yOutRes*zOutRes*sizeofStorageT) );

        checkCUDA(__LINE__, cudaMalloc(&weightGPU,xSize*ySize*zSize*sizeof(uint8_t)) );
        checkCUDA(__LINE__, cudaMalloc(&depthGPU, width*height*sizeofComputeT) );
        checkCUDA(__LINE__, cudaMalloc(&intrinsicsGPU, intrinsicsCPU->numBytes()) );
        checkCUDA(__LINE__, cudaMemcpy(intrinsicsGPU, intrinsicsCPU->CPUmem, intrinsicsCPU->numBytes(), cudaMemcpyHostToDevice) );
        checkCUDA(__LINE__, cudaMalloc(&extrinsicsGPU, extrinsicsCPU->numBytes()) );
        checkCUDA(__LINE__, cudaMemcpy(extrinsicsGPU, extrinsicsCPU->CPUmem, extrinsicsCPU->numBytes(), cudaMemcpyHostToDevice) );

        checkCUDA(__LINE__, cudaMalloc(&objectRtGPU, 12 * sizeof(float)));
        checkCUDA(__LINE__, cudaMalloc(&objCoordsGPU, xObjSize*yObjSize*zObjSize*3*sizeof(float)) );

        memoryBytes += xSize*ySize*zSize*(batch_size*sizeofStorageT*2 + sizeof(uint8_t)) + width*height*sizeofComputeT + intrinsicsCPU->numBytes() + extrinsicsCPU->numBytes();
        std::vector<int> data_dim;


        out[0]->need_diff = false;
        data_dim.resize(5);
        data_dim[0] = batch_size;
        data_dim[1] = 1;
        data_dim[2] = xSize;
        data_dim[3] = ySize;
        data_dim[4] = zSize;

        out[0]->receptive_field.resize(data_dim.size()-2);  fill_n(out[0]->receptive_field.begin(), data_dim.size()-2,unit);
        out[0]->receptive_gap.resize(data_dim.size()-2);    fill_n(out[0]->receptive_gap.begin(),   data_dim.size()-2,unit);
        out[0]->receptive_offset.resize(data_dim.size()-2); fill_n(out[0]->receptive_offset.begin(),data_dim.size()-2,0);
        memoryBytes += out[0]->Malloc(data_dim);

        out[1]->need_diff = false;
        data_dim.resize(5);
        data_dim[0] = batch_size;
        data_dim[1] = 1;
        memoryBytes += out[1]->Malloc(data_dim);

        out[2]->need_diff = false;
        data_dim[1] = 4;
        data_dim[2] = xOutRes;
        data_dim[3] = yOutRes;
        data_dim[4] = zOutRes;
        memoryBytes += out[2]->Malloc(data_dim);

        out[3]->need_diff = false;
        memoryBytes += out[3]->Malloc(data_dim);

        out[4]->need_diff = false;
        data_dim[1] = 3;
        memoryBytes += out[4]->Malloc(data_dim);

        out[5]->need_diff = false;
        memoryBytes += out[5]->Malloc(data_dim);

        out[6]->need_diff = false;
        data_dim[1] = 1;
        memoryBytes += out[6]->Malloc(data_dim);

        out[7]->need_diff = false;
        data_dim[1] = xObjSize*yObjSize*zObjSize;
        memoryBytes += out[7]->Malloc(data_dim);

        prefetch(); 
        //lock = std::async(std::launch::async,&APCDataLayer::prefetch,this);

        return memoryBytes;
    };


    void forward(Phase phase_){
        //lock.wait();
        epoch = epoch_prefetch;
        std::swap(out[0]->dataGPU,cacheGPU);

        std::swap(out[1]->dataGPU,cls_labelGPU);
        std::swap(out[2]->dataGPU,r_labelGPU);
        std::swap(out[3]->dataGPU,r_weightGPU);
        std::swap(out[4]->dataGPU,t_labelGPU);
        std::swap(out[5]->dataGPU,t_weightGPU);
        std::swap(out[6]->dataGPU,objCoord_labelGPU);
        std::swap(out[7]->dataGPU,objCoord_weightGPU);

        prefetch();
        //lock = std::async(std::launch::async,&APCDataLayer::prefetch,this);
    };

    void shuffle(){};     
};