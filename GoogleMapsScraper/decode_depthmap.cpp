#include "base64.h"
#include <zlib.h>
#include <fstream>
#include <stdio.h>
#include <string.h>
#include <vector>
#include <cmath>
#include <math.h>
#include <cassert>
#include <locale.h>
#include <stdlib.h>

using namespace std;

struct depthMapPlane {
    float x, y, z;
    float d;
};

struct xy {
    int x, y;
};


//Decode the depth map
//The depth map is encoded as a series of pixels in a 512x256 image. Each pixels refers
//to a depthMapPlane which are also encoded in the data. Each depthMapPlane has three elements:
//The x,y,z normals and the closest distance the plane has to the origin. This uniquely
//identifies the plane in 3d space.
void decodeDepth(char* xml_fname, char* out_fname)
{
    //Depth map information
    int mapWidth, mapHeight;
    vector<unsigned char> depthmapIndices;
    vector<struct depthMapPlane> depthmapPlanes;
    
    
    FILE * pFile;
    long lSize;
    char * buffer;
    size_t result;
    
    pFile = fopen (xml_fname , "rb" );
    if (pFile==NULL) {fputs ("File error",stderr); exit (1);}
    
    // obtain file size:
    fseek (pFile , 0 , SEEK_END);
    lSize = ftell (pFile);
    rewind (pFile);
    
    // allocate memory to contain the whole file:
    buffer = (char*) malloc (sizeof(char)*lSize);
    if (buffer == NULL) {fputs ("Memory error",stderr); exit (2);}
    
    // copy the file into the buffer:
    result = fread (buffer,1,lSize,pFile);
    if (result != lSize) {fputs ("Reading error",stderr); exit (3);}
    
    /* the whole file is now loaded in the memory buffer. */
    
    // terminate
    fclose (pFile);
    
    
    char* xml = buffer;
    
    //Get the base64 encoded data
    string depth_map_base64;
    {
        const char* begin = strstr(xml, "<depth_map>");
        const char* end = strstr(xml, "</depth_map>");
        if (begin == NULL || end == NULL)
            throw "No depth map information found in xml data";
        
        depth_map_base64 = std::string(begin + strlen("<depth_map>"), end);
    }
    
    //Decode base64
    vector<unsigned char> depth_map_compressed(depth_map_base64.length());
    int compressed_length = decode_base64(&depth_map_compressed[0], &depth_map_base64[0]);
    
    //Uncompress data with zlib
    //TODO: decompress in a loop so we can accept any size
    unsigned long length = 512 * 256 + 5000;
    vector<unsigned char> depth_map(length);
    int zlib_return = uncompress(&depth_map[0], &length, &depth_map_compressed[0], compressed_length);
    if (zlib_return != Z_OK)
        throw "zlib decompression of the depth map failed";
    
    //Load standard data
    const int headersize = depth_map[0];
    const int numPanos = depth_map[1] | (depth_map[2] << 8);
    mapWidth = depth_map[3] | (depth_map[4] << 8);
    mapHeight = depth_map[5] | (depth_map[6] << 8);
    const int panoIndicesOffset = depth_map[7];
    
    if (headersize != 8 || panoIndicesOffset != 8)
        throw "Unexpected depth map header";
    
    //Load depthMapIndices
    depthmapIndices = vector<unsigned char>(mapHeight * mapWidth);
    memcpy(&depthmapIndices[0], &depth_map[panoIndicesOffset], mapHeight * mapWidth);
    
    //Load depthMapPlanes
    depthmapPlanes = vector<struct depthMapPlane > (numPanos);
    memcpy(&depthmapPlanes[0], &depth_map[panoIndicesOffset + mapHeight * mapWidth], numPanos * sizeof (struct depthMapPlane));
    
    free (buffer);
    
    ofstream fout(out_fname);
    
    for (unsigned int y = 0; y < mapHeight; ++y) {
        for (unsigned int x = 0; x < mapWidth ; ++x){
            
            double rad_azimuth = x / (float) (mapWidth - 1.0f) * 2 * M_PI;
            double rad_elevation = y / (float) (mapHeight - 1.0f) * M_PI;
            
            //Calculate the cartesian position of this vertex (if it was at unit distance)
            double dx = sin(rad_elevation) * sin(rad_azimuth);
            double dy = sin(rad_elevation) * cos(rad_azimuth);
            double dz = cos(rad_elevation);
            float distance = 1;
            
            //Value that is safe to use to retrieve stuff from the index arrays
            
            
            //Calculate distance of point according to the depth map data.
            int depthMapIndex = depthmapIndices[y * mapWidth + x];
            if (depthMapIndex == 0) {
                //Distance of sky
                fout<< "NaN" <<"\t"<< "NaN" <<"\t"<< "NaN" <<"\t";
                
            } else {
                struct depthMapPlane plane = depthmapPlanes[depthMapIndex];
                distance = -plane.d / (plane.x * dx + plane.y * dy + -plane.z * dz);
                fout<< dx * distance<<"\t"<< dy*distance<<"\t"<< dz * distance<<"\t";
            }
            
        }
        fout<<endl;
    }
    fout.close();
}

int main(int argc, char** argv){
    decodeDepth(argv[1],argv[2]);
    return 0;
}

