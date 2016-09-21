#include "render.hpp"
#include "label.hpp"

__global__ void Kernel_integrate(
        bool flipVertical4render,
        unsigned int xSize, unsigned int ySize, unsigned int zSize, 
        ComputeT xMin, ComputeT yMin, ComputeT zMin, 
        ComputeT unit, ComputeT margin, 
        unsigned int width, unsigned int height, 
        const float* depth, const ComputeT* pose, const ComputeT* intrinsics, StorageT *tsdf, uint8_t *weight) {

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

            v_new = 1.0 - fabs(v_new); // 1-tdf // comment this out if you want to use tsdf

            unsigned int idx = idx_offset + z;

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
                StorageT *cls_labelGPU, 
                StorageT *r_weightGPU, 
                StorageT *t_weightGPU){

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
                    count += GPUStorage2ComputeT(tsdfGPU[iO])>0;
                }
            }
        }
        //if (count>0) printf("%d ",count); //good debuging to output histogram for cutting
        StorageT result = (count*100>xRF*yRF*zRF)? (GPUCompute2StorageT(1)) : (GPUCompute2StorageT(0));
        unsigned int i_base_z = i_base+z;
        cls_labelGPU[i_base_z] = result;
        r_weightGPU[i_base_z] = result;
        r_weightGPU[i_base_z+offset] = result;
        r_weightGPU[i_base_z+offset+offset] = result;
        r_weightGPU[i_base_z+offset+offset+offset] = result;
        t_weightGPU[i_base_z] = result;
        t_weightGPU[i_base_z+offset] = result;
        t_weightGPU[i_base_z+offset+offset] = result;
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

    uint8_t* weightGPU;
    float* depthGPU;


    Mesh3D* pModel;
    Tensor<ComputeT>* intrinsicsCPU;
    Tensor<ComputeT>* extrinsicsCPU;

    ComputeT* intrinsicsGPU;
    ComputeT* extrinsicsGPU;

    std::uniform_real_distribution<ComputeT>* uDistribution;
public:
    bool fixedPose;
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
        SetValue(json, fixedPose, false)

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
    };

    void init(){
        epoch_prefetch  = 0;

        cacheGPU = NULL;
        cls_labelGPU = NULL;
        r_labelGPU = NULL;
        r_weightGPU = NULL;
        t_labelGPU = NULL;
        t_weightGPU = NULL;

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

        intrinsicsCPU = new Tensor<ComputeT>(intrinsics);
        extrinsicsCPU = new Tensor<ComputeT>(extrinsics);

        uDistribution = new std::uniform_real_distribution<ComputeT>(0,1);
    };    

    void clearTSDF(size_t batchID){
        //GPU_set_negones(xSize*ySize*zSize, cacheGPU+batchID*xSize*ySize*zSize*sizeofStorageT);
        GPU_set_zeros(xSize*ySize*zSize, cacheGPU+batchID*xSize*ySize*zSize);
        checkCUDA(__LINE__, cudaMemset(weightGPU, 0, sizeof(uint8_t) * xSize*ySize*zSize));
    };

    void integrateTSDF(bool flipVertical4render,size_t batchID, size_t poseID){
        Kernel_integrate<<<xSize,ySize>>>(flipVertical4render,xSize, ySize, zSize, xMin, yMin, zMin, unit, margin, width, height, depthGPU, extrinsicsGPU+3*4*poseID, intrinsicsGPU, cacheGPU+batchID*xSize*ySize*zSize, weightGPU);
    };


    void prefetch(){
        checkCUDA(__LINE__,cudaSetDevice(GPU));

        for (size_t batchID=0;batchID<batch_size;++batchID){

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
            if (fixedPose){
                quaternion[0] = 1;
                quaternion[1] = 0;
                quaternion[2] = 0;
                quaternion[3] = 0;
                objectRt[3] = 0.5*(xMaxNow-xMinNow)+xMinNow;
                objectRt[7] = 0.5*(yMaxNow-yMinNow)+yMinNow;
                objectRt[11]= 0.5*(zMaxNow-zMinNow)+zMinNow;
            }

            quaternion2matrix(quaternion, objectRt, 4);


            //debug
            /*
            {
                intrinsicsCPU->CPUmem[2]=320;
                intrinsicsCPU->CPUmem[5]=240;
                
                std::cout<<"intrinsics:"<<std::endl;
                for(int r=0;r<3;++r){
                    for(int c=0;c<3;++c){
                        std::cout<<intrinsicsCPU->CPUmem[r*3+c]<<" ";
                    }
                    std::cout<<std::endl;
                }
            }
            {
                std::cout<<"objectRt:"<<std::endl;
                for(int r=0;r<3;++r){
                    for(int c=0;c<4;++c){
                        std::cout<<objectRt[r*4+c]<<" ";
                    }
                    std::cout<<std::endl;
                }
            }
            */


            // render and integrate

            for (size_t poseID=0;poseID<extrinsicsCPU->dim[0] ;++poseID){

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

            // generate the label

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
                cls_labelGPU+batchID*1*xOutRes*yOutRes*zOutRes, 
                r_weightGPU+batchID*4*xOutRes*yOutRes*zOutRes,
                t_weightGPU+batchID*3*xOutRes*yOutRes*zOutRes);


            counter++;
        }//end for (size_t i=0;i<batch_size;++i)

        if (saveFiles)
        {
            {
                // debug save tsdf
                Response* r = out[0];
                Tensor<StorageT>* t = new Tensor<StorageT>(r->dim);
                t->readGPU(cacheGPU);
                std::string fname = "debug/"+std::to_string(counter)+"_tsdf.tensor";
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
                std::string fname = "debug/"+std::to_string(counter)+"_cls.tensor";
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
                std::string fname = "debug/"+std::to_string(counter)+"_r_label.tensor";
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
                std::string fname = "debug/"+std::to_string(counter)+"_r_weight.tensor";
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
                std::string fname = "debug/"+std::to_string(counter)+"_t_label.tensor";
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
                std::string fname = "debug/"+std::to_string(counter)+"_t_weight.tensor";
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
        checkCUDA(__LINE__, cudaMalloc(&cls_labelGPU, batch_size*1*xOutRes*yOutRes*zOutRes*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&r_labelGPU, batch_size*4*xOutRes*yOutRes*zOutRes*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&r_weightGPU, batch_size*4*xOutRes*yOutRes*zOutRes*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&t_labelGPU, batch_size*3*xOutRes*yOutRes*zOutRes*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&t_weightGPU, batch_size*3*xOutRes*yOutRes*zOutRes*sizeofStorageT) );

        checkCUDA(__LINE__, cudaMalloc(&weightGPU,xSize*ySize*zSize*sizeof(uint8_t)) );
        checkCUDA(__LINE__, cudaMalloc(&depthGPU, width*height*sizeofComputeT) );
        checkCUDA(__LINE__, cudaMalloc(&intrinsicsGPU, intrinsicsCPU->numBytes()) );
        checkCUDA(__LINE__, cudaMemcpy(intrinsicsGPU, intrinsicsCPU->CPUmem, intrinsicsCPU->numBytes(), cudaMemcpyHostToDevice) );
        checkCUDA(__LINE__, cudaMalloc(&extrinsicsGPU, extrinsicsCPU->numBytes()) );
        checkCUDA(__LINE__, cudaMemcpy(extrinsicsGPU, extrinsicsCPU->CPUmem, extrinsicsCPU->numBytes(), cudaMemcpyHostToDevice) );


        memoryBytes += xSize*ySize*zSize*(batch_size*sizeofStorageT + sizeof(uint8_t)) + width*height*sizeofComputeT + intrinsicsCPU->numBytes() + extrinsicsCPU->numBytes();
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
        data_dim[2] = xOutRes;
        data_dim[3] = yOutRes;
        data_dim[4] = zOutRes;
        memoryBytes += out[1]->Malloc(data_dim);

        out[2]->need_diff = false;
        data_dim[1] = 4;
        memoryBytes += out[2]->Malloc(data_dim);

        out[3]->need_diff = false;
        memoryBytes += out[3]->Malloc(data_dim);

        out[4]->need_diff = false;
        data_dim[1] = 3;
        memoryBytes += out[4]->Malloc(data_dim);

        out[5]->need_diff = false;
        memoryBytes += out[5]->Malloc(data_dim);

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

        prefetch();
        //lock = std::async(std::launch::async,&APCDataLayer::prefetch,this);
    };

    void shuffle(){};     
};