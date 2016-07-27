/*
% install lOSMesa
% compile
% mex RenderPCcamera.cpp -lGLU -lOSMesa
% or
% mex RenderPCcamera.cpp -lGLU -lOSMesa -I/media/Data/usr/Mesa-9.1.2/include
% on mac:
% mex RenderPCcamera.cpp -lGLU -lOSMesa -I/opt/X11/include/ -L/opt/X11/lib/
*/

/*

This code is to render a Mesh given a 3x4 camera matrix with an image resolution widthxheight. The rendering result is an ID map for facets, edges and vertices. This can usually used for occlusion testing in texture mapping a model from an image, such as the texture mapping in the following two papers.

--Jianxiong Xiao http://mit.edu/jxiao/

Citation:

[1] J. Xiao, T. Fang, P. Zhao, M. Lhuillier, and L. Quan
Image-based Street-side City Modeling
ACM Transaction on Graphics (TOG), Volume 28, Number 5
Proceedings of ACM SIGGRAPH Asia 2009

[2] J. Xiao, T. Fang, P. Tan, P. Zhao, E. Ofek, and L. Quan
Image-based Facade Modeling
ACM Transaction on Graphics (TOG), Volume 27, Number 5
Proceedings of ACM SIGGRAPH Asia 2008

*/

#include "mex.h" 
#include <string.h>
#include <math.h>
#include <GL/osmesa.h>
#include <GL/glu.h>


unsigned int uchar2uint(unsigned char* in){
  unsigned int out = (((unsigned int)(in[0])) << 16) + (((unsigned int)(in[1])) << 8) + ((unsigned int)(in[2]));
  return out;
}


void uint2uchar(unsigned int in, unsigned char* out){
  out[0] = (in & 0x00ff0000) >> 16;
  out[1] = (in & 0x0000ff00) >> 8;
  out[2] =  in & 0x000000ff;
  
  //mexPrintf("%d=>[%d,%d,%d]=>%d\n",in,out[0],out[1],out[2], uchar2uint(out));
}

// Input: 
//     arg0: 3x4 Projection matrix, 
//     arg1: image width, 
//     arg2: image height, 
//     arg3: 3*N double matrix for the coordinates of N 3D pioints
//     arg4: 3*N uint8 matrix for the RGB colors of the N points
//     arg5: 
// Output: you will need to transpose the result in Matlab manually. see the demo

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  //mexPrintf("RenderMex\n"); 

  float m_near = 0.3;
  float m_far = 1e8;
  int m_level = 0;
  

  double* projection = mxGetPr(prhs[0]);    //     arg0: 3x4 Projection matrix, 
  int m_width = (int)mxGetScalar(prhs[1]);  //     arg1: image width,
  int m_height = (int)mxGetScalar(prhs[2]); //     arg2: image height, 
  unsigned int  num_points = mxGetN(prhs[3]);
  double*       vertex = mxGetPr(prhs[3]);  //     3 x N double vertices matrix
  unsigned char* color = (unsigned char*) mxGetData(prhs[4]);
  
  unsigned int  num_edges  = mxGetN(prhs[5]);
  double*       vertexEdge = mxGetPr(prhs[5]);  //     3 x N double vertices matrix
  unsigned char* colorEdge = (unsigned char*) mxGetData(prhs[6]);
  
  
  // Step 1: setup off-screen binding 
  OSMesaContext ctx;
  ctx = OSMesaCreateContextExt(OSMESA_BGR, 32, 0, 0, NULL ); // strange hack not sure why it is not OSMESA_RGB
  unsigned char * pbuffer = new unsigned char [3 * m_width * m_height];
  // Bind the buffer to the context and make it current
  if (!OSMesaMakeCurrent(ctx, (void*)pbuffer, GL_UNSIGNED_BYTE, m_width, m_height)) {
    mexErrMsgTxt("OSMesaMakeCurrent failed!: ");
  }
  OSMesaPixelStore(OSMESA_Y_UP, 0);

  // Step 2: Setup basic OpenGL setting
  glEnable(GL_DEPTH_TEST);
  glDisable(GL_LIGHTING);
  glEnable(GL_CULL_FACE);
  glCullFace(GL_BACK);
  glPolygonMode(GL_FRONT, GL_FILL);
  glClearColor(1.0f, 1.0f, 1.0f, 1.0f); // white background
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glViewport(0, 0, m_width, m_height);

  // Step 3: Set projection matrices
  double scale = (0x0001) << m_level;
  double final_matrix[16];

  // new way: faster way by reuse computation and symbolic derive. See sym_derive.m to check the math.
  double inv_width_scale  = 1.0/(m_width*scale);
  double inv_height_scale = 1.0/(m_height*scale);
  double inv_width_scale_1 =inv_width_scale - 1.0;
  double inv_height_scale_1_s = -(inv_height_scale - 1.0);
  double inv_width_scale_2 = inv_width_scale*2.0;
  double inv_height_scale_2_s = -inv_height_scale*2.0;
  double m_far_a_m_near = m_far + m_near;
  double m_far_s_m_near = m_far - m_near;
  double m_far_d_m_near = m_far_a_m_near/m_far_s_m_near;
  final_matrix[ 0]= projection[2+0*3]*inv_width_scale_1 + projection[0+0*3]*inv_width_scale_2;
  final_matrix[ 1]= projection[2+0*3]*inv_height_scale_1_s + projection[1+0*3]*inv_height_scale_2_s;
  final_matrix[ 2]= projection[2+0*3]*m_far_d_m_near;
  final_matrix[ 3]= projection[2+0*3];
  final_matrix[ 4]= projection[2+1*3]*inv_width_scale_1 + projection[0+1*3]*inv_width_scale_2;
  final_matrix[ 5]= projection[2+1*3]*inv_height_scale_1_s + projection[1+1*3]*inv_height_scale_2_s; 
  final_matrix[ 6]= projection[2+1*3]*m_far_d_m_near;    
  final_matrix[ 7]= projection[2+1*3];
  final_matrix[ 8]= projection[2+2*3]*inv_width_scale_1 + projection[0+2*3]*inv_width_scale_2; 
  final_matrix[ 9]= projection[2+2*3]*inv_height_scale_1_s + projection[1+2*3]*inv_height_scale_2_s;
  final_matrix[10]= projection[2+2*3]*m_far_d_m_near;
  final_matrix[11]= projection[2+2*3];
  final_matrix[12]= projection[2+3*3]*inv_width_scale_1 + projection[0+3*3]*inv_width_scale_2;
  final_matrix[13]= projection[2+3*3]*inv_height_scale_1_s + projection[1+3*3]*inv_height_scale_2_s;  
  final_matrix[14]= projection[2+3*3]*m_far_d_m_near - (2*m_far*m_near)/m_far_s_m_near;
  final_matrix[15]= projection[2+3*3];
  
  // matrix is ready. use it
  glMatrixMode(GL_PROJECTION);
  glLoadMatrixd(final_matrix);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  // Step 3: render
  
  //render points
  glBegin(GL_POINTS);
  for (unsigned int p = 0; p < num_points ; ++p) {
      glColor3ubv(color);
      glVertex3dv(vertex);
      color += 3;
      vertex+= 3;
  }
  glEnd();
  
  //render lines
  glLineWidth(3);
  
  glBegin(GL_LINES);
  for (unsigned int p = 0; p < num_edges ; ++p) {
      glColor3ubv(colorEdge);
      glVertex3dv(vertexEdge);
      colorEdge += 3;
      vertexEdge+= 3;
  }
  glEnd();

  
  
  glFinish(); // done rendering
  
  
  // Step 5: convert the result from color to interger array
  plhs[0] = mxCreateNumericMatrix(m_width, m_height, mxUINT32_CLASS, mxREAL);
  unsigned int* result = (unsigned int*) mxGetData(plhs[0]);

  unsigned int* resultCur = result;
  unsigned int* resultEnd = result + m_width * m_height;
  unsigned char * pbufferCur = pbuffer;
  while(resultCur != resultEnd){
      *resultCur = uchar2uint(pbufferCur);
      
      //if (*resultCur!=0){
      //    mexPrintf("%d=[%d,%d,%d]\n",*resultCur,pbufferCur[0],pbufferCur[1],pbufferCur[2]);
      //}
      
      pbufferCur += 3;
      ++resultCur;
  }
  
    
  unsigned int* pDepthBuffer;
  GLint outWidth, outHeight, bitPerDepth;
  OSMesaGetDepthBuffer(ctx, &outWidth, &outHeight, &bitPerDepth, (void**)&pDepthBuffer);
  // mexPrintf("w = %d, h = %d, bitPerDepth = %d\n", outWidth, outHeight, bitPerDepth);
  plhs[1] = mxCreateNumericMatrix((int)outWidth, (int)outHeight, mxUINT32_CLASS, mxREAL);
  
  memcpy((unsigned int*) mxGetData(plhs[1]),pDepthBuffer,sizeof(unsigned int)*outWidth*outHeight);
  
  
  OSMesaDestroyContext(ctx);
  delete [] pbuffer;

} 