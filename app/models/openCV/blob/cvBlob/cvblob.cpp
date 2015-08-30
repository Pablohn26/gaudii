// Copyright (C) 2007 by Cristóbal Carnero Liñán
// grendel.ccl@gmail.com
//
// This file is part of cvBlob.
//
// cvBlob is free software: you can redistribute it and/or modify
// it under the terms of the Lesser GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// cvBlob is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// Lesser GNU General Public License for more details.
//
// You should have received a copy of the Lesser GNU General Public License
// along with cvBlob.  If not, see <http://www.gnu.org/licenses/>.
//

#include <cmath>
#include <iostream>
using namespace std;

#ifdef WIN32
#include <cv.h>
#else
#include <opencv/cv.h>
#endif

#include "cvblob.h"

CvLabel cvGreaterBlob(const CvBlobs &blobs)
{
  CvLabel label=0;
  unsigned int maxArea=0;
  
  for (CvBlobs::const_iterator it=blobs.begin();it!=blobs.end();++it)
  {
    CvBlob *blob=(*it).second;
    //if ((!blob->_parent)&&(blob->area>maxArea))
    if (blob->area>maxArea)
    {
      label=blob->label;
      maxArea=blob->area;
    }
  }
  
  return label;
}

void cvFilterByArea(CvBlobs &blobs, unsigned int minArea, unsigned int maxArea)
{
  CvBlobs::iterator it=blobs.begin();
  while(it!=blobs.end())
  {
    CvBlob *blob=(*it).second;
    if ((blob->area<minArea)||(blob->area>maxArea))
    {
      delete blob;
      CvBlobs::iterator tmp=it;
      ++it;
      blobs.erase(tmp);
    }
    else
      ++it;
  }
}

void cvCentralMoments(CvBlob *blob, const IplImage *img)
{
  CV_FUNCNAME("cvCentralMoments");
  __BEGIN__;
  if (!blob->centralMoments)
  {
    CV_ASSERT(img&&(img->depth==IPL_DEPTH_LABEL)&&(img->nChannels==1));

    //cvCentroid(blob); // Here?

    blob->u11=blob->u20=blob->u02=0.;

    // Only in the bounding box
    int stepIn = img->widthStep / (img->depth / 8);
    int img_width = img->width;
    int img_height = img->height;
    int img_offset = 0;
    if(0 != img->roi)
    {
      img_width = img->roi->width;
      img_height = img->roi->height;
      img_offset = img->roi->xOffset + (img->roi->yOffset * stepIn);
    }

    CvLabel *imgData=(CvLabel *)img->imageData + (blob->miny * stepIn) + img_offset;
    for (unsigned int r=blob->miny;
	r<blob->maxy;
	r++,imgData+=stepIn)
      for (unsigned int c=blob->minx;c<blob->maxx;c++)
	if (imgData[c]==blob->label)
	{
	  double tx=(c-blob->centroid.x);
	  double ty=(r-blob->centroid.y);
	  blob->u11+=tx*ty;
	  blob->u20+=tx*tx;
	  blob->u02+=ty*ty;
	}

    blob->centralMoments = true;
  }
  __END__;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Based on http://en.wikipedia.org/wiki/HSL_and_HSV

/// \def _HSV2RGB_(H, S, V, R, G, B)
/// \brief Color translation between HSV and RGB.
#define _HSV2RGB_(H, S, V, R, G, B) \
{ \
  double _h = H/60.; \
  int _hf = floor(_h); \
  int _hi = ((int)_h)%6; \
  double _f = _h - _hf; \
  \
  double _p = V * (1. - S); \
  double _q = V * (1. - _f * S); \
  double _t = V * (1. - (1. - _f) * S); \
 \
  switch (_hi) \
  { \
    case 0: \
      R = 255.*V; G = 255.*_t; B = 255.*_p; \
      break; \
    case 1: \
      R = 255.*_q; G = 255.*V; B = 255.*_p; \
      break; \
    case 2: \
      R = 255.*_p; G = 255.*V; B = 255.*_t; \
      break; \
    case 3: \
      R = 255.*_p; G = 255.*_q; B = 255.*V; \
      break; \
    case 4: \
      R = 255.*_t; G = 255.*_p; B = 255.*V; \
      break; \
    case 5: \
      R = 255.*V; G = 255.*_p; B = 255.*_q; \
      break; \
  } \
}
///////////////////////////////////////////////////////////////////////////////////////////////////

struct Color { unsigned char r,g, b; };
typedef std::map<CvLabel, Color> Palete;

void cvRenderBlobs(const IplImage *imgLabel, const CvBlobs &blobs, IplImage *imgSource, IplImage *imgDest, unsigned short mode, double alpha)
{
  CV_FUNCNAME("cvRenderBlobs");
  __BEGIN__;

  CV_ASSERT(imgLabel&&(imgLabel->depth==IPL_DEPTH_LABEL)&&(imgLabel->nChannels==1));
  CV_ASSERT(imgDest&&(imgDest->depth==IPL_DEPTH_8U)&&(imgDest->nChannels==3));

  if (mode&CV_BLOB_RENDER_COLOR)
  {
    Palete pal;

    unsigned int colorCount = 0;
    for (CvBlobs::const_iterator it=blobs.begin(); it!=blobs.end(); ++it)
    {
      CvLabel label = (*it).second->label;

      Color color;

      _HSV2RGB_((double)((colorCount*77)%360), .5, 1., color.r, color.g, color.b);
      colorCount++;

      pal[label] = color;
    }

    int stepLbl = imgLabel->widthStep/(imgLabel->depth/8);
    int stepSrc = imgSource->widthStep/(imgSource->depth/8);
    int stepDst = imgDest->widthStep/(imgDest->depth/8);
    int imgLabel_width = imgLabel->width;
    int imgLabel_height = imgLabel->height;
    int imgLabel_offset = 0;
    int imgSource_width = imgSource->width;
    int imgSource_height = imgSource->height;
    int imgSource_offset = 0;
    int imgDest_width = imgDest->width;
    int imgDest_height = imgDest->height;
    int imgDest_offset = 0;
    if(imgLabel->roi)
    {
      imgLabel_width = imgLabel->roi->width;
      imgLabel_height = imgLabel->roi->height;
      imgLabel_offset = (imgLabel->nChannels * imgLabel->roi->xOffset) + (imgLabel->roi->yOffset * stepLbl);
    }
    if(imgSource->roi)
    {
      imgSource_width = imgSource->roi->width;
      imgSource_height = imgSource->roi->height;
      imgSource_offset = (imgSource->nChannels * imgSource->roi->xOffset) + (imgSource->roi->yOffset * stepSrc);
    }
    if(imgDest->roi)
    {
      imgDest_width = imgDest->roi->width;
      imgDest_height = imgDest->roi->height;
      imgDest_offset = (imgDest->nChannels * imgDest->roi->xOffset) + (imgDest->roi->yOffset * stepDst);
    }

    CvLabel *labels = (CvLabel *)imgLabel->imageData + imgLabel_offset;
    unsigned char *source = (unsigned char *)imgSource->imageData + imgSource_offset;
    unsigned char *imgData = (unsigned char *)imgDest->imageData + imgDest_offset;

    for (unsigned int r=0; r<(unsigned int)imgLabel_height; r++, labels+=stepLbl, source+=stepSrc, imgData+=stepDst)
      for (unsigned int c=0; c<(unsigned int)imgLabel_width; c++)
      {
        if (labels[c])
        {
          Color color = pal[labels[c]];

          imgData[imgDest->nChannels*c+0] = (unsigned char)((1.-alpha)*source[imgSource->nChannels*c+0]+alpha*color.b);
          imgData[imgDest->nChannels*c+1] = (unsigned char)((1.-alpha)*source[imgSource->nChannels*c+1]+alpha*color.g);
          imgData[imgDest->nChannels*c+2] = (unsigned char)((1.-alpha)*source[imgSource->nChannels*c+2]+alpha*color.r);
        }
      }
  }

  if (mode)
  {
    for (CvBlobs::const_iterator it=blobs.begin(); it!=blobs.end(); ++it)
    {
      CvBlob *blob=(*it).second;

      if (mode&CV_BLOB_RENDER_TO_LOG)
      {
	std::clog << "Blob " << blob->label << std::endl;
	std::clog << " - Bounding box: (" << blob->minx << ", " << blob->miny << ") - (" << blob->maxx << ", " << blob->maxy << ")" << std::endl;
	std::clog << " - Bounding box area: " << (1 + blob->maxx - blob->minx) * (1 + blob->maxy - blob->miny) << std::endl;
	std::clog << " - Area: " << blob->area << std::endl;
	std::clog << " - Centroid: (" << blob->centroid.x << ", " << blob->centroid.y << ")" << std::endl;
	std::clog << std::endl;
      }

      if (mode&CV_BLOB_RENDER_TO_STD)
      {
	std::cout << "Blob " << blob->label << std::endl;
	std::cout << " - Bounding box: (" << blob->minx << ", " << blob->miny << ") - (" << blob->maxx << ", " << blob->maxy << ")" << std::endl;
	std::cout << " - Bounding box area: " << (1 + blob->maxx - blob->minx) * (1 + blob->maxy - blob->miny) << std::endl;
	std::cout << " - Area: " << blob->area << std::endl;
	std::cout << " - Centroid: (" << blob->centroid.x << ", " << blob->centroid.y << ")" << std::endl;
	std::cout << std::endl;
      }

      if (mode&CV_BLOB_RENDER_BOUNDING_BOX)
        cvRectangle(imgDest,cvPoint(blob->minx,blob->miny),cvPoint(blob->maxx,blob->maxy),CV_RGB(255.,0.,0.));

      if (mode&CV_BLOB_RENDER_ANGLE)
      {
        cvCentralMoments(blob,imgLabel);
        double angle = cvAngle(blob);

        double x1,y1,x2,y2;
	double lengthLine = MAX(blob->maxx-blob->minx, blob->maxy-blob->miny)/2.;

        x1=blob->centroid.x-lengthLine*cos(angle);
        y1=blob->centroid.y-lengthLine*sin(angle);
        x2=blob->centroid.x+lengthLine*cos(angle);
        y2=blob->centroid.y+lengthLine*sin(angle);
        cvLine(imgDest,cvPoint(int(x1),int(y1)),cvPoint(int(x2),int(y2)),CV_RGB(0.,255.,0.));
      }

      if (mode&CV_BLOB_RENDER_CENTROID)
      {
	cvLine(imgDest,cvPoint(int(blob->centroid.x)-3,int(blob->centroid.y)),cvPoint(int(blob->centroid.x)+3,int(blob->centroid.y)),CV_RGB(0.,0.,255.));
	cvLine(imgDest,cvPoint(int(blob->centroid.x),int(blob->centroid.y)-3),cvPoint(int(blob->centroid.x),int(blob->centroid.y)+3),CV_RGB(0.,0.,255.));
      }
    }
  }

  __END__;
}

// Returns radians
double cvAngle(CvBlob *blob)
{
  CV_FUNCNAME("cvAngle");
  __BEGIN__;

  CV_ASSERT(blob->centralMoments);

  return .5*atan2(2.*blob->u11,(blob->u20-blob->u02));

  __END__;
}
