#include "3d.hpp"

#include <GL/osmesa.h>
#include <GL/glu.h>

float* renderDepth(Mesh3D* model, float* projection, int render_width, int render_height){

	unsigned char * pbufferRGB = new unsigned char [3 * render_width * render_height];


	float m_near = 0.3;
	float m_far = 1e8;
	int m_level = 0;

	// Step 1: setup off-screen mesa's binding 
	OSMesaContext ctx = OSMesaCreateContextExt(OSMESA_RGB, 32, 0, 0, NULL );
	// Bind the buffer to the context and make it current
	if (!OSMesaMakeCurrent(ctx, (void*)pbufferRGB, GL_UNSIGNED_BYTE, render_width, render_height)) {
		cerr << "OSMesaMakeCurrent failed!: " << render_width << ' ' << render_height << endl;
		return NULL;
	}
	OSMesaPixelStore(OSMESA_Y_UP, 0);

	// Step 2: Setup basic OpenGL setting
	glEnable(GL_DEPTH_TEST);
	glDisable(GL_LIGHTING);
	glDisable(GL_CULL_FACE);
	//glEnable(GL_CULL_FACE);
	//glCullFace(GL_BACK);
	glPolygonMode(GL_FRONT, GL_FILL);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	//glClearColor(m_clearColor[0], m_clearColor[1], m_clearColor[2], 1.0f); // this line seems useless
	glViewport(0, 0, render_width, render_height);

	// Step 3: Set projection matrices
	double scale = (0x0001) << m_level;
	double final_matrix[16];

	// new way: faster way by reuse computation and symbolic derive. See sym_derive.m to check the math.
	double inv_width_scale  = 1.0/(render_width*scale);
	double inv_height_scale = 1.0/(render_height*scale);
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

	// Step 3: render the mesh 

	for (unsigned int i = 0; i < model->face.size() ; ++i) {
		glBegin(GL_POLYGON);
		for (unsigned int j=0; j < model->face[i].size(); ++j){
			int vi = model->face[i][j];
			glVertex3f(model->vertex[vi].x, model->vertex[vi].y, model->vertex[vi].z);
		}
		glEnd();
	}

	glFinish(); // done rendering

	////////////////////////////////////////////////////////////////////////////////
	unsigned int* pDepthBuffer;
	GLint outWidth, outHeight, bitPerDepth;
	OSMesaGetDepthBuffer(ctx, &outWidth, &outHeight, &bitPerDepth, (void**)&pDepthBuffer);

	float* pbufferD = new float[outWidth*outHeight];
	for(int i=0; i<outWidth*outHeight; i++){
		pbufferD[i] = float( m_near / (1.0 - double(pDepthBuffer[i])/double(4294967296)) );
	}
	OSMesaDestroyContext(ctx);

	delete [] pbufferRGB;
	return pbufferD;
}
