//
//  Common.cpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-11-15.
//  Copyright © 2017 AHN. All rights reserved.
//

//======================================
// Generally useful convenience funcs
//======================================

#include "Common.hpp"

cplx I(0.0, 1.0);

//======
// Math
//======

//---------------------------------------------------
void _fft(cplx buf[], cplx out[], int n, int step)
{
    if (step < n) {
        _fft( out, buf, n, step * 2);
        _fft( out + step, buf + step, n, step * 2);
        
        for (int i = 0; i < n; i += 2 * step) {
            cplx t = exp( -I * PI * (cplx(i) / cplx(n))) * out[ i + step];
            buf[ i / 2]     = out[i] + t;
            buf[ (i + n)/2] = out[i] - t;
        }
    }
}

//---------------------------
void fft(cplx buf[], int n)
{
    cplx out[n];
    for (int i = 0; i < n; i++) out[i] = buf[i];
    
    _fft( buf, out, n, 1);
}

// Debugger Helpers
//======================

// Print a vector
//--------------------------------------------
void print_vecf( std::vector<double> v)
{
    printf("(\n");
    ISLOOP (v) {
        printf( "%8.2f\n", v[i]);
    }
    printf(")\n");
}

//--------------------------------------------
void print_veci( std::vector<int> v)
{
    printf("(\n");
    ISLOOP (v) {
        printf( "%d\n", v[i]);
    }
    printf(")\n");
}


