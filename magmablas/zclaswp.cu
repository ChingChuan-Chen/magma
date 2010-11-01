/*
    -- MAGMA (version 1.0) --
       Univ. of Tennessee, Knoxville
       Univ. of California, Berkeley
       Univ. of Colorado, Denver
       November 2010

       @precisions mixed zc -> ds

*/

#include "cublas.h"
#include "magma.h"

#define num_threazc 64

__global__ void
zclaswp_kernel(int n, double2 *a, int lda, float2 *sa, int m, int *ipiv)
{
  int ind = blockIdx.x*num_threazc + threadIdx.x, newind;
  float2 res;

  if (ind < m) {
    sa   += ind;
    ipiv += ind;

    newind = ipiv[0];
 
    for(int i=0; i<n; i++) {
       res = (float2)a[newind+i*lda];
       sa[i*lda] = res; 
    }
  }
}

extern "C" void
magmablas_zclaswp(int n, double2 *a, int lda, float2 *sa, int m, int *ipiv)
{
/*  -- MAGMA (version 1.0) --
       Univ. of Tennessee, Knoxville
       Univ. of California, Berkeley
       Univ. of Colorado, Denver
       November 2010

    Purpose
    =======

    Row i of A is casted to single precision in row ipiv[i] of SA, 0<=i<m.

    N      - (input) INTEGER.
             On entry, N specifies the number of columns of the matrix A.

    A      - (input) DOUBLE PRECISION array on the GPU, dimension (LDA,N)
             On entry, the matrix of column dimension N and row dimension M
             to which the row interchanges will be applied.

    LDA    - (input) INTEGER.
             LDA specifies the leading dimension of A.

    SA     - (output) REAL array on the GPU, dimension (LDA,N)
             On exit, the casted to single precision and permuted matrix.
        
    M      - (input) The number of rows to be interchanged.

    IPIV   - (input) INTEGER array, dimension (M)
             The vector of pivot indices. Row i of A is casted to single 
             precision in row ipiv[i] of SA, 0<=i<m. 

    ===================================================================== */

    int blocks;
    if (m % num_threazc==0)
	blocks = m/num_threazc;
    else
        blocks = m/num_threazc + 1;

    dim3 grid(blocks, 1, 1);
    dim3 threazc(num_threazc, 1, 1);

    zclaswp_kernel<<<grid, threazc>>>(n, a, lda, sa, m, ipiv);
}

#undef num_threazc
