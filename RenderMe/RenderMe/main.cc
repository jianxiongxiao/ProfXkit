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

#include <iostream>
#include <fstream>
#include <GL/osmesa.h>
#include <GL/glu.h>
#include "Mesh.h"
#include "RenderMe.h"
// need to install libosmesa6-dev or newer version of osmesa


using namespace std;

int main(int argc, char** argv){
	cout<<"%% RenderMe: Give a mesh + a camera + a resolution, output a rendering of face ID map."<<endl;
	cout<<"%% input: plyFileName camFileName"<<endl;
	CMesh mesh;
	mesh.readPLY(argv[1]);
	CRenderMe render;
	render.m_pmesh = &mesh;


	render.m_near = 1;
	render.m_far = 100;
	//render.m_clearColor[0] = 0.0f;
	//render.m_clearColor[1] = 0.0f;
	//render.m_clearColor[2] = 0.0f;
	render.m_level = 0;
	render.m_linewidth = 1;
	render.m_pointsize = 1;


	ifstream fin(argv[2]);
	fin>>render.m_width;
	fin>>render.m_height;
	for(int i=0;i<3;++i){
		for(int j=0;j<4;++j){
			fin>>render.projection[i][j];
		}
	}
	fin.close();

	unsigned int* result = render.render();
	
	cout<<"result = ["<<endl;
	for(int i=0;i<render.m_height; ++i){
		for(int j=0;j<render.m_width; ++j){
			cout<<result[i*render.m_width+j]<<" ";
		}
		cout<<endl;
	}
	cout<<"];"<<endl;
	cout<<"close all"<<endl;
	cout<<"imagesc(result)"<<endl;
	cout<<"axis equal"<<endl;
	cout<<"axis tight"<<endl;
	cout<<"max(max(result))"<<endl;
	delete [] result;

	return 0;
}
