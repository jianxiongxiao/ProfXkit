// Please choose a data type to compile
#define DATATYPE 0

#if DATATYPE==0
    #pragma message "Compiling using StorageT=half ComputeT=float"
    #define StorageT half
    #define ComputeT float
    #define sizeofStorageT 2
    #define sizeofComputeT 4
    #define CUDNNStorageT CUDNN_DATA_HALF
    #define CUDNNConvComputeT CUDNN_DATA_FLOAT
    #define CPUStorage2ComputeT(x) (cpu_half2float(x))
    #define CPUCompute2StorageT(x) (cpu_float2half(x))
    #define GPUStorage2ComputeT(x) (__half2float(x))
    #define GPUCompute2StorageT(x) (__float2half(x))
    #define GPUgemm Hgemm
    #define GPUasum Hasum
    #define ISNAN(x) (ishnan(x))
    #define ComputeT_MIN FLT_MIN
#elif DATATYPE==1
    #pragma message "Compiling using StorageT=float ComputeT=float"
    #define StorageT float
    #define ComputeT float
    #define sizeofStorageT 4
    #define sizeofComputeT 4
    #define CUDNNStorageT CUDNN_DATA_FLOAT
    #define CUDNNConvComputeT CUDNN_DATA_FLOAT
    #define CPUStorage2ComputeT(x) (x)
    #define CPUCompute2StorageT(x) (x)
    #define GPUStorage2ComputeT(x) (x)
    #define GPUCompute2StorageT(x) (x)
    #define GPUgemm cublasSgemm
    #define GPUasum cublasSasum
    #define ISNAN(x) (std::isnan(x))
    #define ComputeT_MIN FLT_MIN
#elif DATATYPE==2
    #pragma message "Compiling using StorageT=double ComputeT=double"
    #define StorageT double
    #define ComputeT double
    #define sizeofStorageT 8
    #define sizeofComputeT 8
    #define CUDNNStorageT CUDNN_DATA_DOUBLE
    #define CUDNNConvComputeT CUDNN_DATA_DOUBLE
    #define CPUStorage2ComputeT(x) (x)
    #define CPUCompute2StorageT(x) (x)
    #define GPUStorage2ComputeT(x) (x)
    #define GPUCompute2StorageT(x) (x)
    #define GPUgemm cublasDgemm
    #define GPUasum cublasDasum
    #define ISNAN(x) (std::isnan(x))
    #define ComputeT_MIN DBL_MIN
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////
// Includes
//////////////////////////////////////////////////////////////////////////////////////////////////
#include <cuda_fp16.h>
#include <cstdlib>
#include <cstdio>
#include <cstdarg>
#include <cmath>
#include <cfloat>
#include <iostream>
#include <fstream>
#include <sstream>
#include <random>
#include <algorithm>
#include <map>
#include <vector>
#include <string>
#include <typeinfo>
#include <typeindex>
#include <thread>
#include <chrono>
#include <future>
#include <sys/time.h>



//////////////////////////////////////////////////////////////////////////////////////////////////
// Debugging utility
//////////////////////////////////////////////////////////////////////////////////////////////////

void FatalError(const int lineNumber=0) {
    std::cerr << "FatalError";
    if (lineNumber!=0) std::cerr<<" at LINE "<<lineNumber;
    std::cerr << ". Program Terminated." << std::endl;
    cudaDeviceReset();
    exit(EXIT_FAILURE);
}

void checkCUDA(const int lineNumber, cudaError_t status) {
    if (status != cudaSuccess) {
        std::cerr << "CUDA failure at LINE " << lineNumber << ": " << status << std::endl;
        FatalError();
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// HALF computation ultility
//////////////////////////////////////////////////////////////////////////////////////////////////

static __inline__ __device__ __host__ int ishnan(half h) {
    // When input is NaN, exponent is all ones and mantissa is non-zero.
    return (h.x & 0x7c00U) == 0x7c00U && (h.x & 0x03ffU) != 0;
}

half cpu_float2half(float f) {
    half ret;

    unsigned x = *((int*)(void*)(&f));
    unsigned u = (x & 0x7fffffff), remainder, shift, lsb, lsb_s1, lsb_m1;
    unsigned sign, exponent, mantissa;

    // Get rid of +NaN/-NaN case first.
    if (u > 0x7f800000) {
        ret.x = 0x7fffU;
        return ret;
    }

    sign = ((x >> 16) & 0x8000);

    // Get rid of +Inf/-Inf, +0/-0.
    if (u > 0x477fefff) {
        ret.x = sign | 0x7c00U;
        return ret;
    }
    if (u < 0x33000001) {
        ret.x = (sign | 0x0000);
        return ret;
    }

    exponent = ((u >> 23) & 0xff);
    mantissa = (u & 0x7fffff);

    if (exponent > 0x70) {
        shift = 13;
        exponent -= 0x70;
    } else {
        shift = 0x7e - exponent;
        exponent = 0;
        mantissa |= 0x800000;
    }
    lsb = (1 << shift);
    lsb_s1 = (lsb >> 1);
    lsb_m1 = (lsb - 1);

    // Round to nearest even.
    remainder = (mantissa & lsb_m1);
    mantissa >>= shift;
    if (remainder > lsb_s1 || (remainder == lsb_s1 && (mantissa & 0x1))) {
        ++mantissa;
        if (!(mantissa & 0x3ff)) {
            ++exponent;
            mantissa = 0;
        }
    }

    ret.x = (sign | (exponent << 10) | mantissa);

    return ret;
}


float cpu_half2float(half h) {
    unsigned sign = ((h.x >> 15) & 1);
    unsigned exponent = ((h.x >> 10) & 0x1f);
    unsigned mantissa = ((h.x & 0x3ff) << 13);

    if (exponent == 0x1f) {  /* NaN or Inf */
        mantissa = (mantissa ? (sign = 0, 0x7fffff) : 0);
        exponent = 0xff;
    } else if (!exponent) {  /* Denorm or Zero */
        if (mantissa) {
            unsigned int msb;
            exponent = 0x71;
            do {
                msb = (mantissa & 0x400000);
                mantissa <<= 1;  /* normalize */
                --exponent;
            } while (!msb);
            mantissa &= 0x7fffff;  /* 1.mantissa is implicit */
        }
    } else {
        exponent += 0x70;
    }

    int temp = ((sign << 31) | (exponent << 23) | mantissa);

    return *((float*)((void*)&temp));
}


bool operator <(const half& x, const half& y) {
    return cpu_half2float(x) < cpu_half2float(y);
}

std::ostream& operator<< (std::ostream& stream, const half& x) {
    stream << cpu_half2float(x);
    return stream;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
// File format
//////////////////////////////////////////////////////////////////////////////////////////////////

void memorySizePrint(size_t bytes){
    if (bytes<512){
        std::cout<<bytes<<" Bytes";
    }else if (bytes<512.0*1024){
        std::cout<<(bytes/1024.0)<<" KB";
    }else if (bytes<512.0*1024*1024){
        std::cout<<(bytes/(1024.0*1024.0))<<" MB";
    }else if (bytes<512.0*1024*1024*1024){
        std::cout<<(bytes/(1024.0*1024.0*1024.0))<<" GB";
    }else if (bytes<512.0*1024*1024*1024*1024){
        std::cout<<(bytes/(1024.0*1024.0*1024.0*1024.0))<<" TB";
    }else{
        std::cout<<(bytes/(1024.0*1024.0*1024.0*1024.0*1024.0))<<" PB";
    }
}

void veciPrint(const std::vector<int>& v){
    std::cout<<"["<<v.size()<<"]={";
    if (v.size()>0) std::cout<<v[0];
    if (v.size()>1){
        for (int i=1;i<v.size();++i){
            std::cout<<","<<v[i];
        }
    }
    std::cout<<"}";
}

size_t numel(const std::vector<int>& dim){
    size_t res = 1;
    for (int i=0;i<dim.size();++i) res *= (size_t)(dim[i]);
    return res;
}

size_t sizeofitem(const std::vector<int>& dim){
    size_t res = 1;
    for (int i=1;i<dim.size();++i) res *= (size_t)(dim[i]);
    return res;
}

size_t numspel(const std::vector<int>& dim){
    size_t res = 1;
    for (int i=2;i<dim.size();++i) res *= (size_t)(dim[i]);
    return res;
}

uint8_t typeID(std::type_index t){
    if (t==typeid(half))        return uint8_t(0);
    if (t==typeid(float))       return uint8_t(1);
    if (t==typeid(double))      return uint8_t(2);
    if (t==typeid(uint8_t))     return uint8_t(3);
    if (t==typeid(uint16_t))    return uint8_t(4);
    if (t==typeid(uint32_t))    return uint8_t(5);
    if (t==typeid(uint64_t))    return uint8_t(6);
    if (t==typeid(int8_t))      return uint8_t(7);
    if (t==typeid(int16_t))     return uint8_t(8);
    if (t==typeid(int32_t))     return uint8_t(9);
    if (t==typeid(int64_t))     return uint8_t(10);
    if (t==typeid(char))        return uint8_t(11);
    if (t==typeid(bool))        return uint8_t(12);
    FatalError(__LINE__);       return uint8_t(255);
}

uint8_t readTypeID(std::string filename){
    FILE* fp = fopen(filename.c_str(),"rb");
    while (fp==NULL) {
        std::cerr<<"readTypeID: fail to open file "<<filename<<". Please provide it first. Will retry after 5 seconds."<<std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(5));
        fp = fopen(filename.c_str(),"rb");
    }
    size_t read_cnt;
    uint8_t fpTypeid; read_cnt = fread((void*)(&fpTypeid), sizeof(uint8_t), 1, fp);     if (read_cnt!=1) { std::cerr<<"Error at readTypeID: no data type. "<<std::endl; FatalError(__LINE__); }
    fclose(fp);
    return fpTypeid;
}

template <class T>
class Tensor{
public:
    std::vector<int> dim;
    T* CPUmem;
    std::string name;

    // compile will check if your time is not correct for writeGPU and readGPU
    void writeGPU(T* GPUmem){
        cudaMemcpy(GPUmem, CPUmem, numel()*sizeof(T), cudaMemcpyHostToDevice);
    };

    void readGPU(T* GPUmem){
        cudaMemcpy(CPUmem, GPUmem, numel()*sizeof(T), cudaMemcpyDeviceToHost);
    };

    Tensor(): CPUmem(NULL){};

    size_t numel(){ return ::numel(dim); };

    size_t numBytes(){ return sizeof(T)*numel(); };

    int numofitems(){ return dim[0]; };

    size_t sizeofitem(){ return ::sizeofitem(dim); };

    ~Tensor(){
        if (CPUmem!=NULL)   delete[] CPUmem;
    };

    void initialize(T val){
        for (size_t i=0;i<numel();++i){
            CPUmem[i]=val;
        }
    };

    size_t readHeader(FILE* fp){
        size_t read_cnt;
        uint8_t myTypeid = typeID(typeid(T));
        uint32_t myTypesizeof = uint32_t(sizeof(T));
        uint8_t fpTypeid;       read_cnt = fread((void*)(&fpTypeid), sizeof(uint8_t), 1, fp);       if (read_cnt!=1) { std::cerr<<"Error at Tensor::readHeader: no data type. "<<std::endl; FatalError(__LINE__); }
        uint32_t fpTypesizeof;  read_cnt = fread((void*)(&fpTypesizeof), sizeof(uint32_t), 1, fp);  if (read_cnt!=1) { std::cerr<<"Error at Tensor::readHeader: no data size. "<<std::endl; FatalError(__LINE__); }
        int lenName;
        read_cnt = fread((void*)(&lenName), sizeof(int), 1, fp);
        if (read_cnt!=1) { std::cerr<<"Error at Tensor::readHeader: wrong data type. "<<std::endl; FatalError(__LINE__); }
        name.resize(lenName);
        if (lenName>0){
            read_cnt = fread((void*)(name.data()), sizeof(char), lenName, fp);
            if (read_cnt!=lenName) { std::cerr<<"Error at Tensor::readHeader: wrong data type. "<<std::endl; FatalError(__LINE__); }
        }
        int nbDims;
        read_cnt = fread((void*)(&nbDims), sizeof(int), 1, fp);
        if (read_cnt!=1) { std::cerr<<"Error at Tensor::readHeader: wrong data type. "<<std::endl; FatalError(__LINE__); }
        dim.resize(nbDims);
        if (nbDims>0){
            read_cnt = fread((void*)(&dim[0]), sizeof(int), nbDims, fp);
            if (read_cnt!=nbDims) { std::cerr<<"Error at Tensor::readHeader: wrong data type. "<<std::endl; FatalError(__LINE__); }
        }

        size_t headerBytes = sizeof(uint8_t) + sizeof(uint32_t) + sizeof(int) + lenName*sizeof(char) + sizeof(int) + nbDims*sizeof(int);

        if (myTypeid!=fpTypeid || myTypesizeof!=fpTypesizeof){
            std::cerr<<"Error at Tensor::readHeader: wrong data type. "<<std::endl; FatalError(__LINE__);
        }

        return headerBytes;
    };

    //support continuous read across many NdTensors
    T* read(FILE* fp,int batch_size=1){
        if (CPUmem!=NULL){
            delete[] CPUmem;
            CPUmem = NULL;
        }

        size_t read_cnt;

        uint8_t myTypeid = typeID(typeid(T));
        uint32_t myTypesizeof = uint32_t(sizeof(T));

        uint8_t fpTypeid;       read_cnt = fread((void*)(&fpTypeid), sizeof(uint8_t), 1, fp);       if (read_cnt!=1) return NULL;
        uint32_t fpTypesizeof;  read_cnt = fread((void*)(&fpTypesizeof), sizeof(uint32_t), 1, fp);  if (read_cnt!=1) return NULL;

        if (myTypeid!=fpTypeid || myTypesizeof!=fpTypesizeof){

            if (myTypeid==fpTypeid && myTypesizeof!=fpTypesizeof){ std::cerr<<"Tensor read error: same type but different sizeof, maybe different computer architecture. "<<std::endl; FatalError(__LINE__);}

            //if (myTypeid!=fpTypeid){ std::cerr<<"Tensor read error: different types. "<<std::endl; FatalError(__LINE__); }

            if (myTypeid==typeID(typeid(half)) && fpTypeid==typeID(typeid(float))){
                //std::cout<<std::endl<<"converting from float to half"<<std::endl;
                fseek(fp, -(sizeof(uint8_t)+sizeof(uint32_t)), SEEK_CUR);
                Tensor<float>* floatTensor = new Tensor<float>(fp);
                this->dim  = floatTensor->dim ;
                this->name = floatTensor->name;
                Malloc(batch_size);
                for(size_t i=0; i<numel(); ++i){
                    half v = cpu_float2half(floatTensor->CPUmem[i]);
                    memcpy(((half*)(CPUmem))+i,&v,sizeof(half));
                }
                delete floatTensor;
            }else if (myTypeid==typeID(typeid(float)) && fpTypeid==typeID(typeid(half))){
                fseek(fp, -(sizeof(uint8_t)+sizeof(uint32_t)), SEEK_CUR);
                Tensor<half>* halfTensor = new Tensor<half>(fp);
                this->dim  = halfTensor->dim ;
                this->name = halfTensor->name;
                Malloc(batch_size);
                for(size_t i=0; i<numel(); ++i){
                    float v = cpu_half2float(halfTensor->CPUmem[i]);
                    memcpy(((float*)(CPUmem))+i,&v,sizeof(float));
                }
                delete halfTensor;
            }else if (myTypeid==typeID(typeid(double)) && fpTypeid==typeID(typeid(float))){
                fseek(fp, -(sizeof(uint8_t)+sizeof(uint32_t)), SEEK_CUR);
                Tensor<float>* floatTensor = new Tensor<float>(fp);
                this->dim  = floatTensor->dim ;
                this->name = floatTensor->name;
                Malloc(batch_size);
                for(size_t i=0; i<numel(); ++i){
                    double v = double(floatTensor->CPUmem[i]);
                    memcpy(((double*)(CPUmem))+i,&v,sizeof(double));
                }
                delete floatTensor;
            }else if (myTypeid==typeID(typeid(float)) && fpTypeid==typeID(typeid(double))){
                fseek(fp, -(sizeof(uint8_t)+sizeof(uint32_t)), SEEK_CUR);
                Tensor<double>* doubleTensor = new Tensor<double>(fp);
                this->dim  = doubleTensor->dim ;
                this->name = doubleTensor->name;
                Malloc(batch_size);
                for(size_t i=0; i<numel(); ++i){
                    float v = float(doubleTensor->CPUmem[i]);
                    memcpy(((float*)(CPUmem))+i,&v,sizeof(float));
                }
                delete doubleTensor;
            }else if (myTypeid==typeID(typeid(half)) && fpTypeid==typeID(typeid(double))){
                fseek(fp, -(sizeof(uint8_t)+sizeof(uint32_t)), SEEK_CUR);
                Tensor<double>* doubleTensor = new Tensor<double>(fp);
                this->dim  = doubleTensor->dim ;
                this->name = doubleTensor->name;
                Malloc(batch_size);
                for(size_t i=0; i<numel(); ++i){
                    half v = cpu_float2half(float(doubleTensor->CPUmem[i]));
                    memcpy(((half*)(CPUmem))+i,&v,sizeof(half));
                }
                delete doubleTensor;
            }else if (myTypeid==typeID(typeid(float)) && fpTypeid==typeID(typeid(half))){
                fseek(fp, -(sizeof(uint8_t)+sizeof(uint32_t)), SEEK_CUR);
                Tensor<half>* halfTensor = new Tensor<half>(fp);
                this->dim  = halfTensor->dim ;
                this->name = halfTensor->name;
                Malloc(batch_size);
                for(size_t i=0; i<numel(); ++i){
                    double v = double(cpu_half2float(halfTensor->CPUmem[i]));
                    memcpy(((double*)(CPUmem))+i,&v,sizeof(double));
                }
                delete halfTensor;
            }else{
                std::cerr<<"Tensor conversion is not supported: from Type "<<fpTypeid<<" to Type "<<myTypeid<<std::endl;
                FatalError(__LINE__);
            }

        }else{
            int lenName;
            read_cnt = fread((void*)(&lenName), sizeof(int), 1, fp);
            if (read_cnt!=1) return NULL;
            name.resize(lenName);
            if (lenName>0){
                read_cnt = fread((void*)(name.data()), sizeof(char), lenName, fp);
                if (read_cnt!=lenName) return NULL;
            }
            int nbDims;
            read_cnt = fread((void*)(&nbDims), sizeof(int), 1, fp);
            if (read_cnt!=1) return NULL;
            dim.resize(nbDims);
            if (nbDims>0){
                read_cnt = fread((void*)(&dim[0]), sizeof(int), nbDims, fp);
                if (read_cnt!=nbDims) return NULL;
            }

            size_t n = numel();
            Malloc(batch_size);
            read_cnt = fread((void*)(CPUmem), sizeof(T), n, fp);
            if (read_cnt!=n){
                delete [] CPUmem;
                CPUmem = NULL;
                return NULL;
            }
        }

        return CPUmem;
    };

    void Malloc(int batch_size){
        size_t n = numel();
        //std::cout<<"  ";        memorySizePrint(n*sizeof(T));   std::cout<<std::endl;

        if (batch_size==1 || dim[0]%batch_size ==0){
            CPUmem = new T [n];
        }else{
            int dim0 =  (dim[0]/batch_size + 1) * batch_size;
            size_t oversize = n/dim[0] * dim0;
            CPUmem = new T [oversize];
            memset((void*)(CPUmem+n),0, (oversize-n)*sizeof(T));
        }
    };

    T* read(std::string filename,int batch_size=1){
        FILE* fp = fopen(filename.c_str(),"rb");
        while (fp==NULL) {
            std::cerr<<"Tensor:read: fail to open file "<<filename<<". Please provide it first. Will retry after 5 seconds."<<std::endl;
            std::this_thread::sleep_for(std::chrono::seconds(5));
            fp = fopen(filename.c_str(),"rb");
        }
        read(fp,batch_size);
        fclose(fp);
        return CPUmem;
    };

    //write without header
    void writeHeader(FILE* fp, std::vector<int> dim2write){
        uint8_t myTypeid = typeID(typeid(T));
        fwrite((void*)(&myTypeid), sizeof(uint8_t), 1, fp);
        uint32_t typesizeof = uint32_t(sizeof(T));
        fwrite((void*)(&typesizeof), sizeof(uint32_t), 1, fp);
        int lenName = name.size();
        fwrite((void*)(&lenName), sizeof(int), 1, fp);
        if (lenName>0) fwrite((void*)(name.data()), sizeof(char), lenName, fp);
        int nbDims = dim2write.size();
        fwrite((void*)(&nbDims), sizeof(int), 1, fp);
        if (nbDims>0) fwrite((void*)(&dim2write[0]), sizeof(int), nbDims, fp);
        if (ferror (fp)){
            std::cerr << "disk writing failed"<<std::endl;
            FatalError();
        }
    };

    void writeData(FILE* fp, size_t max_size = 0){
        size_t n = numel();
        if (max_size !=0 ) n = min(n,max_size);
        if (n>0){
            fwrite((void*)(CPUmem), sizeof(T), n, fp);
            if (ferror (fp)){
                std::cerr << "disk writing failed" << std::endl;
                FatalError();
            }
        }
    };

    //support continuous write across many NdTensors
    //write with header
    void write(FILE* fp){
        writeHeader(fp,dim);
        writeData(fp);
    };

    void write(std::string filename){
        FILE* fp = fopen(filename.c_str(),"wb");
        while (fp==NULL) {
            std::cerr<<"Tensor::write: fail to open file "<<filename<<". Will retry after 5 seconds."<<std::endl;
            std::this_thread::sleep_for(std::chrono::seconds(5));
            fp = fopen(filename.c_str(),"wb");
        }
        write(fp);
        fclose(fp);
        return;
    };

    Tensor(std::string filename, int batch_size=1): CPUmem(NULL){ read(filename,batch_size); };

    Tensor(FILE* fp): CPUmem(NULL){ read(fp); };

    Tensor(std::vector<int> dim_): dim(dim_){ CPUmem = new T [numel()]; };

    Tensor(std::vector<int> dim_, T initValue): dim(dim_){
        int n = numel();
        CPUmem = new T [n];
        if (initValue == T(0))
            memset(CPUmem, 0, n*sizeof(T));
        else
            for (int i=0;i<n;++i) CPUmem[i] = initValue;

    };

    Tensor(std::string name_, std::vector<int> dim_): name(name_),dim(dim_){
        CPUmem = new T [numel()];
    };

    void permute(std::vector<size_t> v){
        size_t nbItems = numofitems();
        size_t sizeofitem_ = sizeofitem();
        size_t nbBytes = sizeofitem_ * sizeof(T);
        T* CPUmemNew = new T[numel()];
        memcpy(CPUmemNew, CPUmem, nbItems * nbBytes);
        for (size_t i=0;i<nbItems;++i){
            memcpy(CPUmem+i*sizeofitem_, CPUmemNew+v[i]*sizeofitem_, nbBytes);
        }
        delete [] CPUmemNew;
    };


    void printRange(){
        int n = numel();
        if (n==0){
            std::cout<<"Emtpy tensor"<<std::endl;
            return;
        }
        T maxValue = CPUmem[0];
        T minValue = CPUmem[0];

        for (int i=0;i<n;++i){
            if (maxValue<CPUmem[i])     maxValue=CPUmem[i];
            if (CPUmem[i]<minValue)     minValue=CPUmem[i];
        }
        std::cout<< "Value Range ["<<minValue<<", "<<maxValue<<"]"<<std::endl;
    };

    void print(std::vector<int> display_dim){

        std::cout<<"  name:"<<name<<" dim"; veciPrint(dim); std::cout<<std::endl;
        switch (display_dim.size()){
            case 1:
                for (int i=0;i<min((size_t)(display_dim[0]),numel());++i)
                    std::cout<<CPUmem[i]<<" ";
                std::cout<<std::endl;
                break;
            case 2:
                for (int i=0;i<display_dim[0];++i){
                    for (int j=0;j<display_dim[1];++j){
                        std::cout<<(CPUmem[i*dim[display_dim.size()-1]+j])<<" ";
                    }
                    std::cout<<std::endl;
                }
                break;
            case 3:
                for (int i=0;i<display_dim[0];++i){
                    for (int j=0;j<display_dim[1];++j){
                        for (int k=0;k<display_dim[2];++k){
                            std::cout<<CPUmem[i*dim[dim.size()-2]*dim[dim.size()-1]+j*dim[dim.size()-1]+k]<<" ";
                        }
                        std::cout<<std::endl;
                    }
                    std::cout<<std::endl;
                }
                break;
        }

    };
};

//////////////////////////////////////////////////////////////////////////////////////////////////
// CUDA kernels
//////////////////////////////////////////////////////////////////////////////////////////////////


#define CUDA_NUM_THREADS 512

#define MAX_NUM_BLOCKS 2880

inline int CUDA_GET_BLOCKS(const size_t N) {
    return min(MAX_NUM_BLOCKS, int((N + size_t(CUDA_NUM_THREADS) - 1) / CUDA_NUM_THREADS));
}

inline size_t CUDA_GET_LOOPS(const size_t N) {
    size_t total_threads = CUDA_GET_BLOCKS(N)*CUDA_NUM_THREADS;
    return (N + total_threads -1)/ total_threads;
}


__global__ void Kernel_set_value(size_t CUDA_NUM_LOOPS, size_t N, StorageT* GPUdst, StorageT value){
    const size_t idxBase = size_t(CUDA_NUM_LOOPS) * (size_t(CUDA_NUM_THREADS) * size_t(blockIdx.x) + size_t(threadIdx.x));
    if (idxBase >= N) return;
    for (size_t idx = idxBase; idx < min(N,idxBase+CUDA_NUM_LOOPS); ++idx ){
        GPUdst[idx] = value;
    }
}

void GPU_set_value(size_t N, StorageT* GPUdst, StorageT value){
    Kernel_set_value<<<CUDA_GET_BLOCKS(N), CUDA_NUM_THREADS>>>(CUDA_GET_LOOPS(N),N,GPUdst,value);
    checkCUDA(__LINE__,cudaGetLastError());
}

void GPU_set_ones(size_t N, StorageT* GPUdst){
    GPU_set_value(N, GPUdst, CPUCompute2StorageT(1));
}

void GPU_set_negones(size_t N, StorageT* GPUdst){
    GPU_set_value(N, GPUdst, CPUCompute2StorageT(-1));
}

void GPU_set_zeros(size_t N, StorageT* GPUdst){
    GPU_set_value(N, GPUdst, CPUCompute2StorageT(0));
}

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

            //v_new = 1.0 - fabs(v_new); // 1-tdf // comment this out if you want to use tsdf

            unsigned int idx = idx_offset + z;

            uint8_t w  = weight[idx];
            ComputeT v = GPUStorage2ComputeT(tsdf[idx]);

            tsdf[idx] = GPUCompute2StorageT(fmin(fmax((ComputeT(w)*v + v_new)/(ComputeT(w + 1)), -1.f), 1.f));
            weight[idx] = min(w+1,254);
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// main
//////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char **argv){

    if (argc < 5 || argc >13){
        std::cout<<"Usage:"<<std::endl;
        std::cout<<argv[0]<<" depthMaps.tensor intrinscis.tensor cameraRtW2C.tensor outTSDF.tensor [xMin] [xMax] [yMin] [yMax] [zMin] [zMax] [unit] [margin]"<<std::endl;
        return 0;
    }

    size_t memoryBytes = 0;

    Tensor<ComputeT>* depthMaps_CPU = new Tensor<ComputeT>(argv[1]);
    unsigned int numFrames = depthMaps_CPU->dim[0];
    unsigned int width  = depthMaps_CPU->dim[3];
    unsigned int height = depthMaps_CPU->dim[2];
    std::cout<<"depth maps ["<<numFrames<<", 1, "<<height<<", "<<width<<"]"<<std::endl;

    ComputeT* depthMaps_GPU;
    checkCUDA(__LINE__, cudaMalloc(&depthMaps_GPU, depthMaps_CPU->numBytes()) );    memoryBytes+=depthMaps_CPU->numBytes();
    checkCUDA(__LINE__, cudaMemcpy(depthMaps_GPU, depthMaps_CPU->CPUmem, depthMaps_CPU->numBytes(), cudaMemcpyHostToDevice) );
    delete depthMaps_CPU;


    Tensor<ComputeT>* intrinsics_CPU = new Tensor<ComputeT>(argv[2]);
    ComputeT* intrinsics_GPU;
    checkCUDA(__LINE__, cudaMalloc(&intrinsics_GPU, intrinsics_CPU->numBytes()) );    memoryBytes+=intrinsics_CPU->numBytes();
    checkCUDA(__LINE__, cudaMemcpy(intrinsics_GPU, intrinsics_CPU->CPUmem, intrinsics_CPU->numBytes(), cudaMemcpyHostToDevice) );
    delete intrinsics_CPU;

    Tensor<ComputeT>* cameraRtW2C_CPU = new Tensor<ComputeT>(argv[3]);
    ComputeT* cameraRtW2C_GPU;
    checkCUDA(__LINE__, cudaMalloc(&cameraRtW2C_GPU, cameraRtW2C_CPU->numBytes()) );    memoryBytes+=cameraRtW2C_CPU->numBytes();
    checkCUDA(__LINE__, cudaMemcpy(cameraRtW2C_GPU, cameraRtW2C_CPU->CPUmem, cameraRtW2C_CPU->numBytes(), cudaMemcpyHostToDevice) );
    delete cameraRtW2C_CPU;

    ComputeT xMin;   xMin   = (argc<=5? -0.05 : atof(argv[5] ));     std::cout<<"xMin  ="<<xMin<<std::endl;
    ComputeT xMax;   xMax   = (argc<=6?  0.03 : atof(argv[6] ));     std::cout<<"xMax  ="<<xMax<<std::endl;
    ComputeT yMin;   yMin   = (argc<=7? -0.15 : atof(argv[7] ));     std::cout<<"yMin  ="<<yMin<<std::endl;
    ComputeT yMax;   yMax   = (argc<=8?  0.03 : atof(argv[8] ));     std::cout<<"yMax  ="<<yMax<<std::endl;
    ComputeT zMin;   zMin   = (argc<=9?  0.33 : atof(argv[9] ));     std::cout<<"zMin  ="<<zMin<<std::endl;
    ComputeT zMax;   zMax   = (argc<=10? 0.42 : atof(argv[10]));     std::cout<<"zMax  ="<<zMax<<std::endl;
    ComputeT unit;   unit   = (argc<=11? 0.002 : atof(argv[11]));    std::cout<<"unit  ="<<unit<<std::endl;
    ComputeT margin; margin = (argc<=12? 0.01 : atof(argv[12]));     std::cout<<"margin="<<margin<<std::endl;

    unsigned int xSize = round((xMax-xMin)/unit);
    unsigned int ySize = round((yMax-yMin)/unit);
    unsigned int zSize = round((zMax-zMin)/unit);

    std::cout<<"TSDF resolution: "<<xSize<<"x"<<ySize<<"x"<<zSize<<std::endl;

    StorageT* tsdf_GPU;  checkCUDA(__LINE__, cudaMalloc(&tsdf_GPU,  xSize*ySize*zSize*sizeofStorageT) );    memoryBytes+=xSize*ySize*zSize*sizeofStorageT;
    uint8_t* weight_GPU; checkCUDA(__LINE__, cudaMalloc(&weight_GPU,xSize*ySize*zSize*sizeof(uint8_t)));    memoryBytes+=xSize*ySize*zSize*sizeof(uint8_t);

    std::cout<<"Total GPU memory: ";    memorySizePrint(memoryBytes); std::cout<<std::endl;

    GPU_set_negones(xSize*ySize*zSize, tsdf_GPU);
    checkCUDA(__LINE__, cudaMemset(weight_GPU, 0, sizeof(uint8_t)*xSize*ySize*zSize));

    for (unsigned int f=0;f<numFrames;++f){
        Kernel_integrate<<<xSize,ySize>>>(xSize, ySize, zSize, xMin, yMin, zMin, unit, margin, width, height, 
            depthMaps_GPU+width*height*f, cameraRtW2C_GPU+3*4*f, intrinsics_GPU, tsdf_GPU, weight_GPU);
    }

    std::vector<int> dim;
    dim.push_back(xSize);
    dim.push_back(ySize);
    dim.push_back(zSize);
    Tensor<StorageT>* tsdf_CPU = new Tensor<StorageT>(dim);
    tsdf_CPU->readGPU(tsdf_GPU);
    FILE* fp = fopen(argv[4],"wb");
    tsdf_CPU->write(fp);
    fclose(fp);
    delete tsdf_CPU;  

    if (tsdf_GPU!=NULL) checkCUDA(__LINE__, cudaFree(tsdf_GPU));
    if (weight_GPU!=NULL) checkCUDA(__LINE__, cudaFree(weight_GPU));
    if (depthMaps_GPU!=NULL) checkCUDA(__LINE__, cudaFree(depthMaps_GPU));
    if (cameraRtW2C_GPU!=NULL) checkCUDA(__LINE__, cudaFree(cameraRtW2C_GPU));
    if (intrinsics_GPU!=NULL) checkCUDA(__LINE__, cudaFree(intrinsics_GPU));

    return 0;
}
