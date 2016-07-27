//lightweight Oni matlab reader by Jianxiong Xiao

//#define XN_PLATFORM 5
//#define linux 1
//#define __x86_64__ 1

#include <string.h>
#include <math.h>
#include <XnCppWrapper.h>
#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <stdio.h>
#include <sys/types.h>
#include <sys/dir.h>

//#include "mex.h"

using namespace cv;
using namespace xn;
using namespace std;

#define DEPTH_MAP_HEIGHT  480
#define DEPTH_MAP_WIDTH   640
#define IMAGE_HEIGHT      480
#define IMAGE_WIDTH       640

// #define DEPTH_MAP_HEIGHT  240
// #define DEPTH_MAP_WIDTH   320
// #define IMAGE_HEIGHT      240
// #define IMAGE_WIDTH       320

int main(int argc,char *argv[]){

  Context g_context;
  DepthGenerator g_depth;
  ImageGenerator g_image;
  DepthMetaData g_depthMD;
  ImageMetaData g_imageMD;
  XnStatus rc;
  Player xPlayer;

  string oni_file_path(argv[1]);
  string output_folder = oni_file_path.substr(0, oni_file_path.length() - 4);
  rc = g_context.Init();
  rc = g_context.OpenFileRecording(oni_file_path.c_str(), xPlayer);
  xPlayer.SetRepeat( false );

  mkdir(output_folder.c_str(), 0777);
  char directory_name[256];
  sprintf(directory_name, "%s/depth", output_folder.c_str());
  mkdir(directory_name, 0777);
  sprintf(directory_name, "%s/image", output_folder.c_str());
  mkdir(directory_name, 0777);

  if (rc == XN_STATUS_NO_NODE_PRESENT)
  {
    printf("XN_STATUS_NO_NODE_PRESENT\n");
    return -1;
  }
  else if (rc != XN_STATUS_OK)
  {
    printf("Open failed: %s\n", xnGetStatusString(rc));
    return -1;
  }

  rc = g_context.FindExistingNode(XN_NODE_TYPE_DEPTH, g_depth);
  if (rc != XN_STATUS_OK)
  {
    printf("No depth node exists! Check your XML.");
    return -1;
  }

  rc = g_context.FindExistingNode(XN_NODE_TYPE_IMAGE, g_image);
  if (rc != XN_STATUS_OK)
  {
    printf("No image node exists! Check your XML.");
    return -1;
  }


  XnUInt32 uFrames;
  xPlayer.GetNumFrames( g_depth.GetName(), uFrames );
  int framesDepth = uFrames;
  xPlayer.GetNumFrames( g_image.GetName(), uFrames );
  int framesImage = uFrames;

  printf("# of frames: depth=%d, image=%d\n", framesDepth, framesImage);

  if (framesImage>framesDepth){
    framesImage=framesDepth;
  }

  XnFieldOfView g_fov;
  g_depth.GetFieldOfView(g_fov);
  //printf("fov: h=%f, v=%f\n", g_fov.fHFOV, g_fov.fVFOV);

  float fx = DEPTH_MAP_WIDTH / 2 / tan(g_fov.fHFOV / 2);
  float fy = DEPTH_MAP_HEIGHT / 2 / tan(g_fov.fVFOV / 2);
  float cx = DEPTH_MAP_WIDTH / 2;
  float cy = DEPTH_MAP_HEIGHT / 2;

  FILE * pFile;
  char intrinsics_file[256];
  sprintf(intrinsics_file, "%s/intrinsics.txt", output_folder.c_str());
  pFile = fopen (intrinsics_file,"w");
  fprintf (pFile, "%f 0 %f\n", fx, cx);
  fprintf (pFile, "0 %f %f\n", fy, cy);
  fprintf (pFile, "0 0 1");
  fclose (pFile);

  int depthCnt = 0;
  int imageCnt = 0;
  XnUInt32 prevFrameIDdepth = 0;
  XnUInt32 prevFrameIDimage = 0;

  while(depthCnt<framesDepth || imageCnt<framesImage){

    rc = g_context.WaitAnyUpdateAll();
    if (rc != XN_STATUS_OK)
    {
      printf("Read Finished Before Frames filled: %s\n", xnGetStatusString(rc));
      break;
    }

    XnUInt32 currFrameIDdepth = g_depth.GetFrameID();

    if (currFrameIDdepth>prevFrameIDdepth ){
      if (depthCnt<framesDepth){
        // fetch depth map
        printf("read depth %d\n",currFrameIDdepth);
        prevFrameIDdepth = currFrameIDdepth;
        XnUInt32 depthTimestamp = g_depth.GetTimestamp();
        g_depth.GetMetaData(g_depthMD);
        //printf("PixelFormat=%d\n", g_depthMD.PixelFormat());
        const XnDepthPixel* pDepth = g_depthMD.Data();
        int sizes[2] = {DEPTH_MAP_HEIGHT, DEPTH_MAP_WIDTH};
        Mat cv_depth = Mat(2, sizes, CV_16UC1, (void*) pDepth);

        // convert the depth map to sun3d format
        for (int i = 0; i < sizes[0]; i++){
          for (int j = 0; j < sizes[1]; j++){
              cv_depth.at<short>(i,j) = cv_depth.at<short>(i,j) >> 13 | cv_depth.at<short>(i,j) << 3;
          }
        }

        // save depth map
        char depth_name[100];
        sprintf(depth_name, "%s/depth/%07d-%012d.png", output_folder.c_str(), currFrameIDdepth, depthTimestamp);
        imwrite(depth_name, cv_depth);
        printf("depth saved \n");

        ++depthCnt;
      }else{
          printf("ignore depth %d\n",currFrameIDdepth);
      }
    }


    XnUInt32 currFrameIDimage = g_image.GetFrameID();

    if (currFrameIDimage>prevFrameIDimage){
      if (imageCnt<framesImage){
        // fetch rgb image
        printf("read image %d\n",currFrameIDimage);
        prevFrameIDimage = currFrameIDimage;
        XnUInt32 imageTimestamp = g_image.GetTimestamp();
        g_image.GetMetaData(g_imageMD);
        const XnRGB24Pixel* pImage = g_imageMD.RGB24Data();
        int sizes[2] = {IMAGE_HEIGHT, IMAGE_WIDTH};
        Mat cv_image = Mat(2, sizes, CV_8UC3, (void*) pImage);
        cvtColor(cv_image, cv_image, CV_RGB2BGR); //convert to OpenCV BGR color space

        // save rgb image
        char rgb_name[100];
        sprintf(rgb_name, "%s/image/%07d-%012d.jpg", output_folder.c_str(), currFrameIDimage, imageTimestamp);
        imwrite(rgb_name, cv_image);

        printf("rgb saved \n");

        ++imageCnt;
      }else{
          printf("ignore image %d\n",currFrameIDimage);
      }
    }
  }
  return 0;
}
