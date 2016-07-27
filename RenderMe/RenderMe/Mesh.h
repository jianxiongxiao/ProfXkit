#ifndef MESH_H
#define MESH_H

// This is an over-simplified ply file reader that only works for the format in my example. --jianxiong

#include <vector>

using namespace std;

class CVertex{
public:
	float x,y,z;
};

class CEdge{
public:
	int vertex1;
	int vertex2;
};

class CFace{
public:
	vector< unsigned int > vertex_index;
};

class CMesh{
public:
	vector< CVertex > vertex;
	vector< CEdge >	edge;
	vector< CFace >	face;
	void readPLY(const char* filename); // a super simple ply file reader. it only works with my example format.
	void writePLY(const char* filename);
};

#endif // MESH_H

