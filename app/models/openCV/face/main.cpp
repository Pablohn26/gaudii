/********************************************
* Víctor José Martín Ramírez                *
* Carlos González Morcillo                  *
* Código bajo licencia GPL 3                *
* => http://www.gnu.org/licenses/gpl.html   *
********************************************/

#include <iostream>
#include <cassert>
#include <OpenCV/cv.h>
#include <OpenCV/highgui.h>
#include <math.h>


int main( int argc, char** argv ) { 
    //declarations
	CvHaarClassifierCascade * pCascade = 0; //face detector
	CvMemStorage * pStorage = 0; //expandable memory buffer
	CvSeq * pFaceRectSeq;
	int i, biggestFace=0;
	int chosenX=0, chosenY=0, chosenH=0, chosenW=0;
	
	/*Initializations*/
	IplImage * pInpImg = (argc > 1) ? 
	cvLoadImage(argv[1], CV_LOAD_IMAGE_COLOR) : 0;
	pStorage = cvCreateMemStorage(0);
	pCascade = (CvHaarClassifierCascade *)cvLoad("public/xml/haarcascades/haarcascade_frontalface_alt2.xml", 0, 0, 0);
	
	/*we check everything is fine*/
	if( !pInpImg || !pStorage || !pCascade){
		printf("Initialization failed: %s \n",
			(!pInpImg)? "didn't load the image file" :
			(!pCascade)? "didn't load the Haar cascade" :	
			"Failed to allocate memory for data storage");
		exit(-1);
	}
	
	/*detecting the faces in the image*/
	pFaceRectSeq = cvHaarDetectObjects(pInpImg, pCascade, pStorage,
		1.1,						//increase search scale every step
		40,							//reject groups of less than 3 detections
		CV_HAAR_DO_CANNY_PRUNING,	//skip zones that do not contain a face
		cvSize(0, 0));				//use XML default for smallest search scale
	
	
	/*create a window for displaying the faces*/
	//cvNamedWindow("Haar window", CV_WINDOW_AUTOSIZE);
	
	/*Draw a rectangle around each detection*/
	for(i=0; i< (pFaceRectSeq? pFaceRectSeq->total:0);i++){
		CvRect * r = (CvRect*)cvGetSeqElem(pFaceRectSeq, i);
		if(r->width * r->height > biggestFace){
			biggestFace = r->width * r->height;
			chosenX = r->x;
			chosenY = r->y;
			chosenW = r->width;
			chosenH = r->height;
		}
		
		CvPoint pt1 = { r->x, r->y};
		CvPoint pt2 = { r->x + r->width, r->y + r->height};
		cvRectangle(pInpImg, pt1, pt2, CV_RGB(0,255,0), 3, 4, 0);
	}
	
	printf("%i %i %i %i", chosenX, chosenY, chosenW, chosenH);
	
	/*Uncomment these for watching the results in a window*/
//	cvShowImage("Haar window", pInpImg);
//	cvWaitKey(0);
//	cvDestroyWindow("Haar window");
	
	//cleanning the mess
//	cvReleaseImage(&pInpImg);
//	if(pCascade) cvReleaseHaarClassifierCascade(&pCascade);
//	if(pStorage) cvReleaseMemStorage(&pStorage);
    
    //return 0;
}
