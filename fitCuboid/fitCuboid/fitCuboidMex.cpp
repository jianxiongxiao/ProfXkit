#include "mex.h"
#include <cmath>
#include <cstdio>
#include <iostream>
#include "ceres/ceres.h"
#include "ceres/rotation.h"

/*
Author:
Jianxiong Xiao: http://mit.edu/jxiao/

Citation:
Please cite the following paper if you use this code in all possible ways.

@inproceedings{CuboidDetector,
 author = "Jianxiong Xiao and Bryan C. Russell and Antonio Torralba",
 title = "Localizing 3D Cuboids in Single-view Images",
 booktitle = "Advances in Neural Information Processing Systems (NIPS)",
 year = "2012",
 month = "December",
 address = "Lake Tahoe, USA"
}
*/

/*
 *
 * y
 * ^
 * |
 * |    2-------------7
 * |    |\             \
 * |    | 1-------------4
 * |    | |             |
 * |    5 |             |
 * |     \|             |
 * |      3-------------6
 * |
 * |
 * +----------------------------->x
 * /
 * /
 * /
 * L
 * z
 *
 * X = [-1    -1     -1     1     -1      1      1;
 * 1     1     -1     1     -1     -1      1;
 * 1    -1      1     1     -1      1     -1];
 */

#define CAM_F  parameter[0]
#define CAM_PX parameter[1]
#define CAM_PY parameter[2]
#define CAM_TX parameter[3]
#define CAM_TY parameter[4]
#define CAM_TZ parameter[5]
#define CAM_H  parameter[6]
#define CAM_W  parameter[7]

#define CAM_RX parameter[8]
#define CAM_RY parameter[9]
#define CAM_RZ parameter[10]
#define EPS T(0.00001)

template <typename T>
void reprojectAll(const T* const parameter, T* reprojection){
    
     T t2 = -CAM_H-CAM_TX;    T t3 = CAM_H  -CAM_TX;
     T t4 =  CAM_W-CAM_TY;    T t5 = -CAM_W -CAM_TY;
     T t6 =    1.0-CAM_TZ;    T t7 = -1.0   -CAM_TZ;    
     T point[3];  T p[3];   const T* const rotation = parameter+8;
     // 1
     point[0] = t2;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[0] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[1] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 2
     point[0] = t2;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[2] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[3] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 3
     point[0] = t2;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[4] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[5] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 4
     point[0] = t3;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[6] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[7] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 5
     point[0] = t2;  point[1] = t5;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[8] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[9] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 6
     point[0] = t3;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[10] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[11] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 7
     point[0] = t3;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[12] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[13] = CAM_F * p[1]/p[2] + CAM_PY;     
  

     //std::cout<<"point ="<<point[0] <<" "<<point[1] <<" "<<point[2] <<std::endl;     
     //std::cout<<"p ="<<p[0] <<" "<<p[1] <<" "<<p[2] <<std::endl;     
     /*
        std::cout<<"CAM_F ="<<CAM_F <<std::endl;
        std::cout<<"CAM_PX="<<CAM_PX<<std::endl;
        std::cout<<"CAM_PY="<<CAM_PY<<std::endl;
        std::cout<<"CAM_TX="<<CAM_TX<<std::endl;
        std::cout<<"CAM_TY="<<CAM_TY<<std::endl;
        std::cout<<"CAM_TZ="<<CAM_TZ<<std::endl;
        std::cout<<"CAM_H ="<<CAM_H <<std::endl;
        std::cout<<"CAM_W ="<<CAM_W <<std::endl;
        std::cout<<"CAM_RX="<<CAM_RX<<std::endl;
        std::cout<<"CAM_RY="<<CAM_RY<<std::endl;
        std::cout<<"CAM_RZ="<<CAM_RZ<<std::endl;


        std::cout<<"reprojection:"<<std::endl;
        std::cout<<reprojection[0]<<"\t"<<reprojection[1]<<std::endl;
        std::cout<<reprojection[2]<<"\t"<<reprojection[3]<<std::endl;
        std::cout<<reprojection[4]<<"\t"<<reprojection[5]<<std::endl;
        std::cout<<reprojection[6]<<"\t"<<reprojection[7]<<std::endl;
        std::cout<<reprojection[8]<<"\t"<<reprojection[9]<<std::endl;
        std::cout<<reprojection[10]<<"\t"<<reprojection[11]<<std::endl;
        std::cout<<reprojection[12]<<"\t"<<reprojection[13]<<std::endl;
      */
}

template <typename T>
void reproject1(const T* const parameter, T* reprojection){
     T t2 = -CAM_H-CAM_TX;    T t3 = CAM_H  -CAM_TX;
     T t4 =  CAM_W-CAM_TY;    T t5 = -CAM_W -CAM_TY;
     T t6 =    1.0-CAM_TZ;    T t7 = -1.0   -CAM_TZ;    
     T point[3];  T p[3];   const T* const rotation = parameter+8;
     // 1
     //point[0] = t2;  point[1] = t4;  point[2] = t6;
     //ceres::AngleAxisRotatePoint(rotation, point, p);
     //reprojection[0] = CAM_F * p[0]/p[2] + CAM_PX;
     //reprojection[1] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 2
     point[0] = t2;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[0] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[1] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 3
     point[0] = t2;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[2] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[3] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 4
     point[0] = t3;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[4] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[5] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 5
     point[0] = t2;  point[1] = t5;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[6] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[7] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 6
     point[0] = t3;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[8] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[9] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 7
     point[0] = t3;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[10] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[11] = CAM_F * p[1]/p[2] + CAM_PY;       
}

template <typename T>
void reproject2(const T* const parameter, T* reprojection){
     T t2 = -CAM_H-CAM_TX;    T t3 = CAM_H  -CAM_TX;
     T t4 =  CAM_W-CAM_TY;    T t5 = -CAM_W -CAM_TY;
     T t6 =    1.0-CAM_TZ;    T t7 = -1.0   -CAM_TZ;    
     T point[3];  T p[3];   const T* const rotation = parameter+8;
     // 1
     point[0] = t2;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[0] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[1] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 2
     //point[0] = t2;  point[1] = t4;  point[2] = t7;
     //ceres::AngleAxisRotatePoint(rotation, point, p);
     //reprojection[2] = CAM_F * p[0]/p[2] + CAM_PX;
     //reprojection[3] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 3
     point[0] = t2;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[2] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[3] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 4
     point[0] = t3;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[4] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[5] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 5
     point[0] = t2;  point[1] = t5;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[6] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[7] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 6
     point[0] = t3;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[8] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[9] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 7
     point[0] = t3;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[10] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[11] = CAM_F * p[1]/p[2] + CAM_PY; 
}

template <typename T>
void reproject3(const T* const parameter, T* reprojection){
     T t2 = -CAM_H-CAM_TX;    T t3 = CAM_H  -CAM_TX;
     T t4 =  CAM_W-CAM_TY;    T t5 = -CAM_W -CAM_TY;
     T t6 =    1.0-CAM_TZ;    T t7 = -1.0   -CAM_TZ;    
     T point[3];  T p[3];   const T* const rotation = parameter+8;
     // 1
     point[0] = t2;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[0] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[1] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 2
     point[0] = t2;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[2] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[3] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 3
     //point[0] = t2;  point[1] = t5;  point[2] = t6;
     //ceres::AngleAxisRotatePoint(rotation, point, p);
     //reprojection[4] = CAM_F * p[0]/p[2] + CAM_PX;
     //reprojection[5] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 4
     point[0] = t3;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[4] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[5] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 5
     point[0] = t2;  point[1] = t5;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[6] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[7] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 6
     point[0] = t3;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[8] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[9] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 7
     point[0] = t3;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[10] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[11] = CAM_F * p[1]/p[2] + CAM_PY; 
}

template <typename T>
void reproject4(const T* const parameter, T* reprojection){
     T t2 = -CAM_H-CAM_TX;    T t3 = CAM_H  -CAM_TX;
     T t4 =  CAM_W-CAM_TY;    T t5 = -CAM_W -CAM_TY;
     T t6 =    1.0-CAM_TZ;    T t7 = -1.0   -CAM_TZ;    
     T point[3];  T p[3];   const T* const rotation = parameter+8;
     // 1
     point[0] = t2;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[0] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[1] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 2
     point[0] = t2;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[2] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[3] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 3
     point[0] = t2;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[4] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[5] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 4
     //point[0] = t3;  point[1] = t4;  point[2] = t6;
     //ceres::AngleAxisRotatePoint(rotation, point, p);
     //reprojection[6] = CAM_F * p[0]/p[2] + CAM_PX;
     //reprojection[7] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 5
     point[0] = t2;  point[1] = t5;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[6] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[7] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 6
     point[0] = t3;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[8] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[9] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 7
     point[0] = t3;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[10] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[11] = CAM_F * p[1]/p[2] + CAM_PY; 
}

template <typename T>
void reproject5(const T* const parameter, T* reprojection){
     T t2 = -CAM_H-CAM_TX;    T t3 = CAM_H  -CAM_TX;
     T t4 =  CAM_W-CAM_TY;    T t5 = -CAM_W -CAM_TY;
     T t6 =    1.0-CAM_TZ;    T t7 = -1.0   -CAM_TZ;    
     T point[3];  T p[3];   const T* const rotation = parameter+8;
     // 1
     point[0] = t2;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[0] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[1] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 2
     point[0] = t2;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[2] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[3] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 3
     point[0] = t2;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[4] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[5] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 4
     point[0] = t3;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[6] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[7] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 5
     //point[0] = t2;  point[1] = t5;  point[2] = t7;
     //ceres::AngleAxisRotatePoint(rotation, point, p);
     //reprojection[8] = CAM_F * p[0]/p[2] + CAM_PX;
     //reprojection[9] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 6
     point[0] = t3;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[8] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[9] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 7
     point[0] = t3;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[10] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[11] = CAM_F * p[1]/p[2] + CAM_PY; 
}

template <typename T>
void reproject6(const T* const parameter, T* reprojection){
     T t2 = -CAM_H-CAM_TX;    T t3 = CAM_H  -CAM_TX;
     T t4 =  CAM_W-CAM_TY;    T t5 = -CAM_W -CAM_TY;
     T t6 =    1.0-CAM_TZ;    T t7 = -1.0   -CAM_TZ;    
     T point[3];  T p[3];   const T* const rotation = parameter+8;
     // 1
     point[0] = t2;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[0] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[1] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 2
     point[0] = t2;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[2] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[3] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 3
     point[0] = t2;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[4] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[5] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 4
     point[0] = t3;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[6] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[7] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 5
     point[0] = t2;  point[1] = t5;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[8] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[9] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 6
     //point[0] = t3;  point[1] = t5;  point[2] = t6;
     //ceres::AngleAxisRotatePoint(rotation, point, p);
     //reprojection[10] = CAM_F * p[0]/p[2] + CAM_PX;
     //reprojection[11] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 7
     point[0] = t3;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[10] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[11] = CAM_F * p[1]/p[2] + CAM_PY; 
}

template <typename T>
void reproject7(const T* const parameter, T* reprojection){
     T t2 = -CAM_H-CAM_TX;    T t3 = CAM_H  -CAM_TX;
     T t4 =  CAM_W-CAM_TY;    T t5 = -CAM_W -CAM_TY;
     T t6 =    1.0-CAM_TZ;    T t7 = -1.0   -CAM_TZ;    
     T point[3];  T p[3];   const T* const rotation = parameter+8;
     // 1
     point[0] = t2;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[0] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[1] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 2
     point[0] = t2;  point[1] = t4;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[2] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[3] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 3
     point[0] = t2;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[4] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[5] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 4
     point[0] = t3;  point[1] = t4;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[6] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[7] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 5
     point[0] = t2;  point[1] = t5;  point[2] = t7;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[8] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[9] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 6
     point[0] = t3;  point[1] = t5;  point[2] = t6;
     ceres::AngleAxisRotatePoint(rotation, point, p);
     if (T(0.0)<=p[2])
         if(p[2]<EPS)
             p[2] = EPS;
     else 
         if (p[2]>-EPS)
             p[2] = -EPS;
     reprojection[10] = CAM_F * p[0]/p[2] + CAM_PX;
     reprojection[11] = CAM_F * p[1]/p[2] + CAM_PY;     
     // 7
     //point[0] = t3;  point[1] = t4;  point[2] = t7;
     //ceres::AngleAxisRotatePoint(rotation, point, p);
     //reprojection[12] = CAM_F * p[0]/p[2] + CAM_PX;
     //reprojection[13] = CAM_F * p[1]/p[2] + CAM_PY; 
}

struct CuboidErrorAll {
    CuboidErrorAll(double* observed_in): observed(observed_in) {}
    template <typename T>
    bool operator()(const T* const parameter, T* residuals) const {
        try{
            reprojectAll<T>(parameter,residuals);
        }catch(int err){
        }
        residuals[0] = residuals[0] - observed[0];
        residuals[1] = residuals[1] - observed[1];
        residuals[2] = residuals[2] - observed[2];
        residuals[3] = residuals[3] - observed[3];
        residuals[4] = residuals[4] - observed[4];
        residuals[5] = residuals[5] - observed[5];
        residuals[6] = residuals[6] - observed[6];
        residuals[7] = residuals[7] - observed[7];
        residuals[8] = residuals[8] - observed[8];
        residuals[9] = residuals[9] - observed[9];
        residuals[10] = residuals[10] - observed[10];
        residuals[11] = residuals[11] - observed[11];
        residuals[12] = residuals[12] - observed[12];
        residuals[13] = residuals[13] - observed[13];
        return true;
    }
    double* observed;
};

struct CuboidError1 {
    CuboidError1(double* observed_in): observed(observed_in) {}
    template <typename T>
    bool operator()(const T* const parameter, T* residuals) const {
        reproject1<T>(parameter,residuals);
        residuals[0] = residuals[0] - observed[2];
        residuals[1] = residuals[1] - observed[3];
        residuals[2] = residuals[2] - observed[4];
        residuals[3] = residuals[3] - observed[5];
        residuals[4] = residuals[4] - observed[6];
        residuals[5] = residuals[5] - observed[7];
        residuals[6] = residuals[6] - observed[8];
        residuals[7] = residuals[7] - observed[9];
        residuals[8] = residuals[8] - observed[10];
        residuals[9] = residuals[9] - observed[11];
        residuals[10] = residuals[10] - observed[12];
        residuals[11] = residuals[11] - observed[13];
        return true;
    }
    double* observed;
};

struct CuboidError2 {
    CuboidError2(double* observed_in): observed(observed_in) {}
    template <typename T>
    bool operator()(const T* const parameter, T* residuals) const {
        reproject2<T>(parameter,residuals);
        residuals[0] = residuals[0] - observed[0];
        residuals[1] = residuals[1] - observed[1];
        residuals[2] = residuals[2] - observed[4];
        residuals[3] = residuals[3] - observed[5];
        residuals[4] = residuals[4] - observed[6];
        residuals[5] = residuals[5] - observed[7];
        residuals[6] = residuals[6] - observed[8];
        residuals[7] = residuals[7] - observed[9];
        residuals[8] = residuals[8] - observed[10];
        residuals[9] = residuals[9] - observed[11];
        residuals[10] = residuals[10] - observed[12];
        residuals[11] = residuals[11] - observed[13];
        return true;
    }
    double* observed;
};

struct CuboidError3 {
    CuboidError3(double* observed_in): observed(observed_in) {}
    template <typename T>
    bool operator()(const T* const parameter, T* residuals) const {
        reproject3<T>(parameter,residuals);
        residuals[0] = residuals[0] - observed[0];
        residuals[1] = residuals[1] - observed[1];
        residuals[2] = residuals[2] - observed[2];
        residuals[3] = residuals[3] - observed[3];
        residuals[4] = residuals[4] - observed[6];
        residuals[5] = residuals[5] - observed[7];
        residuals[6] = residuals[6] - observed[8];
        residuals[7] = residuals[7] - observed[9];
        residuals[8] = residuals[8] - observed[10];
        residuals[9] = residuals[9] - observed[11];
        residuals[10] = residuals[10] - observed[12];
        residuals[11] = residuals[11] - observed[13];
        return true;
    }
    double* observed;
};

struct CuboidError4 {
    CuboidError4(double* observed_in): observed(observed_in) {}
    template <typename T>
    bool operator()(const T* const parameter, T* residuals) const {
        reproject4<T>(parameter,residuals);
        residuals[0] = residuals[0] - observed[0];
        residuals[1] = residuals[1] - observed[1];
        residuals[2] = residuals[2] - observed[2];
        residuals[3] = residuals[3] - observed[3];
        residuals[4] = residuals[4] - observed[4];
        residuals[5] = residuals[5] - observed[5];
        residuals[6] = residuals[6] - observed[8];
        residuals[7] = residuals[7] - observed[9];
        residuals[8] = residuals[8] - observed[10];
        residuals[9] = residuals[9] - observed[11];
        residuals[10] = residuals[10] - observed[12];
        residuals[11] = residuals[11] - observed[13];
        return true;
    }
    double* observed;
};

struct CuboidError5 {
    CuboidError5(double* observed_in): observed(observed_in) {}
    template <typename T>
    bool operator()(const T* const parameter, T* residuals) const {
        reproject5<T>(parameter,residuals);
        residuals[0] = residuals[0] - observed[0];
        residuals[1] = residuals[1] - observed[1];
        residuals[2] = residuals[2] - observed[2];
        residuals[3] = residuals[3] - observed[3];
        residuals[4] = residuals[4] - observed[4];
        residuals[5] = residuals[5] - observed[5];
        residuals[6] = residuals[6] - observed[6];
        residuals[7] = residuals[7] - observed[7];
        residuals[8] = residuals[8] - observed[10];
        residuals[9] = residuals[9] - observed[11];
        residuals[10] = residuals[10] - observed[12];
        residuals[11] = residuals[11] - observed[13];
        return true;
    }
    double* observed;
};

struct CuboidError6 {
    CuboidError6(double* observed_in): observed(observed_in) {}
    template <typename T>
    bool operator()(const T* const parameter, T* residuals) const {
        reproject6<T>(parameter,residuals);
        residuals[0] = residuals[0] - observed[0];
        residuals[1] = residuals[1] - observed[1];
        residuals[2] = residuals[2] - observed[2];
        residuals[3] = residuals[3] - observed[3];
        residuals[4] = residuals[4] - observed[4];
        residuals[5] = residuals[5] - observed[5];
        residuals[6] = residuals[6] - observed[6];
        residuals[7] = residuals[7] - observed[7];
        residuals[8] = residuals[8] - observed[8];
        residuals[9] = residuals[9] - observed[9];
        residuals[10] = residuals[10] - observed[12];
        residuals[11] = residuals[11] - observed[13];
        return true;
    }
    double* observed;
};

struct CuboidError7 {
    CuboidError7(double* observed_in): observed(observed_in) {}
    template <typename T>
    bool operator()(const T* const parameter, T* residuals) const {
        reproject7<T>(parameter,residuals);
        residuals[0] = residuals[0] - observed[0];
        residuals[1] = residuals[1] - observed[1];
        residuals[2] = residuals[2] - observed[2];
        residuals[3] = residuals[3] - observed[3];
        residuals[4] = residuals[4] - observed[4];
        residuals[5] = residuals[5] - observed[5];
        residuals[6] = residuals[6] - observed[6];
        residuals[7] = residuals[7] - observed[7];
        residuals[8] = residuals[8] - observed[8];
        residuals[9] = residuals[9] - observed[9];
        residuals[10] = residuals[10] - observed[10];
        residuals[11] = residuals[11] - observed[11];
        return true;
    }
    double* observed;
};





void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    double* observed  = mxGetPr(prhs[0]);
    double* parameter = mxGetPr(prhs[1]);
    double* rotation  = mxGetPr(prhs[2]);
    int option = (int)mxGetScalar(prhs[3]);
    ceres::Problem problem;
    ceres::LossFunction* loss_function = NULL; // squared loss
    //ceres::LossFunction* loss_function = new ceres::HuberLoss(1.0);
    
    /*
    std::cout<<"rotation: "<<std::endl;
    std::cout<<rotation[0]<<" "<<rotation[3]<<" "<<rotation[6]<<std::endl;
    std::cout<<rotation[1]<<" "<<rotation[4]<<" "<<rotation[7]<<std::endl;
    std::cout<<rotation[2]<<" "<<rotation[5]<<" "<<rotation[8]<<std::endl;    
    */
    
    // Conversions between 3x3 rotation matrix (in column major order) and
    // axis-angle rotation representations.  Templated for use with
    // autodifferentiation.
    ceres::RotationMatrixToAngleAxis<double>(rotation, parameter+8);    
    
    /*
    std::cout<<"rotation: ";
    std::cout<<parameter[8]<<",";
    std::cout<<parameter[9]<<",";
    std::cout<<parameter[10]<<std::endl;
    ceres::AngleAxisToRotationMatrix(parameter+8, rotation);
    std::cout<<"rotation: "<<std::endl;
    std::cout<<rotation[0]<<" "<<rotation[3]<<" "<<rotation[6]<<std::endl;
    std::cout<<rotation[1]<<" "<<rotation[4]<<" "<<rotation[7]<<std::endl;
    std::cout<<rotation[2]<<" "<<rotation[5]<<" "<<rotation[8]<<std::endl;
     */    
    
    ceres::CostFunction* cost_function;
    switch(option){
        case 1:
            cost_function = new ceres::AutoDiffCostFunction<CuboidError1, 12, 11>(new CuboidError1(observed));
            break;
        case 2:
            cost_function = new ceres::AutoDiffCostFunction<CuboidError2, 12, 11>(new CuboidError2(observed));
            break;
        case 3:
            cost_function = new ceres::AutoDiffCostFunction<CuboidError3, 12, 11>(new CuboidError3(observed));
            break;
        case 4:
            cost_function = new ceres::AutoDiffCostFunction<CuboidError4, 12, 11>(new CuboidError4(observed));
            break;
        case 5:
            cost_function = new ceres::AutoDiffCostFunction<CuboidError5, 12, 11>(new CuboidError5(observed));
            break;
        case 6:
            cost_function = new ceres::AutoDiffCostFunction<CuboidError6, 12, 11>(new CuboidError6(observed));
            break;
        case 7:
            cost_function = new ceres::AutoDiffCostFunction<CuboidError7, 12, 11>(new CuboidError7(observed));
            break;
        case 8:
            cost_function = new ceres::AutoDiffCostFunction<CuboidErrorAll, 14, 11>(new CuboidErrorAll(observed));
            break;
    }
    
    problem.AddResidualBlock(cost_function,loss_function,parameter);
    
    // Make Ceres automatically detect the bundle structure. Note that the
    // standard solver, SPARSE_NORMAL_CHOLESKY, also works fine but it is slower for standard bundle adjustment problems.
    ceres::Solver::Options options;
    options.max_num_iterations = 50;
    options.linear_solver_type = ceres::DENSE_SCHUR;
    options.ordering_type = ceres::SCHUR;
    options.minimizer_progress_to_stdout = false;
    
    
    ceres::Solver::Summary summary;
    ceres::Solve(options, &problem, &summary);
    //std::cout << summary.BriefReport() << std::endl;
    //std::cout << summary.FullReport() << std::endl;

    
    plhs[1] = mxCreateDoubleScalar(summary.final_cost);
    plhs[0] = mxCreateDoubleMatrix(2, 7, mxREAL);
    reprojectAll<double>(parameter, mxGetPr(plhs[0]));
    
    //if (cost_function!=NULL){
    //    delete cost_function;    
    //}
}

