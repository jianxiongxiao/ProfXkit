// This is a program for packing texture for rectangles into a big image
// It is solving NP-hard 2D Bin Packing problem for rectangles using simple heuristic
// Algorithm explanation: http://www.blackpawn.com/texts/lightmaps/default.html
// Algorithm animation demo: http://incise.org/2d-bin-packing-with-javascript-and-canvas.html
// Jianxiong Xiao: http://mit.edu/jxiao/


#ifndef BinPacking2D_h
#define BinPacking2D_h

#include <cstddef>
#include <vector>
#include <cmath>
using namespace std;

template <class ValueType>
class Rectangle2D{
public:
	ValueType Left;
	ValueType Top;
	ValueType Width;
	ValueType Height;
	Rectangle2D(){};
	Rectangle2D(ValueType l, ValueType t, ValueType w, ValueType h)
	{
		Left = l;
		Top = t;
		Width = w;
		Height = h;
	}
};

template <class ValueType>
class BinPacking2DTreeNode
{
public:
	Rectangle2D<ValueType> * binRectangle;
	BinPacking2DTreeNode * leftChild;
	BinPacking2DTreeNode * rightChild;
	bool filled;

	BinPacking2DTreeNode(Rectangle2D<ValueType> * binRectangle)
	{
		this->binRectangle = binRectangle;
		leftChild = NULL;
		rightChild = NULL;
		filled = false;
	}

	Rectangle2D<ValueType> * insert(Rectangle2D<ValueType> * inputRectangle)
	{
		if(leftChild != NULL || rightChild != NULL){
			Rectangle2D<ValueType> * leftRectangle = leftChild->insert(inputRectangle);
			if(leftRectangle == NULL)
			{
				return rightChild->insert(inputRectangle);
			}
			return leftRectangle;
		}else{
			if(filled || inputRectangle->Width > binRectangle->Width || inputRectangle->Height > binRectangle->Height){
				return NULL;
			}
			if(inputRectangle->Width == binRectangle->Width && inputRectangle->Height == binRectangle->Height){
				filled = true;
				return binRectangle;
			}
			int widthDifference = binRectangle->Width - inputRectangle->Width;
			int heightDifference = binRectangle->Height - inputRectangle->Height;

			Rectangle2D<ValueType> * leftRectangle = new Rectangle2D<ValueType>(*binRectangle);
			Rectangle2D<ValueType> * rightRectangle = new Rectangle2D<ValueType>(*binRectangle);

			if(widthDifference > heightDifference){
				leftRectangle->Width = inputRectangle->Width;
				rightRectangle->Left += inputRectangle->Width;
				rightRectangle->Width -= inputRectangle->Width;
			}else{
				leftRectangle->Height = inputRectangle->Height;
				rightRectangle->Top += inputRectangle->Height;
				rightRectangle->Height -= inputRectangle->Height;
			}
			
			leftChild = new BinPacking2DTreeNode(leftRectangle);
			rightChild = new BinPacking2DTreeNode(rightRectangle);
			
			return leftChild->insert(inputRectangle);
		}
	}
	~BinPacking2DTreeNode()
	{
		if(leftChild != NULL)	delete leftChild;
		if(rightChild != NULL)	delete rightChild;
		delete binRectangle;
	}
};

/*
// usage example
#include "BinPacking2D.h"
#include <iostream>
#include <vector>
using namespace std; 
int main()
{
	Rectangle2D < unsigned int > * pRootRect = new Rectangle2D < unsigned int > (0,0,1024,1024);
	BinPacking2DTreeNode < unsigned int > * pRoot = new BinPacking2DTreeNode < unsigned int > (pRootRect);
	
	
	
	Rectangle2D < unsigned int > * pSomeRect = new Rectangle2D < unsigned int >(0,0,100,200);
	Rectangle2D < unsigned int > * pSomeRectLocation = pRoot->insert(pSomeRect);
	if (pSomeRectLocation!=NULL){
		cout << "["
		<< pSomeRectLocation->Left		<<"\t"
		<< pSomeRectLocation->Top		<<"\t"
		<< pSomeRectLocation->Width		<<"\t"
		<< pSomeRectLocation->Height	<<"]\n";
	}else {
		cout << "insert failed";
	}
	
	delete pSomeRect;
	delete pRoot;
	
	return 1;
}
*/


inline int pow2roundup (int x)
{
    if (x < 0)	return 0;
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x+1;
}

// automatic choose the size of the texture image by making it larger until it fits all rectangels
void pack2Dtexture(unsigned int& texWidth, unsigned int& texHeight, vector<Rectangle2D <unsigned int> >& rectangles){
	unsigned int sumArea = 0;
	for (unsigned int i=0; i<rectangles.size(); ++i) {
		sumArea += rectangles[i].Width * rectangles[i].Height;
	}
	int sqrtArea = ceil(sqrt(double(sumArea)));
	sqrtArea = pow2roundup(sqrtArea);
	unsigned int texSize[2] = {sqrtArea, sqrtArea};
	unsigned int incAspect = 0;
	if (sqrtArea*sqrtArea/2 > sumArea){
		texSize[1]=sqrtArea/2;
		incAspect = 1;
	}
	bool allPack = false;
	while (!allPack) {
		Rectangle2D < unsigned int > * pRootRect = new Rectangle2D < unsigned int > (0,0,texSize[0],texSize[1]);
		BinPacking2DTreeNode < unsigned int > * pRoot = new BinPacking2DTreeNode < unsigned int > (pRootRect);
		
		allPack = true;
		for (unsigned int i=0; i<rectangles.size(); ++i) {
			rectangles[i].Left = 0;
			rectangles[i].Top = 0;
			Rectangle2D < unsigned int > * pSomeRectLocation = pRoot->insert(&(rectangles[i]));
			if (pSomeRectLocation==NULL) {
				allPack = false;
				break;
			}else {
				rectangles[i].Left = pSomeRectLocation->Left;
				rectangles[i].Top  = pSomeRectLocation->Top ;
			}
		}
		delete pRoot;		
		if (!allPack){
			texSize[incAspect] *= 2;
			incAspect = 1-incAspect;
		}		
	}
	texWidth  = texSize[0];
	texHeight = texSize[1];
}

/*
// usage example
#include "BinPacking2D.h"
#include <iostream>
#include <vector>
using namespace std;

int main(){
	unsigned int texWidth;
	unsigned int texHeight;
	vector<Rectangle2D <unsigned int> > rectangles;
	
	rectangles.resize(3);
	rectangles[0].Width = 100;	rectangles[0].Height = 300;
	rectangles[1].Width = 250;	rectangles[1].Height = 100;
	rectangles[2].Width = 150;	rectangles[2].Height = 200;
	
	pack2Dtexture(texWidth, texHeight, rectangles);
	cout << texWidth << "x" << texHeight <<endl;
	for (unsigned int i=0; i<rectangles.size(); ++i) {
		cout << "["
		<< rectangles[i].Left	<<"\t"
		<< rectangles[i].Top	<<"\t"
		<< rectangles[i].Width	<<"\t"
		<< rectangles[i].Height	<<"]\n";
	}
	
	return 1;
}
*/

#endif