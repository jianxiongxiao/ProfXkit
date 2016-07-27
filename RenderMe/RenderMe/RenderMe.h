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


#ifndef RENDERME_H
#define RENDERME_H

#include <vector>
#include "Mesh.h"

class CRenderMe{
public:
	int m_width;
	int m_height;
	float m_near;
	float m_far;
	//float m_clearColor[3]; // this line seems useless
	int m_level; // level in which an image is rendered. influence scaling parameter
	const CMesh* m_pmesh;
	double projection[3][4];
	int m_linewidth;
	int m_pointsize;

	void uint2uchar(unsigned int in, unsigned char* out);
	unsigned int uchar2uint(unsigned char* in);

	unsigned int* render();
};

#endif // RENDERME_H
