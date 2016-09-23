/*
 * ReadMultichannelEXR()
 *
 * The ReadMultichannelEXR() mex function reads image data from an OpenEXR
 * file.  The file may contain any number of "slices" or color channels.
 *
 * Returns a struct array describing the image slices, with one element per
 * slice.  Also returns a double array with size h X w X n, where h and w
 * are the image height and width in pixels, and n is the number of slices.
 *
 * Ben Heasly wrote this function based on two sources:
 *  - the "ReadEXR" function in the HDRToolbox of David Brainard's lab at
 *  the University of Pennsylvania
 *  - the "ReadingAndWritingImageFiles" pdf from the OpenEXR web site
 *  http://www.openexr.com/documentation.html
 *
 */

#include <iostream>
#include <ImfInputFile.h>
#include <ImfChannelList.h>
#include <ImathBox.h>
#include <ImfArray.h>
#include <half.h>
#include <mex.h>
#include <matrix.h>

// make sure we have a portable 32-bit uint
#include <tmwtypes.h>
#define MATLAB_UINT32 uint32_T

using namespace Imf;
using namespace Imath;

// We use these defines to stick data read from the OpenEXR data file and
// stick it into the proper output matrix location.
#define MI(row, col, numRows) col*numRows + row
#define M3I(mDim, nDim, m, n, p) (p*mDim*nDim + n*mDim + m)

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    char *exrFileName;
    double *mxData;
    int width = 0;
    int height = 0;
    int nSlices = 0;
    
    if (nrhs != 1 || !mxIsChar(prhs[0])) {
        mexErrMsgTxt("Usage: ReadMultichannelEXR('exrFile')\n");
    }
    
    // read the exr file with OpenEXR general interface
    exrFileName = mxArrayToString(prhs[0]);
    InputFile file (exrFileName);
    
    // query general file properties
    Box2i dw = file.header().dataWindow();
    width = dw.max.x - dw.min.x + 1;
    height = dw.max.y - dw.min.y + 1;
    
    const ChannelList &channels = file.header().channels();
    for (ChannelList::ConstIterator iter = channels.begin();
    iter != channels.end();
    ++iter) {
        nSlices++;
    }
    
    mexPrintf("Read \"%s\": width=%d height=%d nSlices=%d\n",
            exrFileName, width, height, nSlices);
    mxFree(exrFileName);
    
    // return a struct with info about image slices
    mwSize nDims = 2;
    mwSize infoDims[] = {1, 0};
    infoDims[1] = nSlices;
    const char* fieldNames[] = {"name", "pixelType",
    "xSampling", "ySampling", "isLinear"};
    int nFields = sizeof(fieldNames)/sizeof(fieldNames[0]);
    plhs[0] = mxCreateStructArray(nDims, infoDims, nFields, fieldNames);
    
    // return a double array with size [height width nSlices]
    nDims = 3;
    mwSize dataDims[] = {0, 0, 0};
    dataDims[0] = height;
    dataDims[1] = width;
    dataDims[2] = nSlices;
    plhs[1] = mxCreateNumericArray(nDims, dataDims, mxDOUBLE_CLASS, mxREAL);
    if (NULL == plhs[1]) {
        mexPrintf("Could not allocate image array of size [%d %d %d]\n",
                dataDims[0], dataDims[1], dataDims[2]);
        return;
    }
    double* data = mxGetPr(plhs[1]);
    
    // fill in info struct and data array
    int channelIndex = 0;
    for (ChannelList::ConstIterator iter = channels.begin(); iter != channels.end(); ++iter) {
        const Channel &channel = iter.channel();
        
        // fill in info struct for this channel
        mxSetField(plhs[0], channelIndex, "name", mxCreateString(iter.name()));
        mxSetField(plhs[0], channelIndex, "xSampling", mxCreateDoubleScalar((double)channel.xSampling));
        mxSetField(plhs[0], channelIndex, "ySampling", mxCreateDoubleScalar((double)channel.ySampling));
        mxSetField(plhs[0], channelIndex, "isLinear", mxCreateLogicalScalar((mxLogical)channel.pLinear));
        
        // fill in a slice of the data matrix for this channel
        //  memory allocation depends on slice pixel type
        mxArray* typeName = NULL;
        FrameBuffer frameBuffer;
        switch (channel.type) {
            case UINT:{
                typeName = mxCreateString("UINT");
                
                // copy slice data from file to a frame buffer
                Array2D<MATLAB_UINT32> slicePixels;
                slicePixels.resizeErase(height, width);
                frameBuffer.insert(iter.name(),
                        Slice(HALF,
                        (char *)(&slicePixels[0][0] - dw.min.x - dw.min.y * width),
                        sizeof(slicePixels[0][0]) * 1,
                        sizeof(slicePixels[0][0]) * width,
                        channel.xSampling,
                        channel.ySampling,
                        0.0));
                file.setFrameBuffer (frameBuffer);
                file.readPixels (dw.min.y, dw.max.y);
                
                // copy slice data from frame buffer to data array
                for (int i = 0; i < height; i++) {
                    for (int j = 0; j < width; j++) {
                        data[M3I(height, width, i, j, channelIndex)] = slicePixels[i][j];
                    }
                }
                
                break;
            }
            
            case HALF:{
                typeName = mxCreateString("HALF");
                
                // copy slice data from file to a frame buffer
                Array2D<half> slicePixels;
                slicePixels.resizeErase(height, width);
                frameBuffer.insert(iter.name(),
                        Slice(HALF,
                        (char *)(&slicePixels[0][0] - dw.min.x - dw.min.y * width),
                        sizeof(slicePixels[0][0]) * 1,
                        sizeof(slicePixels[0][0]) * width,
                        channel.xSampling,
                        channel.ySampling,
                        0.0));
                file.setFrameBuffer (frameBuffer);
                file.readPixels (dw.min.y, dw.max.y);
                
                // copy slice data from frame buffer to data array
                for (int i = 0; i < height; i++) {
                    for (int j = 0; j < width; j++) {
                        data[M3I(height, width, i, j, channelIndex)] = slicePixels[i][j];
                    }
                }
                
                break;
            }
            
            case FLOAT:{
                typeName = mxCreateString("FLOAT");
                
                // copy slice data from file to a frame buffer
                Array2D<half> slicePixels;
                slicePixels.resizeErase(height, width);
                frameBuffer.insert(iter.name(),
                        Slice(HALF,
                        (char *)(&slicePixels[0][0] - dw.min.x - dw.min.y * width),
                        sizeof(slicePixels[0][0]) * 1,
                        sizeof(slicePixels[0][0]) * width,
                        channel.xSampling,
                        channel.ySampling,
                        0.0));
                file.setFrameBuffer (frameBuffer);
                file.readPixels (dw.min.y, dw.max.y);
                
                // copy slice data from frame buffer to data array
                for (int i = 0; i < height; i++) {
                    for (int j = 0; j < width; j++) {
                        data[M3I(height, width, i, j, channelIndex)] = slicePixels[i][j];
                    }
                }
                
                break;
            }
            
            default:{
                typeName = mxCreateString("UNKNOWN");
                break;
            }
        }
        mxSetField(plhs[0], channelIndex, "pixelType",  typeName);
        
        channelIndex++;
        
        //mexPrintf("  channel \"%s\": type=%d xSampling=%d ySampling=%d, isLinear=%d\n",
        //        iter.name(), channel.type,
        //        channel.xSampling, channel.ySampling, channel.pLinear);
    }
}
