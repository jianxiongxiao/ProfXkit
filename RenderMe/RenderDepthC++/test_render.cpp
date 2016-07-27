#include "render.hpp"

int main(){
	Mesh3D model;
	model.readOFF("chair.off");
	//model.writeOFF("chair_out.off");
	//model.writePLY("chair_out.ply");

	float projection[12] = {518.8579,0,0,-9.9753,511.4517,-0.0306,325.4296,269.5328,0.9995,16.9581,-869.4678,0.0521};

	float* depth =  renderDepth(&model, projection, 640, 480);

	float minD = depth[0];
	float maxD = depth[0];
	for (int i=1;i<480*640;++i){
		if (minD>depth[i]) minD=depth[i];
		if (maxD<depth[i]) maxD=depth[i];
	}
	cout<<"minD="<<minD<<endl;
	cout<<"maxD="<<maxD<<endl;

	for (int h=0; h<480; ++h){
		for (int w=0; w<640; ++w) if (depth[h*640+w]<4) cout<<".";  else cout<<" ";
		cout<<endl;
	}
	
	return 0;
}