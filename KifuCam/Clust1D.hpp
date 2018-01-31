//
//  Clust1D.hpp
//  KifuCam
//
// The MIT License (MIT)
//
// Copyright (c) 2018 Andreas Hauenstein <hauensteina@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

// Cluster 1D numbers using simple KDE (Kernel density estimation) approach

#ifndef Clust1D_hpp
#define Clust1D_hpp

#include <iostream>
#include "Common.hpp"

class Clust1D
//================
{
public:
    // One dim clustering. Return the cutting points.
    //---------------------------------------------------------------------------
    template <typename T, typename G>
    static inline std::vector<double> cluster( const std::vector<T> &seq_, double width, G getter)
    {
        std::vector<double> cuts;
        const double SMOOTH = 3.0;
        typedef double(*WinFunc)(double,double,double);
        WinFunc winf = bell;
        
        std::vector<double> vals;
        ISLOOP (seq_) { vals.push_back( getter(seq_[i] )); }
        std::sort( vals.begin(), vals.end(), [](double a, double b) { return a<b; });
        std::vector<double> freq(vals.size());
        
        do {
            // Distance weighted sum of number of samples to the left and to the right
            ISLOOP (vals) {
                double sum = 0; int j;
                j=i;
                while( j < vals.size() && winf( vals[j], vals[i], width) > 0) {
                    sum += winf( vals[j], vals[i], width);
                    j++;
                }
                j=i;
                while( j >= 0 && winf( vals[j], vals[i], width) > 0) {
                    sum += winf( vals[j], vals[i], width);
                    j--;
                }
                freq[i] = sum;
            } // ISLOOP
            if (SZ(vals) == 0) break;
            
            // Convert to discrete pdf, missing values set to -1
            int mmax = ROUND( vec_max( vals)) + 1;
            mmax += 10; // Padding to find the rightmost cluster
            std::vector<double> pdf(mmax,-1);
            ISLOOP (freq) {
                pdf[ROUND(vals[i])] = freq[i];
            }
            pdf = smooth( pdf,SMOOTH);
            
            std::vector<double> maxes;
            ISLOOP (pdf) {
                if (i < 1) continue;
                if (i >= pdf.size()-1) continue;
                if (pdf[i] >= pdf[i-1] && pdf[i] > pdf[i+1]) {
                    maxes.push_back( i);
                }
            }
            ISLOOP (maxes) {
                if (i==0) continue;
                cuts.push_back( (maxes[i] + maxes[i-1]) / 2.0);
            }
        } while(0);
        return cuts;
    } // cluster()
    
    // Use the cuts returned by cluster() to classify new samples
    //---------------------------------------------------------------------------
    template <typename T, typename G>
    static inline void classify( std::vector<T> samples, const std::vector<double> &cuts, int minsz,
                                G getter,
                                std::vector<std::vector<T> > &parts)
    {
        std::sort( samples.begin(), samples.end(),
                  [getter](T a, T b) { return getter(a) < getter(b); });
        std::vector<std::vector<T> > res(cuts.size()+1);
        int cut=0;
        std::vector<T> part;
        ISLOOP (samples) {
            T s = samples[i];
            double x = getter(s);
            if (cut < cuts.size()) {
                if (x > cuts[cut]) {
                    res[cut] = part;
                    part.clear();
                    cut++;
                }
            }
            part.push_back( s);
        }
        res[cut] = part;
        
        // Eliminate small clusters
        std::vector<std::vector<T> > big;
        ISLOOP (res) {
            if (res[i].size() >= minsz) {
                big.push_back( res[i]);
            }
        }
        
        parts = big;
    } // classify()
    
    
private:
    // Smoothe
    //-----------------------------------------------------------------------------------------
    static inline std::vector<double> smooth( const std::vector<double> &seq, double width = 3)
    {
        std::vector<double> res( seq.size());
        ISLOOP (seq) {
            double ssum = 0;
            for (int k = i-width; k <= i+width; k++) {
                if (k < 0) continue;
                if (k >= seq.size()) continue;
                double weight = triang( i, k, width);
                ssum += seq[k] * weight;
            }
            res[i] = ssum;
        }
        return res;
    }
    
    // Various window funcs. Bell works best.
    //=========================================
    // Triangle, 1.0 at the center, falling to both sides
    //----------------------------------------------------------------
    static inline double triang( double val, double center, double width)
    {
        double d = fabs( center-val);
        double res = (1.0 - d / width);
        return res > 0 ? res : 0;
    }
    // Rectangle, 1.0 at the center, extends by width both sides
    //---------------------------------------------------------------
    static inline double rect( double val, double center, double width)
    {
        double d = fabs( center-val);
        double res = (1.0 - d / width);
        return res > 0 ? 1 : 0;
    }
    // Bell (Gaussian)
    //--------------------------------------------------------------
    static inline double bell( double val, double center, double sigma)
    {
        double d = center-val;
        double bell = exp(-(d*d) / 2*sigma);
        return bell;
    }
}; // class Clust1D


#endif /* Clust1D_hpp */

