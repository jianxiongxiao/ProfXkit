#include "3d.hpp"

int main(){
	Mesh3D obj;
	obj.readPLYbin("/Volumes/vision/www/pvt/obj2off/example/model.ply");
	obj.writeOFF("/Users/xj/Downloads/model.off");
	//obj.readPLY("/Users/xj/Downloads/toilet_0343_out.ply");
	//obj.writeOFF("/Users/xj/Downloads/toilet_0343_out2.off");
	return 0;
}