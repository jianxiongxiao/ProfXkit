__global__ void Kernel_integrate(
        unsigned int xSize, unsigned int ySize, unsigned int zSize, 
        ComputeT xMin, ComputeT yMin, ComputeT zMin, 
        ComputeT unit, ComputeT margin, 
        unsigned int width, unsigned int height, 
        const ComputeT* depth, const ComputeT* pose, const ComputeT* intrinsics, StorageT *tsdf, uint8_t *weight) {

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

    unsigned int idx_offset = x * ySize * zSize + y * zSize;

    for (unsigned int z = 0; z < zSize; ++z, xCamera += xDelta, yCamera += yDelta, zCamera += zDelta){

        ComputeT xOzCamera = xCamera / zCamera;
        ComputeT yOzCamera = yCamera / zCamera;

        int px = roundf(intrinsics[0] * xOzCamera + intrinsics[2]);
        int py = roundf(intrinsics[4] * yOzCamera + intrinsics[5]);

        if (px < 0 || px >= width || py < 0 || py >= height) continue;

        ComputeT p_depth = *(depth + py * width + px);

        if (p_depth == 0.0) continue;

        ComputeT diff = (p_depth - zCamera) * sqrtf(1.0 + xOzCamera * xOzCamera + yOzCamera * yOzCamera);

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


// Return all files in directory using search string
#include <dirent.h>
std::vector<std::string> getFileList(std::string directory, std::string search_string) {

    if (directory.substr(directory.length()-1,1) != "/")
        directory = directory + "/";

    std::vector<std::string> file_list;
    DIR *dir;
    struct dirent *ent;
    if ((dir = opendir (directory.c_str())) != NULL) {
        while ((ent = readdir (dir)) != NULL) {
            std::string filename(ent->d_name);
            if ((filename.find(search_string) != std::string::npos || search_string.empty()) && filename != "." && filename != ".." && filename.substr(0,1) != ".")
            file_list.push_back(directory+filename);
        }
        closedir(dir);
        std::sort(file_list.begin(), file_list.end());
    } else {
        perror ("Error: could not look into directory!");
    }
    return file_list;
}


class TSDFDataLayer : public DataLayer {

    std::future<void> lock;
    int epoch_prefetch;
    std::vector<size_t> ordering;

    unsigned int xSize;
    unsigned int ySize;
    unsigned int zSize;


    StorageT* cacheGPU;
    uint8_t* weightGPU;
    ComputeT* depthGPU;
    ComputeT* poseGPU;
    ComputeT* intrinsicsGPU;

    std::vector<std::string> folders;
public:
    std::string folder_list;
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

    int numofitems(){
        return folders.size();
    };

    TSDFDataLayer(std::string name_, Phase phase_, std::string folder_list_, int batch_size_): DataLayer(name_), batch_size(batch_size_), folder_list(folder_list_){
        phase = phase_;
        init();
    };
    TSDFDataLayer(JSON* json){
        SetOrDie(json, name)
        SetValue(json, phase,       Training)
        SetOrDie(json, folder_list  )
        SetValue(json, batch_size,  2)

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

        SetValue(json, random,true)

        init();
    };
    ~TSDFDataLayer(){
        if (cacheGPU!=NULL) checkCUDA(__LINE__, cudaFree(cacheGPU));
        if (weightGPU!=NULL) checkCUDA(__LINE__, cudaFree(weightGPU));
        if (depthGPU!=NULL) checkCUDA(__LINE__, cudaFree(depthGPU));
        if (poseGPU!=NULL) checkCUDA(__LINE__, cudaFree(poseGPU));
        if (intrinsicsGPU!=NULL) checkCUDA(__LINE__, cudaFree(intrinsicsGPU));
    };

    void shuffle(){
        if (phase!=Testing && random){
            ordering = randperm(numofitems(), rng);
        }else{
            ordering.resize(numofitems());
            for (int i=0;i<numofitems();++i) ordering[i]=i;            
        }
    }; 

    void clearTSDF(size_t batchID){
        //GPU_set_negones(xSize*ySize*zSize, cacheGPU+batchID*xSize*ySize*zSize*sizeofStorageT);
        GPU_set_zeros(xSize*ySize*zSize, cacheGPU+batchID*xSize*ySize*zSize);
        checkCUDA(__LINE__, cudaMemset(weightGPU, 0, sizeof(uint8_t) * xSize*ySize*zSize));
    };

    void integrateTSDF(size_t batchID){
        Kernel_integrate<<<xSize,ySize>>>(xSize, ySize, zSize, xMin, yMin, zMin, unit, margin, width, height, depthGPU, poseGPU, intrinsicsGPU, cacheGPU+batchID*xSize*ySize*zSize, weightGPU);
    };


    void prefetch(){
        checkCUDA(__LINE__,cudaSetDevice(GPU));

        for (size_t i=0;i<batch_size;++i){
            int sequence_i = ordering[counter];

            std::vector<std::string> depth_list = getFileList(folders[sequence_i],"_depth.tensor");
            std::vector<std::string> pose_list = getFileList(folders[sequence_i],"_RtW2C.tensor");
            Tensor<ComputeT>* intrinsics = new Tensor<ComputeT>(folders[sequence_i]+"/intrinsics.tensor");
            checkCUDA(__LINE__, cudaMemcpy(intrinsicsGPU, intrinsics->CPUmem, 3*3*sizeofComputeT, cudaMemcpyHostToDevice) );
            delete intrinsics;

            clearTSDF(i);

            for (size_t f=0;f<depth_list.size();++f){
                Tensor<ComputeT>* depth_map = new Tensor<ComputeT>(depth_list[f]);
                checkCUDA(__LINE__, cudaMemcpy(depthGPU, depth_map->CPUmem, depth_map->numBytes(), cudaMemcpyHostToDevice) );
                delete depth_map;

                Tensor<ComputeT>* pose      = new Tensor<ComputeT>(pose_list[f]);
                checkCUDA(__LINE__, cudaMemcpy(poseGPU, pose->CPUmem, 3*4*sizeofComputeT, cudaMemcpyHostToDevice) );
                delete pose;

                integrateTSDF(i);
            }

            counter++;
            if (counter>= ordering.size()){
                if (phase!=Testing) shuffle();
                counter = 0;
                ++epoch_prefetch;
            }
        }//end for (size_t i=0;i<batch_size;++i)

        /*
        // debug save tsdf
        Response* r = out[0];
        Tensor<StorageT>* t = new Tensor<StorageT>(r->dim);
        t->readGPU(r-> dataGPU);
        checkCUDA(__LINE__, cudaMemcpy(t->CPUmem, cacheGPU, t->numBytes(), cudaMemcpyDeviceToHost) );
        FILE* fp = fopen("tsdf_debug.tensor","wb");
        t->write(fp);
        fclose(fp);
        delete t;        
        */

    };    

    void init(){
        epoch_prefetch  = 0;
        cacheGPU = NULL;
        weightGPU = NULL;

        depthGPU = NULL;
        poseGPU = NULL;
        intrinsicsGPU = NULL;

        train_me = false;
        std::cout<<"TSDFDataLayer "<<name<<" loading data: "<<std::endl;
        folders = getFileList(folder_list, "");

        for (int k=0;k<folders.size();++k)
            std::cout<<"Folder "<<k<<": "<<folders[k]<<std::endl;

        shuffle();
    };

    size_t Malloc(Phase phase_){
        if (phase == Training && phase_==Testing) return 0;
        
        if (!in.empty()){   std::cout<<"TSDFDataLayer shouldn't have any in's"<<std::endl; FatalError(__LINE__); }
        if (out.empty()){   std::cout<<"TSDFDataLayer should have some out's" <<std::endl; FatalError(__LINE__); }

        xSize = round((xMax-xMin)/unit);
        ySize = round((yMax-yMin)/unit);
        zSize = round((zMax-zMin)/unit);

        size_t memoryBytes = 0;
        std::cout<< (train_me? "* " : "  ");
        std::cout<<name<<std::endl;

        checkCUDA(__LINE__, cudaMalloc(&cacheGPU, batch_size*xSize*ySize*zSize*sizeofStorageT) );
        checkCUDA(__LINE__, cudaMalloc(&weightGPU,xSize*ySize*zSize*sizeof(uint8_t)) );
        checkCUDA(__LINE__, cudaMalloc(&depthGPU, width*height*sizeofComputeT) );
        checkCUDA(__LINE__, cudaMalloc(&poseGPU,  3*4*sizeofComputeT) );
        checkCUDA(__LINE__, cudaMalloc(&intrinsicsGPU, 3*3*sizeofComputeT) );

        memoryBytes += xSize*ySize*zSize*(batch_size*sizeofStorageT + sizeof(uint8_t)) + width*height*sizeofComputeT;

        out[0]->need_diff = false;
        std::vector<int> data_dim;
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

        //prefetch(); 
        lock = std::async(std::launch::async,&TSDFDataLayer::prefetch,this);

        return memoryBytes;
    };


    void forward(Phase phase_){
        lock.wait();
        epoch = epoch_prefetch;
        std::swap(out[0]->dataGPU,cacheGPU);
        //prefetch();
        lock = std::async(std::launch::async,&TSDFDataLayer::prefetch,this);
    };
};