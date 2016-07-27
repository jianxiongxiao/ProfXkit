#include "Mesh.h"
#include <fstream>
#include <iostream>
#include <string>

void CMesh::readPLY(const char* filename){
	//cout<<"Reading PLY file: "<<filename<<endl;
	ifstream fin(filename);
	int num_vertex, num_face, num_edge;
	int tmp;
	string str;
	getline(fin,str);
	getline(fin,str);
	getline(fin,str);
	fin>>str>>str>>num_vertex;  getline(fin,str);
  getline(fin,str);
  getline(fin,str);
  getline(fin,str);
	fin>>str>>str>>num_face;  getline(fin,str);
  getline(fin,str);
	fin>>str>>str>>num_edge;  getline(fin,str);
  getline(fin,str);
  getline(fin,str);
  getline(fin,str);
	//cout<<"num_vertex="<<num_vertex<<endl;
	//cout<<"num_face  ="<<num_face<<endl;
	//cout<<"num_edge  ="<<num_edge<<endl;
	for (int i=0;i<num_vertex;++i){
		CVertex v;
		fin>>v.x>>v.y>>v.z;
		vertex.push_back(v);
	}
	for (int i=0;i<num_face;++i){
		CFace f;
		int num_vertex_index;
		fin>>num_vertex_index;
		f.vertex_index.resize(num_vertex_index);
		for (int j=0;j<num_vertex_index; j++){
			fin>>f.vertex_index[j];
		}
		face.push_back(f);
	}
	for (int i=0;i<num_edge;++i){
		CEdge e;
		fin>>e.vertex1>>e.vertex2;
		edge.push_back(e);
	}
	fin.close();
}

void CMesh::writePLY(const char* filename){
	ofstream fout(filename);

	fout<<"ply"<<endl;
	fout<<"format ascii 1.0"<<endl;
	fout<<"comment format for RenderMe"<<endl;
	fout<<"element vertex "<<vertex.size()<<endl;
	fout<<"property float x"<<endl;
	fout<<"property float y"<<endl;
	fout<<"property float z"<<endl;
	fout<<"element face "<<face.size()<<endl;
	fout<<"property list uchar int vertex_index"<<endl;
	fout<<"element edge "<<edge.size()<<endl;
	fout<<"property int vertex1"<<endl;
	fout<<"property int vertex2"<<endl;
	fout<<"end_header"<<endl;

	for (int i=0;i<vertex.size();++i){
		fout<<vertex[i].x<<" "<<vertex[i].y<<" "<<vertex[i].z<<endl;
	}
	for (int i=0;i<face.size();++i){
		fout<<face[i].vertex_index.size();
		for (int j=0;j<face[i].vertex_index.size();++j){
			fout<<" "<<face[i].vertex_index[j];
		}
		fout<<endl;
	}
	for (int i=0;i<edge.size();++i){
		fout<<edge[i].vertex1<<" "<<edge[i].vertex2<<endl;
	}
	fout.close();
}

