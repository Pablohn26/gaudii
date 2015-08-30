/********************************************
* Víctor José Martín Ramírez                *
* Carlos González Morcillo                  *
* Código bajo licencia GPL 3                *
* => http://www.gnu.org/licenses/gpl.html   *
********************************************/

#include <iostream>
#include <OpenCV/cv.h>
#include <OpenCV/highgui.h>
#include <math.h>
#include "cvBlob/cvblob.h"

int main( int argc, char** argv ) { 
	IplImage *img = cvLoadImage(argv[1]);
	IplImage *dst = cvCreateImage(cvGetSize(img), IPL_DEPTH_8U, 1);
	IplImage *chR = cvCreateImage(cvGetSize(img), IPL_DEPTH_8U, 1);
	IplImage *chG = cvCreateImage(cvGetSize(img), IPL_DEPTH_8U, 1);
	IplImage *chB = cvCreateImage(cvGetSize(img), IPL_DEPTH_8U, 1);
	int third_x1, third_x2, third_y1, third_y2; 
	int imageArea, auxArea, centerX, centerY;
	int found=0, closestDistance=1000000, chosenX=0, chosenY=0, chosenW=0, chosenH=0;
	
	third_x1 = (float)img->width * 0.334;
	third_x2 = (float)img->width * 0.667;
	third_y1 = (float)img->height * 0.334;
	third_y2 = (float)img->height * 0.667;
	imageArea = img->width * img->height;
	
	/*We split the channels of the image*/
	cvSplit(img, chR, chG, chB, NULL);
	cvThreshold(chR,dst,55,255,CV_THRESH_TOZERO_INV);
	
	/*Get the blobs*/
	IplImage *labelImg=cvCreateImage(cvGetSize(chR), IPL_DEPTH_LABEL, 1);
	CvBlobs blobs;
	unsigned int result=cvLabel(dst, labelImg, blobs);
	
	
	/*Iterating the blobs*/
	for (CvBlobs::const_iterator it=blobs.begin(); it!=blobs.end(); ++it){
		auxArea = (it->second->maxx - it->second->minx) * (it->second->maxy - it->second->miny);
		if(auxArea > imageArea*0.04 && auxArea < imageArea*0.25){
			found=0;
			centerX = it->second->maxx + (it->second->maxx - it->second->minx)/2;
			centerY = it->second->maxy + (it->second->maxy - it->second->miny)/2;
			
			if(sqrt((centerX-third_x1)*(centerX-third_x1)+(centerY-third_y1)*(centerY-third_y1)) < closestDistance){
				found=1;
				closestDistance = sqrt((centerX-third_x1)*(centerX-third_x1)+(centerY-third_y1)*(centerY-third_y1));
			}
			if(sqrt((centerX-third_x2)*(centerX-third_x2)+(centerY-third_y1)*(centerY-third_y1)) < closestDistance){
				found=1;
				closestDistance = sqrt((centerX-third_x2)*(centerX-third_x2)+(centerY-third_y1)*(centerY-third_y1));
			}
			if(sqrt((centerX-third_x1)*(centerX-third_x1)+(centerY-third_y2)*(centerY-third_y2)) < closestDistance){
				found=1;
				closestDistance = sqrt((centerX-third_x1)*(centerX-third_x1)+(centerY-third_y2)*(centerY-third_y2));
			}
			if(sqrt((centerX-third_x2)*(centerX-third_x2)+(centerY-third_y2)*(centerY-third_y2)) < closestDistance){
				found=1;
				closestDistance = sqrt((centerX-third_x2)*(centerX-third_x2)+(centerY-third_y2)*(centerY-third_y2));
			}
			
			if(found==1){
				chosenX=it->second->minx;
				chosenY=it->second->miny;
				chosenW=it->second->maxx - it->second->minx;
				chosenH=it->second->maxy - it->second->miny;
			}
			
		}
	}
	
	printf("%i %i %i %i", chosenX, chosenY, chosenW, chosenH);
	
	/*Uncomment these for watching the results in a window*/
	//Render the blobs
	//cvRenderBlobs(labelImg, blobs, img, img);
	
	
	//cvNamedWindow("Example",CV_WINDOW_AUTOSIZE); 
    //cvShowImage("Example", img ); 
    //cvWaitKey(0); 
    //cvReleaseImage( &img); 
    //cvDestroyWindow("Example"); 
    
    return 0;
}
