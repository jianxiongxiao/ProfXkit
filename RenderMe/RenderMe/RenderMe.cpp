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

#include "RenderMe.h"
#include <iostream>
#include <GL/osmesa.h>
#include <GL/glu.h>

void CRenderMe::uint2uchar(unsigned int in, unsigned char* out){
	out[0] = (in & 0x00ff0000) >> 16;
	out[1] = (in & 0x0000ff00) >> 8;
	out[2] =  in & 0x000000ff;
}

unsigned int CRenderMe::uchar2uint(unsigned char* in){
	unsigned int out = (((unsigned int)(in[0])) << 16) + (((unsigned int)(in[1])) << 8) + ((unsigned int)(in[2]));
	return out;
}

unsigned int* CRenderMe::render() {
	// Step 1: setup off-screen mesa's binding 
  OSMesaContext ctx;
  ctx = OSMesaCreateContextExt(OSMESA_RGB, 32, 0, 0, NULL );
	unsigned char * pbuffer = new unsigned char [3 * m_width * m_height];
  // Bind the buffer to the context and make it current
  if (!OSMesaMakeCurrent(ctx, (void*)pbuffer, GL_UNSIGNED_BYTE, m_width, m_height)) {
    cerr << "OSMesaMakeCurrent failed!: " << m_width << ' ' << m_height << endl;
    return NULL;
  }
  OSMesaPixelStore(OSMESA_Y_UP, 0);

	// Step 2: Setup basic OpenGL setting
  glEnable(GL_DEPTH_TEST);
  glDisable(GL_LIGHTING);
  glEnable(GL_CULL_FACE);
  glCullFace(GL_BACK);
  glPolygonMode(GL_FRONT, GL_FILL);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  //glClearColor(m_clearColor[0], m_clearColor[1], m_clearColor[2], 1.0f); // this line seems useless
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
	final_matrix[ 0]= projection[2][0]*inv_width_scale_1 + projection[0][0]*inv_width_scale_2;
	final_matrix[ 1]= projection[2][0]*inv_height_scale_1_s + projection[1][0]*inv_height_scale_2_s;
	final_matrix[ 2]= projection[2][0]*m_far_d_m_near;
	final_matrix[ 3]= projection[2][0];
	final_matrix[ 4]= projection[2][1]*inv_width_scale_1 + projection[0][1]*inv_width_scale_2;
	final_matrix[ 5]= projection[2][1]*inv_height_scale_1_s + projection[1][1]*inv_height_scale_2_s; 
	final_matrix[ 6]= projection[2][1]*m_far_d_m_near;    
	final_matrix[ 7]= projection[2][1];
	final_matrix[ 8]= projection[2][2]*inv_width_scale_1 + projection[0][2]*inv_width_scale_2; 
	final_matrix[ 9]= projection[2][2]*inv_height_scale_1_s + projection[1][2]*inv_height_scale_2_s;
	final_matrix[10]= projection[2][2]*m_far_d_m_near;
	final_matrix[11]= projection[2][2];
	final_matrix[12]= projection[2][3]*inv_width_scale_1 + projection[0][3]*inv_width_scale_2;
	final_matrix[13]= projection[2][3]*inv_height_scale_1_s + projection[1][3]*inv_height_scale_2_s;  
	final_matrix[14]= projection[2][3]*m_far_d_m_near - (2*m_far*m_near)/m_far_s_m_near;
	final_matrix[15]= projection[2][3];

	/*
	// the equivalent but slower way to compute things on the fly
  projection[3] = Vec4f(0, 0, 0, 1);

	// handle the near and far clip plane in OpenGL
  Mat4f protr;
  protr[0] = Vec4f(1.0f, 0.0f, 0.0f, 0.0f);
  protr[1] = Vec4f(0.0f, 1.0f, 0.0f, 0.0f);
  protr[2] = Vec4f(0.0f, 0.0f, m_far / (m_far - m_near), - m_near * m_far /(m_far - m_near));
  protr[3] = Vec4f(0.0f, 0.0f, 1.0f, 0.0f);

  // handle half pixel inconsistency
  Mat4f offset;
  offset[0] = Vec4f(1.0f, 0.0f, 0.5f, 0.0f);
  offset[1] = Vec4f(0.0f, 1.0f, 0.5f, 0.0f);
  offset[2] = Vec4f(0.0f, 0.0f, 1.0f, 0.0f);
  offset[3] = Vec4f(0.0f, 0.0f, 0.0f, 1.0f);
  
	// undo image aspect ratio and size
  Mat4f m0;
  m0[0] = Vec4f(m_width / 2, 0.0f,         0.0f, 0 + m_width / 2.0f);
  m0[1] = Vec4f(0.0f,        m_height / 2, 0.0f, 0 + m_height / 2.0f);
  m0[2] = Vec4f(0.0f,        0.0f,         0.5f, 0.5f);
  m0[3] = Vec4f(0.0f,        0.0f,         0.0f, 1.0f);
  Mat4f m0_inv;
  invert(m0_inv, m0);

	// handle scaling
  Mat4f m1;
  m1[0] = Vec4f(1 / scale,   0.0f,         0.0f,                0.0f);
  m1[1] = Vec4f(0.0f,        1 / scale,    0.0f,                0.0f);
  m1[2] = Vec4f(0.0f,        0.0f,         1.0f,                0.0f);
  m1[3] = Vec4f(0.0f,        0.0f,         0.0f,                1.0f);

	// handle upside down in vertical direction in image
  Mat4f m2;
  m2[0] = Vec4f(1,           0.0f,         0.0f,                0.0f);
  m2[1] = Vec4f(0.0f,        -1.0f,        m_height,            0.0f);
  m2[2] = Vec4f(0.0f,        0.0f,         1.0f,                0.0f);
  m2[3] = Vec4f(0.0f,        0.0f,         0.0f,                1.0f);

	// the final matrix
  projection = m0_inv * protr * m2 * m1 * offset * projection;

	// OpenGL way of storing the matrix
  for (int y = 0; y < 4; ++y){
    for (int x = 0; x < 4; ++x){
      final_matrix[4 * y + x] = projection[x][y];
    }
  }
	*/
	
	// matrix is ready. use it
  glMatrixMode(GL_PROJECTION);
  glLoadMatrixd(final_matrix);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

	// Step 3: render the mesh with encoded color from their ID
	unsigned char colorBytes[3];

	// render face
	for (unsigned int i = 0; i < m_pmesh->face.size(); ++i) {
		uint2uchar(1+i,colorBytes);
		glColor3ub(colorBytes[0],colorBytes[1],colorBytes[2]);
		glBegin(GL_POLYGON);
		for (unsigned int j = 0; j < m_pmesh->face[i].vertex_index.size(); ++j) {
			CVertex v = m_pmesh->vertex[m_pmesh->face[i].vertex_index[j]];
			glVertex3f(v.x, v.y, v.z);
		}
		glEnd();
	}

	// render edge
	glLineWidth(m_linewidth);
	glBegin(GL_LINES);
	for (unsigned int i = 0; i < m_pmesh->edge.size(); ++i) {
		uint2uchar(1+m_pmesh->face.size()+i,colorBytes);
		glColor3ub(colorBytes[0],colorBytes[1],colorBytes[2]);
		CVertex v;
		v = m_pmesh->vertex[m_pmesh->edge[i].vertex1];
		glVertex3f(v.x, v.y, v.z);
		v = m_pmesh->vertex[m_pmesh->edge[i].vertex2];
		glVertex3f(v.x, v.y, v.z);
	}
	glEnd();

	// render vertex
	glPointSize(m_pointsize);
	glBegin(GL_POINTS);
	for (unsigned int i = 0; i < m_pmesh->vertex.size(); ++i) {
		uint2uchar(1+m_pmesh->face.size()+m_pmesh->edge.size()+i,colorBytes);
		glColor3ub(colorBytes[0],colorBytes[1],colorBytes[2]);
		CVertex v = m_pmesh->vertex[i];
		glVertex3f(v.x, v.y, v.z);
	}
	glEnd();
	
	glFinish(); // done rendering

	// Step 5: convert the result from color to interger array
	unsigned int* result = new unsigned int [m_width * m_height];
	unsigned int* resultCur = result;
	unsigned int* resultEnd = result + m_width * m_height;
	unsigned char * pbufferCur = pbuffer;
	while(resultCur != resultEnd){
		*resultCur = uchar2uint(pbufferCur);
		pbufferCur += 3;
		++resultCur;
	}

  OSMesaDestroyContext(ctx);
	delete [] pbuffer;

	return result;
}

