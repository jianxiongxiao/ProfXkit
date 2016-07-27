#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cstdlib>

using namespace std;

struct Point3D{
	float x;
	float y;
	float z;
};

class Mesh3D{
public:
	vector < Point3D > vertex;
	vector < vector< int > > face;
	Mesh3D(){};
	Mesh3D(string filename){ readOFF(filename); };

	Point3D getCenter(){
		Point3D center;
		center.x = 0;
		center.y = 0;
		center.z = 0;
		for (int i=0;i<vertex.size();++i){
			center.x += vertex[i].x;
			center.y += vertex[i].y;
			center.z += vertex[i].z;
		}
		if (vertex.size()>0){		
			center.x /= float(vertex.size());
			center.y /= float(vertex.size());
			center.z /= float(vertex.size());
		}
		return center;
	};
	void translate(Point3D T){
		for (int i=0;i<vertex.size();++i){
			vertex[i].x += T.x;
			vertex[i].y += T.y;
			vertex[i].z += T.z;
		}
	};
	void zeroCenter(){
		Point3D center = getCenter();
		center.x = - center.x;
		center.y = - center.y;
		center.z = - center.z;
		translate(center);
	};
	void readOFF(const string filename){
		string readLine;
		ifstream fin(filename.c_str());
		getline(fin,readLine);
		if (readLine != "OFF") cerr << "The file to read should be OFF." << endl;
		int delimiterPos_1, delimiterPos_2, delimiterPos_3;

		//getline(fin,readLine);
		//cout<<"readLine[0]="<<readLine[0]<<endl;
		//cout<<"readLine[0]="<<(!(readLine[0]=='#' || readLine[0]==' ' || readLine[0]=='\n' || readLine[0]=='\r'))<<endl;

		do { getline(fin,readLine); } while((readLine[0]=='#' || readLine[0]==' ' || readLine[0]=='\n' || readLine[0]=='\r'));
		
		//cout<<"endl"<<endl;

		delimiterPos_1 = readLine.find(" ", 0);
		int nv = atoi(readLine.substr(0,delimiterPos_1+1).c_str());
		delimiterPos_2 = readLine.find(" ", delimiterPos_1+1);
		int nf = atoi(readLine.substr(delimiterPos_1+1,delimiterPos_2-delimiterPos_1-1).c_str());

		//cout<<"nv="<<nv<<endl;
		//cout<<"nf="<<nf<<endl;

		vertex.resize(nv);
		face.resize(nf);
		for (int n=0; n<nv; n++){
			do { getline(fin,readLine); } while((readLine[0]=='#' || readLine[0]==' ' || readLine[0]=='\n' || readLine[0]=='\r'));
			delimiterPos_1 = readLine.find(" ", 0);
			vertex[n].x = atof(readLine.substr(0,delimiterPos_1).c_str());
			delimiterPos_2 = readLine.find(" ", delimiterPos_1+1);
			vertex[n].y = atof(readLine.substr(delimiterPos_1,delimiterPos_2 ).c_str());
			delimiterPos_3 = readLine.find(" ", delimiterPos_2+1);
			vertex[n].z = atof(readLine.substr(delimiterPos_2,delimiterPos_3 ).c_str());
		}
		for (int n=0; n<nf; n++){
			do { getline(fin,readLine); } while((readLine[0]=='#' || readLine[0]==' ' || readLine[0]=='\n' || readLine[0]=='\r'));
			delimiterPos_1 = readLine.find(" ", 0);
			face[n].resize(atoi(readLine.substr(0,delimiterPos_1).c_str()));
			for (int i=0;i<face[n].size();++i){
				delimiterPos_2 = readLine.find(" ", delimiterPos_1+1);
				face[n][i] = atoi(readLine.substr(delimiterPos_1,delimiterPos_2).c_str());
				delimiterPos_1 = delimiterPos_2;
			}
		}
		fin.close();
	};
	void writeOFF(const string filename){
		ofstream fout(filename.c_str());
		fout<<"OFF"<<endl;
		fout<<vertex.size()<<" "<<face.size()<<" 0"<<endl;
		for(int n=0;n<vertex.size();++n)
			fout<<vertex[n].x<<" "<<vertex[n].y<<" "<<vertex[n].z<<endl;
		for(int n=0;n<face.size();++n){
			fout<<face[n].size();
			for (int i=0;i<face[n].size();++i) fout<<" "<<face[n][i];
			fout<<endl;
		}
		fout.close();
	};

	void readPLY(const string filename){
		ifstream fin(filename.c_str());
		int num_vertex, num_face, num_edge;
		string str;
		getline(fin,str); getline(fin,str); getline(fin,str);
		fin>>str>>str>>num_vertex;  getline(fin,str);
		getline(fin,str); getline(fin,str); getline(fin,str);
		fin>>str>>str>>num_face;  getline(fin,str);
		getline(fin,str);
		//fin>>str>>str>>num_edge;  getline(fin,str);
		//getline(fin,str); 
		//getline(fin,str); 
		getline(fin,str);
		//cout<<"num_vertex="<<num_vertex<<endl;
		//cout<<"num_face  ="<<num_face<<endl;
		//cout<<"num_edge  ="<<num_edge<<endl;
		vertex.resize(num_vertex);
		for (int i=0;i<num_vertex;++i){
			fin>>vertex[i].x>>vertex[i].y>>vertex[i].z;
		}
		face.resize(num_face);
		for (int i=0;i<num_face;++i){
			int num_vertex_index;
			fin>>num_vertex_index;
			face[i].resize(num_vertex_index);
			for (int j=0;j<num_vertex_index; j++)
				fin>>face[i][j];
		}
		fin.close();
	};

	void readPLYbin(const string filename){
		ifstream fin(filename.c_str());
		int num_vertex, num_face, num_edge;
		string str;
		getline(fin,str); getline(fin,str); //getline(fin,str);
		fin>>str>>str>>num_vertex;  getline(fin,str);
		getline(fin,str); getline(fin,str); getline(fin,str);
		fin>>str>>str>>num_face;  getline(fin,str);
		getline(fin,str);
		//fin>>str>>str>>num_edge;  getline(fin,str);
		//getline(fin,str); 
		//getline(fin,str); 
		getline(fin,str);
		//cout<<"num_vertex="<<num_vertex<<endl;
		//cout<<"num_face  ="<<num_face<<endl;
		//cout<<"num_edge  ="<<num_edge<<endl;
		vertex.resize(num_vertex);

		fin.read((char*)(&(vertex[0].x)), num_vertex*3*sizeof(float));

		face.resize(num_face);
		for (int i=0;i<num_face;++i){
			uint8_t num_vertex_index;
			fin.read((char*)(&num_vertex_index),sizeof(uint8_t));
			face[i].resize(num_vertex_index);
			fin.read((char*)(&(face[i][0])),num_vertex_index*sizeof(int));
		}
		fin.close();
	};

	void writePLY(const string filename){
		ofstream fout(filename.c_str());
		fout<<"ply"<<endl;
		fout<<"format ascii 1.0"<<endl;
		//fout<<"comment format for RenderMe"<<endl;
		fout<<"element vertex "<<vertex.size()<<endl;
		fout<<"property float x"<<endl;
		fout<<"property float y"<<endl;
		fout<<"property float z"<<endl;
		fout<<"element face "<<face.size()<<endl;
		fout<<"property list uchar int vertex_index"<<endl;
		//fout<<"element edge "<<0<<endl;
		//fout<<"property int vertex1"<<endl;
		//fout<<"property int vertex2"<<endl;
		fout<<"end_header"<<endl;
		for (int i=0;i<vertex.size();++i){
			fout<<vertex[i].x<<" "<<vertex[i].y<<" "<<vertex[i].z<<endl;
		}
		for (int i=0;i<face.size();++i){
			fout<<face[i].size();
			for (int j=0;j<face[i].size();++j){
				fout<<" "<<face[i][j];
			}
			fout<<endl;
		}
		fout.close();
	};
};



