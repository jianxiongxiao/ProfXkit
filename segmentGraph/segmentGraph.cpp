// compile: mex segmentGraph.cpp
// this is a Matlab mex version of Pedro F. Felzenszwalb's "Efficient Graph-Based Image Segmentation" algorithm
// it supports general graph structure
// Usage: SegmentID = segmentGraphMex_edge(num_vertices, num_edges, double(edges, c, minSize);
// edges is a 3 x num_edges double array, sorted in non-decreasing weight order.
// first row and second row are the indices of the edges, starting from 0
// third row contains the weights for the edges
// originally written by Pedro F. Felzenszwalb
// mexified by Princeton Vision Group


#include <cstdio>
#include <cstdlib>
#include <algorithm>
#include <cmath>
#include "mex.h"


///////////////////////////////////////////////////////////////////////////////////////
// disjoint-set.h
///////////////////////////////////////////////////////////////////////////////////////

// disjoint-set forests using union-by-rank and path compression (sort of).

typedef struct {
  int rank;
  int p;
  int size;
} uni_elt;

class universe {
public:
  universe(int elements);
  ~universe();
  int find(int x);  
  void join(int x, int y);
  int size(int x) const { return elts[x].size; }
  int num_sets() const { return num; }

private:
  uni_elt *elts;
  int num;
};

universe::universe(int elements) {
  elts = new uni_elt[elements];
  num = elements;
  for (int i = 0; i < elements; i++) {
    elts[i].rank = 0;
    elts[i].size = 1;
    elts[i].p = i;
  }
}
  
universe::~universe() {
  printf("release universe: %d\n", num);
  printf("elts: %d\n", elts);
  delete [] elts;
  printf("universe released\n");
}

int universe::find(int x) {
  int y = x;
  while (y != elts[y].p)
    y = elts[y].p;
  elts[x].p = y;
  return y;
}

void universe::join(int x, int y) {
  if (elts[x].rank > elts[y].rank) {
    elts[y].p = x;
    elts[x].size += elts[y].size;
  } else {
    elts[x].p = y;
    elts[y].size += elts[x].size;
    if (elts[x].rank == elts[y].rank)
      elts[y].rank++;
  }
  num--;
}


///////////////////////////////////////////////////////////////////////////////////////
// segment-graph.h
///////////////////////////////////////////////////////////////////////////////////////


// threshold function
#define THRESHOLD(size, c) (c/size)

typedef struct {
  float w;
  int a, b;
} edge;

bool operator<(const edge &a, const edge &b) {
  return a.w < b.w;
}

/*
 * Segment a graph
 *
 * Returns a disjoint-set forest representing the segmentation.
 *
 * num_vertices: number of vertices in graph.
 * num_edges: number of edges in graph
 * edges: array of edges.
 * c: constant for treshold function.
 */
universe *segment_graph(int num_vertices, int num_edges, edge *edges, float c) { 
  // sort edges by weight
  std::sort(edges, edges + num_edges);

  // make a disjoint-set forest
  universe *u = new universe(num_vertices);

  // init thresholds
  float *threshold = new float[num_vertices];
  for (int i = 0; i < num_vertices; i++)
    threshold[i] = THRESHOLD(1,c);

  printf("initialization finished\n");
  // for each edge, in non-decreasing weight order...
  for (int i = 0; i < num_edges; i++) {
    edge *pedge = &edges[i];
    
    // components conected by this edge
    int a = u->find(pedge->a);
    int b = u->find(pedge->b);
    if (a != b) {
      if ((pedge->w <= threshold[a]) && (pedge->w <= threshold[b])) {
      	u->join(a, b);
	      a = u->find(a);
	      threshold[a] = pedge->w + THRESHOLD(u->size(a), c);
      }
    }
  }
  printf("finish\n");
  // free up
  delete threshold;
  return u;
}


///////////////////////////////////////////////////////////////////////////////////////
// segment-graph.h
///////////////////////////////////////////////////////////////////////////////////////

void mexFunction(int nlhs,mxArray* plhs[],int nrhs,const mxArray* prhs[])
{
	// check arguments
	if (nrhs != 5) 
	{
		mexPrintf("Usage: SegmentID = segmentGraphMex_edge(num_vertices, num_edges, double(edges, c, minSize);\n");
		mexPrintf("edges is a 3 x num_edges double array, sorted in non-decreasing weight order.\n");
		return;
	}
	// convert edges memory from matlab to c++
  int num_vertices = (int)mxGetScalar(prhs[0]);
  int num_edges = (int)mxGetScalar(prhs[1]);
	double* edgeMat = (double*)mxGetData(prhs[2]);
	double c = mxGetScalar(prhs[3]);
	int min_size = (int)mxGetScalar(prhs[4]);
  printf("num_vertices: %d, num_edges: %d, c: %f, min_size: %d\n", num_vertices, num_edges, c, min_size);
    
	edge *edges = new edge[num_edges];
	for( int i = 0; i<num_edges; i++)
	{
		edges[i].a = edgeMat[i*3+0];
		edges[i].b = edgeMat[i*3+1];
		edges[i].w = edgeMat[i*3+2];
	}
  printf("a: %d, b: %d, w: %f\n", edges[0].a, edges[0].b, edges[0].w);
  printf("Loading finished!\n");
	universe *u = segment_graph( num_vertices, num_edges, edges, c);

  printf("get out of segment_graph\n");
	// post process
	for (int i = 0; i < num_edges; i++) 
	{
		int a = u->find(edges[i].a);
		int b = u->find(edges[i].b);
		if ((a != b) && ((u->size(a) < min_size) || (u->size(b) < min_size)))
			u->join(a, b);
	}

  printf("finish post process\n");
	// pass result to matlab
	plhs[0] = mxCreateNumericMatrix((mwSize)num_vertices, 1, mxDOUBLE_CLASS, mxREAL);
	double* output = (double *)mxGetData(plhs[0]);
	for (int i = 0; i<num_vertices; i++)
  {
    output[i] = (double)(u->find(i));
  }
    
  printf("packed up output\n");
	delete[] edges;
  printf("delete edges\n");
	delete u;
  printf("memory released\n");
}
