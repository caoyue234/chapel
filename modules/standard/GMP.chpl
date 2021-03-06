/*
 * Copyright 2004-2016 Cray Inc.
 * Other additional copyright holders may be indicated within.
 *
 * The entirety of this work is licensed under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 *
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*

Support for GNU Multiple Precision Arithmetic

This module provides a low-level interface to a substantial fraction
of the GMP library (the GNU Multiple Precision arithmetic library).
This support includes the C types for GMP integers, floating point
numbers, and random numbers, and nearly every operation on those
types. These types and functions enable efficient multi-precision
computation within a single locale.  See the `GMP homepage
<https://gmplib.org/>`_ for more information on this library.

The module :mod:`BigInteger` leverages this interface to define the
record :record:`~BigInteger.bigint`.  The methods on the record
:record:`~BigInteger.bigint` are locale aware so that Chapel programs
can, for example, create a distributed array of GMP integers. That
record also provides operator overloads for the standard arithmetic
and assignment operators which tend to enable a more natural
expression of some algorithms.  Please see the documentation in
:mod:`BigInteger` for details.

Using the GMP Module
--------------------

Step 1:
  Build Chapel with GMP

  .. code-block:: sh

            # To use the already-installed GMP
            export CHPL_GMP=system
            # To use the distributed GMP
            export CHPL_GMP=gmp
            # From $CHPL_HOME
            make clean; make


Step 2:
  Have your Chapel program ``use`` the standard GMP module

  .. code-block:: chapel

            use GMP;   // put this statement in your Chapel program


Step 3:
  Start using the supported subset of GMP types and routines defined
  in this module or the bigint record (see :mod:`BigInteger`).


Calling GMP functions directly
------------------------------

The low-level option for Chapel programs using multi-precision numbers
is to the GMP functions directly. For a full reference to GMP capabilities,
please refer to the `GMP website <https://gmplib.org>`_ and the
`GMP documentation <https://gmplib.org/manual/>`_.


At present, Chapel's GMP module supports the following GMP types:

  * :type:`mp_bitcnt_t`
  * :type:`mpf_t`
  * :type:`mpz_t`

And all :type:`mpz_t` GMP routines, as well as the following routines:

  * :proc:`gmp_fprintf()`
  * :proc:`gmp_printf()`
  * :proc:`mpf_add()`
  * :proc:`mpf_clear()`
  * :proc:`mpf_div_2exp()`
  * :proc:`mpf_get_d()`
  * :proc:`mpf_get_prec()`
  * :proc:`mpf_init()`
  * :proc:`mpf_mul()`
  * :proc:`mpf_mul_ui()`
  * :proc:`mpf_out_str()`
  * :proc:`mpf_set_d()`
  * :proc:`mpf_set_default_prec()`
  * :proc:`mpf_set_prec_raw()`
  * :proc:`mpf_set_z()`
  * :proc:`mpf_sub()`
  * :proc:`mpf_ui_div()`
  * :proc:`mpf_ui_sub()`

The BigInt class
----------------

This class is deprecated for release 1.14 (Fall 2016) and will not be
present in release 1.15 (Spring 2017).  Please see the record
:record:`~BigInteger.bigint` in the module :mod:`BigInteger` for
the replacement for this class.

This module also provides a class :class:`BigInt` that wraps GMP
integers.  Nearly every GMP function for the GMP type ``mpz_t`` is
wrapped by a method with a similar name.  These methods are locale
aware - so Chapel programs can, for example, create a distributed
array of GMP numbers.  A method of a :class:`BigInt` object set the
receiver so that, for example, myBigInt.add(x,y) sets myBigInt to ``x
+ y``.

A code example::

 use GMP;

 // initialize a GMP value, set it to zero
 var a = new BigInt();

 a.fac_ui(100);     // set a to 100!

 writeln(a);        // output 100!

 delete a;          // free memory used by the GMP value

 // initialize from a decimal string
 var b = new BigInt("48473822929893829847");

 b.add_ui(b, 1);    // add one to b

 delete b;          // free memory used by b

*/
module GMP {
  use SysBasic;
  use Error;
  use BigInteger;

  /* The GMP ``mp_bitcnt_t`` type */
  extern type mp_bitcnt_t     = c_ulong;

  /* The GMP ``mp_size_t``   type */
  extern type mp_size_t       = size_t;

  /* The GMP ``mp_limb_t``   type. */
  extern type mp_limb_t       = uint(64);

  /* The GMP `mp_bits_per_limb`` constant */
  extern const mp_bits_per_limb: c_int;


  //
  // GMP represents a multi-precision integer as an __mpz_struct.
  // This is treated as an internal type by GMP and is not intended to
  // used directly by C developers.  Chapel treats this as an opaque object.
  //
  // In practice the implementation is a dynamically-sized packed vector
  // of platform-specific integers i.e.
  //
  //     typedef struct {
  //       int        _mp_alloc;  // capacity
  //       int        _mp_size;   // current size
  //       mp_limb_t* _mp_d;      // a packed vector of integers
  //     } __mpz_struct;
  //
  //
  // GMP then defines the type mpz_t as
  //
  //     typedef __mpz_struct mpz_t[1];
  //
  // When used to define a C value, this is simply a single __mpz_struct.
  // As an argument to a function, this causes the value to be passed by
  // reference rather than by value as would be expected for a struct.
  //
  //
  // For single locale applications the application programmer is
  // responsible for ensuring that every mpz_t is initialized correctly
  // and that it is cleared/freed when it is no longer needed.
  //
  // For multi-locale applications the application programmer must be aware
  // that Chapel creates shallow copies of this data structure within
  // on-statements; the _mp_d value will not be valid on the remote locale.
  // The developer may invoke chpl_gmp_get_mpz() to create a local copy of
  // the actual GMP data.
  //

  pragma "no doc"
  extern type __mpz_struct;

  /* The GMP ``mpz_t`` type */
  extern type mpz_t           = 1 * __mpz_struct;

  pragma "no doc"
  extern type __mpf_struct;

  /*  The GMP ``mpf_t`` type */
  extern type mpf_t           = 1 * __mpf_struct;

  pragma "no doc"
  extern type __gmp_randstate_struct;


  /* The GMP ``gmp_randstate_t`` type */
  extern type gmp_randstate_t = 1 * __gmp_randstate_struct;

  //
  // The organization of the following interfaces is aligned with
  //
  //      https://gmplib.org/manual/index.html
  //
  // for version 6.1.1


  //
  // 5 Integer Functions
  //

  //
  // 5.1 Initializing Functions
  //

  /* */
  extern proc mpz_init(ref x: mpz_t);

  extern proc mpz_init2(ref x: mpz_t, n: mp_bitcnt_t);

  extern proc mpz_clear(ref x: mpz_t);

  extern proc mpz_realloc2(ref x: mpz_t, n: mp_bitcnt_t);


  //
  // 5.2 Assignment Functions
  //

  extern proc mpz_set(ref rop: mpz_t, const ref op: mpz_t);

  extern proc mpz_set_ui(ref rop: mpz_t, op: c_ulong);

  extern proc mpz_set_si(ref rop: mpz_t, op: c_long);

  extern proc mpz_set_d(ref rop: mpz_t, op: c_double);

  extern proc mpz_set_str(ref rop: mpz_t, str: c_string, base: c_int);

  extern proc mpz_swap(ref rop1: mpz_t, ref rop2: mpz_t);


  //
  // 5.3 Combined Initialization and Assignment Functions
  //

  extern proc mpz_init_set(ref rop: mpz_t, const ref op: mpz_t);

  extern proc mpz_init_set_ui(ref rop: mpz_t, op: c_ulong);

  extern proc mpz_init_set_si(ref rop: mpz_t, op: c_long);

  extern proc mpz_init_set_d(ref rop: mpz_t, op: c_double);

  extern proc mpz_init_set_str(ref rop: mpz_t,
                               str: c_string,
                               base: c_int) : c_int;


  //
  // 5.4 Conversion Functions
  //

  extern proc mpz_get_ui(const ref op: mpz_t) : c_ulong;

  extern proc mpz_get_si(const ref op: mpz_t) : c_long;

  extern proc mpz_get_d(const ref op: mpz_t) : c_double;

  extern proc mpz_get_d_2exp(ref exp: c_long,
                             const ref op: mpz_t) : c_double;

  extern proc mpz_get_str(str: c_string,
                          base: c_int,
                          const ref op: mpz_t) : c_string;


  //
  // 5.5 Arithmetic Functions
  //

  extern proc mpz_add(ref rop: mpz_t,
                      const ref op1: mpz_t,
                      const ref op2: mpz_t);

  extern proc mpz_add_ui(ref rop: mpz_t,
                         const ref op1: mpz_t,
                         op2: c_ulong);

  extern proc mpz_sub(ref rop: mpz_t,
                      const ref op1: mpz_t,
                      const ref op2: mpz_t);

  extern proc mpz_sub_ui(ref rop: mpz_t,
                         const ref op1: mpz_t,
                         op2: c_ulong);

  extern proc mpz_ui_sub(ref rop: mpz_t,
                         op1: c_ulong,
                         const ref op2: mpz_t);

  extern proc mpz_mul(ref rop: mpz_t,
                      const ref op1: mpz_t,
                      const ref op2: mpz_t);

  extern proc mpz_mul_si(ref rop: mpz_t,
                         const ref op1: mpz_t,
                         op2: c_long);

  extern proc mpz_mul_ui(ref rop: mpz_t,
                         const ref op1: mpz_t,
                         op2: c_ulong);

  extern proc mpz_addmul(ref rop: mpz_t,
                         const ref op1: mpz_t,
                         const ref op2: mpz_t);

  extern proc mpz_addmul_ui(ref rop: mpz_t,
                            const ref op1: mpz_t,
                            op2: c_ulong);

  extern proc mpz_submul(ref rop: mpz_t,
                         const ref op1: mpz_t,
                         const ref op2: mpz_t);

  extern proc mpz_submul_ui(ref rop: mpz_t,
                            const ref op1: mpz_t,
                            op2: c_ulong);

  extern proc mpz_mul_2exp(ref rop: mpz_t,
                           const ref op1: mpz_t,
                           op2: mp_bitcnt_t);

  extern proc mpz_neg(ref rop: mpz_t,
                      const ref op: mpz_t);

  extern proc mpz_abs(ref rop: mpz_t,
                      const ref op: mpz_t);


  //
  // 5.6 Division Functions
  //

  extern proc mpz_cdiv_q(ref q: mpz_t,
                         const ref n: mpz_t,
                         const ref d: mpz_t);

  extern proc mpz_cdiv_r(ref r: mpz_t,
                         const ref n: mpz_t,
                         const ref d: mpz_t);

  extern proc mpz_cdiv_qr(ref q: mpz_t,
                          ref r: mpz_t,
                          const ref n: mpz_t,
                          const ref d: mpz_t);

  extern proc mpz_cdiv_q_ui(ref q: mpz_t,
                            const ref n: mpz_t,
                            d: c_ulong) : c_ulong;

  extern proc mpz_cdiv_r_ui(ref r: mpz_t,
                            const ref n: mpz_t,
                            d: c_ulong) : c_ulong;

  extern proc mpz_cdiv_qr_ui(ref q: mpz_t,
                             ref r: mpz_t,
                             const ref n: mpz_t,
                             d: c_ulong) : c_ulong;

  extern proc mpz_cdiv_ui(const ref n: mpz_t,
                          d: c_ulong) : c_ulong;

  extern proc mpz_cdiv_q_2exp(ref q: mpz_t,
                              const ref n: mpz_t,
                              b: mp_bitcnt_t);

  extern proc mpz_cdiv_r_2exp(ref r: mpz_t,
                              const ref n: mpz_t,
                              b: mp_bitcnt_t);


  //
  extern proc mpz_fdiv_q(ref q: mpz_t,
                         const ref n: mpz_t,
                         const ref d: mpz_t);

  extern proc mpz_fdiv_r(ref r: mpz_t,
                         const ref n: mpz_t,
                         const ref d: mpz_t);

  extern proc mpz_fdiv_qr(ref q: mpz_t,
                          ref r: mpz_t,
                          const ref n: mpz_t,
                          const ref d: mpz_t);

  extern proc mpz_fdiv_q_ui(ref q: mpz_t,
                            const ref n: mpz_t,
                            d: c_ulong) : c_ulong;

  extern proc mpz_fdiv_r_ui(ref r: mpz_t,
                            const ref n: mpz_t,
                            d: c_ulong) : c_ulong;

  extern proc mpz_fdiv_qr_ui(ref q: mpz_t,
                             ref r: mpz_t,
                             const ref n: mpz_t,
                             d: c_ulong) : c_ulong;

  extern proc mpz_fdiv_ui(const ref n: mpz_t,
                          d: c_ulong) : c_ulong;

  extern proc mpz_fdiv_q_2exp(ref q: mpz_t,
                              const ref n: mpz_t,
                              b: mp_bitcnt_t);

  extern proc mpz_fdiv_r_2exp(ref r: mpz_t,
                              const ref n: mpz_t,
                              b: mp_bitcnt_t);


  //
  extern proc mpz_tdiv_q(ref q: mpz_t,
                         const ref n: mpz_t,
                         const ref d: mpz_t);

  extern proc mpz_tdiv_r(ref r: mpz_t,
                         const ref n: mpz_t,
                         const ref d: mpz_t);

  extern proc mpz_tdiv_qr(ref q: mpz_t,
                          ref r: mpz_t,
                          const ref n: mpz_t,
                          const ref d: mpz_t);

  extern proc mpz_tdiv_q_ui(ref q: mpz_t,
                            const ref n: mpz_t,
                            d: c_ulong) : c_ulong;

  extern proc mpz_tdiv_r_ui(ref r: mpz_t,
                            const ref n: mpz_t,
                            d: c_ulong) : c_ulong;

  extern proc mpz_tdiv_qr_ui(ref q: mpz_t,
                             ref r: mpz_t,
                             const ref n: mpz_t,
                             d: c_ulong) : c_ulong;

  extern proc mpz_tdiv_ui(const ref n: mpz_t,
                          d: c_ulong) : c_ulong;

  extern proc mpz_tdiv_q_2exp(ref q: mpz_t,
                              const ref n: mpz_t,
                              b: mp_bitcnt_t);

  extern proc mpz_tdiv_r_2exp(ref r: mpz_t,
                              const ref n: mpz_t,
                              b: mp_bitcnt_t);


  //
  extern proc mpz_mod(ref rop: mpz_t,
                      const ref n: mpz_t,
                      const ref d: mpz_t);

  extern proc mpz_mod_ui(ref rop: mpz_t,
                         const ref n: mpz_t,
                         d: c_ulong) : c_ulong;

  extern proc mpz_divexact(ref q: mpz_t,
                           const ref n: mpz_t,
                           const ref d: mpz_t);

  extern proc mpz_divexact_ui(ref q: mpz_t,
                              const ref n: mpz_t,
                              d: c_ulong);

  extern proc mpz_divisible_p(const ref n: mpz_t,
                              const ref d: mpz_t) : c_int;

  extern proc mpz_divisible_ui_p(const ref n: mpz_t,
                                 d: c_ulong) : c_int;

  extern proc mpz_divisible_2exp_p(const ref n: mpz_t,
                                   b: mp_bitcnt_t) : c_int;

  extern proc mpz_congruent_p(const ref n: mpz_t,
                              const ref c: mpz_t,
                              const ref d: mpz_t) : c_int;

  extern proc mpz_congruent_ui_p(const ref n: mpz_t,
                                 c: c_ulong,
                                 d: c_ulong) : c_int;

  extern proc mpz_congruent_2exp_p(const ref n: mpz_t,
                                   const ref c: mpz_t,
                                   b: mp_bitcnt_t) : c_int;


  //
  // 5.7 Exponentiation Functions
  //

  extern proc mpz_powm(ref rop: mpz_t,
                       const ref base: mpz_t,
                       const ref exp: mpz_t,
                       const ref mod: mpz_t);

  extern proc mpz_powm_ui(ref rop: mpz_t,
                          const ref base: mpz_t,
                          exp: c_ulong,
                          const ref mod: mpz_t);

  extern proc mpz_powm_sec(ref rop: mpz_t,
                           const ref base: mpz_t,
                           const ref exp: mpz_t,
                           const ref mod:  mpz_t);

  extern proc mpz_pow_ui(ref rop: mpz_t,
                         const ref base: mpz_t,
                         exp: c_ulong);

  extern proc mpz_ui_pow_ui(ref rop: mpz_t,
                            base: c_ulong,
                            exp: c_ulong);


  //
  // 5.8 Root Extraction Functions
  //

  extern proc mpz_root(ref rop: mpz_t,
                       const ref op: mpz_t,
                       n: c_ulong) : c_int;

  extern proc mpz_rootrem(ref root: mpz_t,
                          ref rem: mpz_t,
                          const ref u: mpz_t,
                          n: c_ulong);

  extern proc mpz_sqrt(ref rop: mpz_t,
                       const ref op: mpz_t);

  extern proc mpz_sqrtrem(ref rop1: mpz_t,
                          ref rop2: mpz_t,
                          const ref op: mpz_t);

  extern proc mpz_perfect_power_p(const ref op: mpz_t) : c_int;

  extern proc mpz_perfect_square_p(const ref op: mpz_t) : c_int;


  //
  // 5.9 Number Theoretic Functions
  //

  extern proc mpz_probab_prime_p(ref n: mpz_t,
                                 reps: c_int) : c_int;

  extern proc mpz_nextprime(ref rop: mpz_t,
                            const ref op: mpz_t);

  extern proc mpz_gcd(ref rop: mpz_t,
                      const ref op1: mpz_t,
                      const ref op2: mpz_t);

  extern proc mpz_gcd_ui(ref rop: mpz_t,
                         const ref op1: mpz_t,
                         op2: c_ulong);

  extern proc mpz_gcdext(ref g: mpz_t,
                         ref s: mpz_t,
                         ref t: mpz_t,
                         const ref a: mpz_t,
                         const ref b: mpz_t);

  extern proc mpz_lcm(ref rop: mpz_t,
                      const ref op1: mpz_t,
                      const ref op2: mpz_t);

  extern proc mpz_lcm_ui(ref rop: mpz_t,
                         const ref op1: mpz_t,
                         op2: c_ulong);

  extern proc mpz_invert(ref rop: mpz_t,
                         const ref op1: mpz_t,
                         const ref op2: mpz_t) : c_int;

  extern proc mpz_jacobi(const ref a: mpz_t,
                         const ref b: mpz_t) : c_int;

  extern proc mpz_legendre(const ref a: mpz_t,
                           const ref p: mpz_t) : c_int;

  extern proc mpz_kronecker(const ref a: mpz_t,
                            const ref b: mpz_t) : c_int;

  extern proc mpz_kronecker_si(const ref a: mpz_t,
                               b: c_long) : c_int;

  extern proc mpz_kronecker_ui(const ref a: mpz_t,
                               b: c_ulong) : c_int;

  extern proc mpz_si_kronecker(a: c_long,
                               const ref b: mpz_t) : c_int;

  extern proc mpz_ui_kronecker(a: c_ulong,
                               const ref b: mpz_t) : c_int;

  extern proc mpz_remove(ref rop: mpz_t,
                         const ref op: mpz_t,
                         const ref f: mpz_t) : c_ulong;

  extern proc mpz_fac_ui(ref rop: mpz_t,
                         n: c_ulong);

  extern proc mpz_2fac_ui(ref rop: mpz_t,
                          n: c_ulong);

  extern proc mpz_mfac_uiui(ref rop: mpz_t,
                            n: c_ulong,
                            m: c_ulong);

  extern proc mpz_primorial_ui(ref rop: mpz_t,
                               n: c_ulong);

  extern proc mpz_bin_ui(ref rop: mpz_t,
                         const ref n: mpz_t,
                         k: c_ulong);

  extern proc mpz_bin_uiui(ref rop: mpz_t,
                           n: c_ulong,
                           k: c_ulong);

  extern proc mpz_fib_ui(ref fn: mpz_t,
                         n: c_ulong);

  extern proc mpz_fib2_ui(ref fn: mpz_t,
                          ref fnsub1: mpz_t,
                          n: c_ulong);

  extern proc mpz_lucnum_ui(ref ln: mpz_t,
                            n: c_ulong);

  extern proc mpz_lucnum2_ui(ref ln: mpz_t,
                             ref lnsub1: mpz_t,
                             n: c_ulong);


  //
  // 5.10 Comparison Functions
  //

  extern proc mpz_cmp(const ref op1: mpz_t,
                      const ref op2: mpz_t) : c_int;

  extern proc mpz_cmp_d(const ref op1: mpz_t,
                        op2: c_double) : c_int;

  extern chpl_mpz_cmp_si
         proc mpz_cmp_si(const ref op1: mpz_t,
                         op2: c_long) : c_int;

  extern chpl_mpz_cmp_ui
         proc mpz_cmp_ui(const ref op1: mpz_t,
                         op2: c_ulong) : c_int;

  extern proc mpz_cmpabs(const ref op1: mpz_t,
                         const ref op2: mpz_t) : c_int;

  extern proc mpz_cmpabs_d(const ref op1: mpz_t,
                           op2: c_double) : c_int;

  extern proc mpz_cmpabs_ui(const ref op1: mpz_t,
                            op2: c_ulong) : c_int;

  extern chpl_mpz_sgn
         proc mpz_sgn(const ref op: mpz_t) : c_int;


  //
  // 5.11 Logical and Bit Manipulation Functions
  //

  extern proc mpz_and(ref rop: mpz_t,
                      const ref op1: mpz_t,
                      const ref op2: mpz_t);

  extern proc mpz_ior(ref rop: mpz_t,
                      const ref op1: mpz_t,
                      const ref op2: mpz_t);

  extern proc mpz_xor(ref rop: mpz_t,
                      const ref op1: mpz_t,
                      const ref op2: mpz_t);

  extern proc mpz_com(ref rop: mpz_t,
                      const ref op: mpz_t);

  extern proc mpz_popcount(const ref op: mpz_t) : c_ulong;

  extern proc mpz_hamdist(const ref op1: mpz_t,
                          const ref op2: mpz_t) : c_ulong;

  extern proc mpz_scan0(const ref op: mpz_t,
                        starting_bit: mp_bitcnt_t) : c_ulong;

  extern proc mpz_scan1(const ref op: mpz_t,
                        starting_bit: mp_bitcnt_t) : c_ulong;

  extern proc mpz_setbit(ref rop: mpz_t,
                         bit_index: mp_bitcnt_t);

  extern proc mpz_clrbit(ref rop: mpz_t,
                         bit_index: mp_bitcnt_t);

  extern proc mpz_combit(ref rop: mpz_t,
                         bit_index: mp_bitcnt_t);

  extern proc mpz_tstbit(const ref op: mpz_t,
                         bit_index: mp_bitcnt_t) : c_int;


  //
  // 5.12 Input and Output Functions
  //


  //
  // 5.13 Random Number Functions
  //

  extern proc mpz_urandomb(ref rop: mpz_t,
                           ref state: gmp_randstate_t,
                           n: mp_bitcnt_t);

  extern proc mpz_urandomm(ref rop: mpz_t,
                           ref state: gmp_randstate_t,
                           const ref n: mpz_t);

  extern proc mpz_rrandomb(ref rop: mpz_t,
                           ref state: gmp_randstate_t,
                           n: mp_bitcnt_t);

  extern proc mpz_random(ref rop: mpz_t,
                         max_size: mp_size_t);

  extern proc mpz_random2(ref rop: mpz_t,
                         max_size: mp_size_t);


  //
  // 5.14 Integer Import and Export
  //


  //
  // 5.15 Miscellaneous Functions
  //

  extern proc mpz_fits_ulong_p(const ref op: mpz_t) : c_int;

  extern proc mpz_fits_slong_p(const ref op: mpz_t) : c_int;

  extern proc mpz_fits_uint_p(const ref op: mpz_t) : c_int;

  extern proc mpz_fits_sint_p(const ref op: mpz_t) : c_int;

  extern proc mpz_fits_ushort_p(const ref op: mpz_t) : c_int;

  extern proc mpz_fits_sshort_p(const ref op: mpz_t) : c_int;

  extern chpl_mpz_odd_p
         proc mpz_odd_p(const ref op: mpz_t) : c_int;

  extern chpl_mpz_even_p
         proc mpz_even_p(const ref op: mpz_t) : c_int;

  extern proc mpz_sizeinbase(const ref op: mpz_t,
                             base: c_int) : size_t;


  //
  // 5.16 Special Functions
  //

  extern proc mpz_getlimbn(const ref op: mpz_t,
                           n: mp_size_t) : mp_limb_t;

  extern proc mpz_size(const ref x: mpz_t): size_t;


  //
  // Floating-point Functions
  //


  //
  // 7.1 Initialization Functions
  //

  extern proc mpf_set_default_prec(prec: mp_bitcnt_t);

  extern proc mpf_get_default_prec() : mp_bitcnt_t;

  extern proc mpf_init(ref x: mpf_t);

  extern proc mpf_init2(ref x: mpf_t, prec: mp_bitcnt_t);

  extern proc mpf_clear(ref x: mpf_t);

  extern proc mpf_get_prec(const ref op: mpf_t) : mp_bitcnt_t;

  extern proc mpf_set_prec(ref rop: mpf_t,
                           prec: mp_bitcnt_t);

  extern proc mpf_set_prec_raw(ref rop: mpf_t,
                               prec: mp_bitcnt_t);


  //
  // 7.2 Assignment Functions
  //

  extern proc mpf_set(ref rop: mpf_t,
                      const ref op: mpz_t);

  extern proc mpf_set_ui(ref rop: mpf_t,
                         op: c_ulong);

  extern proc mpf_set_si(ref rop: mpf_t,
                         op: c_long);

  extern proc mpf_set_d(ref rop: mpf_t,
                        op: c_double);

  extern proc mpf_set_z(ref rop: mpf_t,
                        const ref op: mpz_t);

  extern proc mpf_set_q(ref rop: mpf_t,
                        const ref op: mpz_t);

  extern proc mpf_set_str(ref rop: mpz_t,
                          str: c_string,
                          base: c_int);

  extern proc mpf_swap(ref rop1: mpf_t,
                       ref rop2: mpz_t);


  //
  // 7.3 Combined Initialization and Assignment Functions
  //

  extern proc mpf_init_set(ref rop: mpf_t,
                           const ref op: mpz_t);

  extern proc mpf_init_set_ui(ref rop: mpf_t,
                              op: c_ulong);

  extern proc mpf_init_set_si(ref rop: mpf_t,
                              op: c_long);

  extern proc mpf_init_set_d(ref rop: mpf_t,
                             op: c_double);


  //
  // 7.4 Conversion Functions
  //

  extern proc mpf_get_d(const ref op: mpf_t) : c_double;

  extern proc mpf_get_d_2exp(ref exp: c_long,
                             const ref op: mpz_t) : c_double;

  extern proc mpf_get_si(const ref op: mpf_t) : c_long;

  extern proc mpf_get_ui(const ref op: mpf_t) : c_ulong;


  //
  // 7.5 Arithmetic Functions
  //

  extern proc mpf_add(ref rop: mpf_t,
                      const ref op1: mpf_t,
                      const ref op2: mpf_t);

  extern proc mpf_add_ui(ref rop: mpf_t,
                         const ref op1: mpf_t,
                         op2: c_ulong);

  extern proc mpf_sub(ref rop: mpf_t,
                      const ref op1: mpf_t,
                      const ref op2: mpf_t);

  extern proc mpf_ui_sub(ref rop: mpf_t,
                         op1: c_ulong,
                         const ref op2: mpf_t);

  extern proc mpf_sub_ui(ref rop: mpf_t,
                         const ref op1: mpf_t,
                         op2: c_ulong);

  extern proc mpf_mul(ref rop: mpf_t,
                      const ref op1: mpf_t,
                      const ref op2: mpf_t);

  extern proc mpf_mul_ui(ref rop: mpf_t,
                         const ref op1: mpf_t,
                         op2: c_ulong);

  extern proc mpf_div(ref rop: mpf_t,
                      const ref op1: mpf_t,
                      const ref op2: mpf_t);

  extern proc mpf_ui_div(ref rop: mpf_t,
                         op1: c_ulong,
                         const ref op2: mpf_t);

  extern proc mpf_div_ui(ref rop: mpf_t,
                         const ref op1: mpf_t,
                         op2: c_ulong);

  extern proc mpf_sqrt(ref rop: mpf_t,
                       const ref op: mpf_t);

  extern proc mpf_sqrt_ui(ref rop: mpf_t,
                          op: c_ulong);

  extern proc mpf_pow_ui(ref rop: mpf_t,
                         const ref op1: mpf_t,
                         op2: c_ulong);

  extern proc mpf_neg(ref rop: mpf_t,
                      const ref op: mpf_t);

  extern proc mpf_abs(ref rop: mpf_t,
                      const ref op: mpf_t);

  extern proc mpf_mul_2exp(ref rop: mpf_t,
                           const ref op1: mpf_t,
                           op2: mp_bitcnt_t);

  extern proc mpf_div_2exp(ref rop: mpf_t,
                           const ref op1: mpf_t,
                           op2: mp_bitcnt_t);


  //
  // 7.6 Comparison Functions
  //

  extern proc mpf_cmp(const ref op1: mpf_t,
                      const ref op2: mpf_t) : c_int;

  extern proc mpf_cmp_z(const ref op1: mpf_t,
                        const ref op2: mpf_t) : c_int;

  extern proc mpf_cmp_d(const ref op1: mpf_t,
                        op2: c_double) : c_int;

  extern proc mpf_cmp_ui(const ref op1: mpf_t,
                         op2: c_ulong) : c_int;

  extern proc mpf_cmp_si(const ref op1: mpf_t,
                         op2: c_long) : c_int;

  extern proc mpf_eq(const ref op1: mpf_t,
                     const ref op2: mpf_t,
                     op3: mp_bitcnt_t) : c_int;

  extern proc mpf_reldiff(const ref rop: mpf_t,
                          const ref op1: mpf_t,
                          const ref op2: mpf_t);

  extern proc mpf_sgn(const ref op: mpf_t);


  //
  // 7.7 Input and Output Functions
  //

  extern proc mpf_out_str(stream: _file,
                          base: c_int,
                          n_digits: size_t,
                          const ref op: mpf_t);

  extern proc mpf_inp_str(ref rop: mpf_t,
                          stream: _file,
                          base: c_int);


  //
  // 7.8 Miscellaneous Functions
  //

  extern proc mpf_ceil(ref rop: mpf_t,
                       const ref op: mpf_t);

  extern proc mpf_floor(ref rop: mpf_t,
                        const ref op: mpf_t);

  extern proc mpf_trunc(ref rop: mpf_t,
                        const ref op: mpf_t);

  extern proc mpf_integer_p(const ref op: mpf_t) : c_int;

  extern proc mpf_fits_ulong_p(const ref op: mpf_t) : c_int;

  extern proc mpf_fits_slong_p(const ref op: mpf_t) : c_int;

  extern proc mpf_fits_uint_p(const ref op: mpf_t) : c_int;

  extern proc mpf_fits_sint_p(const ref op: mpf_t) : c_int;

  extern proc mpf_fits_ushort_p(const ref op: mpf_t) : c_int;

  extern proc mpf_fits_sshort_p(const ref op: mpf_t) : c_int;

  extern proc mpf_urandomb(ref rop: mpf_t,
                           ref state: gmp_randstate_t,
                           nbits : mp_bitcnt_t);


  //
  // 9 Random Number Functions
  //


  //
  // 9.1 Random State Initialization
  //

  extern proc gmp_randinit_default(ref state: gmp_randstate_t);

  extern proc gmp_randinit_mt(ref state: gmp_randstate_t);

  extern proc gmp_randinit_lc_2exp(ref state: gmp_randstate_t,
                                   const ref a: mpz_t,
                                   c: c_ulong,
                                   m2exp: mp_bitcnt_t);

  extern proc gmp_randinit_lc_2exp_size(ref state: gmp_randstate_t,
                                        size: mp_bitcnt_t);

  extern proc gmp_randinit_set(ref rop: gmp_randstate_t,
                               ref op: gmp_randstate_t);

  extern proc gmp_randclear(ref state: gmp_randstate_t);


  //
  // 9.2 Random State Seeding
  //

  extern proc gmp_randseed(ref state: gmp_randstate_t,
                           const ref seed: mpz_t);

  extern proc gmp_randseed_ui(ref state: gmp_randstate_t,
                              seed: c_ulong);


  //
  // 9.3 Random State Miscellaneous
  //

  extern proc gmp_urandomb_ui(ref state: gmp_randstate_t,
                              n: c_ulong) : c_ulong;

  extern proc gmp_urandomm_ui(ref state: gmp_randstate_t,
                              n: c_ulong) : c_ulong;


  //
  // printf/scanf
  //
  extern proc gmp_printf(fmt: c_string, arg...);

  extern proc gmp_fprintf(fp: _file, fmt: c_string, arg...);

  extern proc gmp_fprintf(fp: _file, fmt: c_string, arg...);

  extern proc gmp_asprintf(ref ret: c_string, fmt: c_string, arg...);


  //
  // Initialize GMP to use Chapel's allocator
  //
  private extern proc chpl_gmp_init();

  /* Get an MPZ value stored on another locale */
  extern proc chpl_gmp_get_mpz(ref ret: mpz_t,
                               src_local: int,
                               from: __mpz_struct);

  /* Get a randstate value stored on another locale */
  private extern
  proc chpl_gmp_get_randstate(not_inited_state: gmp_randstate_t,
                              src_locale: int,
                              from: __gmp_randstate_struct);

  /* Return the number of limbs in an __mpz_struct */
  private extern proc chpl_gmp_mpz_nlimbs(from: __mpz_struct) : uint(64);

  /* Print out an mpz_t (for debugging) */
  extern proc chpl_gmp_mpz_print(const ref x: mpz_t);

  /* Get an mpz_t as a string */
  extern proc chpl_gmp_mpz_get_str(base: c_int, const ref x: mpz_t) : c_string_copy;


  enum Round {
    DOWN = -1,
    ZERO =  0,
    UP   =  1
  }

  /*
    This class is deprecated for release 1.14 (Fall 2016) and will not
    be present in release 1.15 (Spring 2017).  Please see the record
    :record:`~BigInteger.bigint` in the module :mod:`BigInteger` for
    the replacement for this class.


    The BigInt class provides a more Chapel-friendly interface to the
    GMP integer functions. In particular, this class supports GMP
    integers that can be stored in distributed arrays.

    All methods on BigInt work with Chapel types. Many of them use the gmp
    functions directly, which use C types. Runtime checks are used to ensure
    the Chapel types can safely be cast to the C types (e.g. when casting a
    Chapel uint it checks that it fits in the C ulong which could be a 32 bit
    type if running on linux32 platform).

    The checks are controlled by the compiler options ``--[no-]cast-checks``,
    ``--fast``, etc.
  */
  class BigInt {
    var mpz: mpz_t;

    // initializing integers (constructors)
    proc BigInt(init2: bool, nbits: uint) {
      compilerWarning("The class GMP.BigInt has been deprecated.  Please use the record BigInteger.bigint instead");

      mpz_init2(this.mpz, nbits.safeCast(c_ulong));
    }

    proc BigInt(num: int) {
      compilerWarning("The class GMP.BigInt has been deprecated.  Please use the record BigInteger.bigint instead");

      mpz_init_set_si(this.mpz, num.safeCast(c_long));
    }

    proc BigInt(str: string, base: int = 0) {
      compilerWarning("The class GMP.BigInt has been deprecated.  Please use the record BigInteger.bigint instead");

      var e: c_int;

      e = mpz_init_set_str(this.mpz,
                           str.localize().c_str(),
                           base.safeCast(c_int));

      if e {
        mpz_clear(this.mpz);

        halt("Error initializing big integer: bad format");
      }
    }

    proc BigInt(str: string, base: int = 0, out error: syserr) {
      compilerWarning("The class GMP.BigInt has been deprecated.  Please use the record BigInteger.bigint instead");

      var e: c_int;

      error = ENOERR;

      e = mpz_init_set_str(this.mpz,
                           str.localize().c_str(),
                           base.safeCast(c_int));

      if e {
        mpz_clear(this.mpz);

        error = EFORMAT;
      }
    }

    proc BigInt(num: BigInt) {
      compilerWarning("The class GMP.BigInt has been deprecated.  Please use the record BigInteger.bigint instead");

      if num.locale == here {
        mpz_init_set(this.mpz, num.mpz);
      } else {
        mpz_init(this.mpz);

        var mpz_struct = num.mpzStruct();

        chpl_gmp_get_mpz(this.mpz, num.locale.id, mpz_struct);
      }
    }

    proc BigInt() {
      compilerWarning("The class GMP.BigInt has been deprecated.  Please use the record BigInteger.bigint instead");

      mpz_init(this.mpz);
    }

    // destructor
    proc ~BigInt() {
      on this do mpz_clear(this.mpz);
    }

    // utility functions used below.
    proc numLimbs: uint(64) {
      var mpz_struct = this.mpz[1];

      return chpl_gmp_mpz_nlimbs(mpz_struct);
    }

    proc mpzStruct() : __mpz_struct {
      var ret: __mpz_struct;

      on this {
        ret = this.mpz[1];
      }

      return ret;
    }


    // returns true if we made a temp copy.
    proc maybeCopy() : (bool, BigInt) {
      if this.locale == here {
        return (false, this);
      } else {
        var mpz_struct = this.mpz[1];
        var tmp        = new BigInt(true,
                                    (mp_bits_per_limb: uint(64)) *
                                    chpl_gmp_mpz_nlimbs(mpz_struct));

        chpl_gmp_get_mpz(tmp.mpz, this.locale.id, mpz_struct);

        return (true, tmp);
      }
    }

    // Assignment functions
    proc set(a: BigInt) {
      on this {
        if a.locale == here {
          mpz_set(this.mpz, a.mpz);
        } else {
          var mpz_struct = a.mpzStruct();

          chpl_gmp_get_mpz(this.mpz, a.locale.id, mpz_struct);
        }
      }
    }

    proc set_ui(num: uint) {
      on this do
        mpz_set_ui(this.mpz, num.safeCast(c_ulong));
    }

    proc set_si(num: int) {
      on this do
        mpz_set_si(this.mpz, num.safeCast(c_long));
    }

    proc set(num: int) {
      set_si(num.safeCast(c_long));
    }

    proc set_d(num: real) {
      on this do
        mpz_set_d(this.mpz, num: c_double);
    }

    proc set_str(str: string, base: int = 0) {
      on this do
        mpz_set_str(this.mpz, str.localize().c_str(), base.safeCast(c_int));
    }

    proc swap(a: BigInt) {
      on this {
        if a.locale == here {
          mpz_swap(this.mpz, a.mpz);
        } else {
          // we have to introduce a temporary..
          var tmp = new BigInt(a);

          // set a to what this
          a.set(this);

          // now tmp is local.
          // set this to a (in tmp)
          mpz_set(this.mpz, tmp.mpz);
        }
      }
    }

    proc get_ui() : uint {
      var x: c_ulong;

      on this do x = mpz_get_ui(this.mpz);

      return x.safeCast(uint);
    }

    proc get_si() : int {
      var x: c_long;

      on this do x = mpz_get_si(this.mpz);

      return x.safeCast(int);
    }

    proc get_d() : real {
      var x: c_double;

      on this do x = mpz_get_d(this.mpz);

      return x: real;
    }


    // returns (exponent, double)
    proc get_d_2exp() : (int, real) {
      var exp: c_long;
      var dbl: c_double;

      on this {
        var tmp: c_long;

        dbl = mpz_get_d_2exp(tmp, this.mpz);
        exp = tmp;
      }

      return (exp.safeCast(int), dbl: real);
    }

    proc get_str(base: int=10) : string {
      var ret: string;

      on this {
        var tmp = chpl_gmp_mpz_get_str(base.safeCast(c_int), this.mpz);

        ret = tmp: string;
      }

      return ret;
    }


    // Arithmetic functions
    proc add(a: BigInt, b: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();

        mpz_add(this.mpz, a_.mpz, b_.mpz);

        if acopy then delete a_;
        if bcopy then delete b_;
      }
    }

    proc add_ui(a: BigInt, b: uint) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_add_ui(this.mpz, a_.mpz, b.safeCast(c_ulong));

        if acopy then delete a_;
      }
    }

    proc sub(a: BigInt, b: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();

        mpz_sub(this.mpz, a_.mpz, b_.mpz);

        if acopy then delete a_;
        if bcopy then delete b_;
      }
    }

    proc sub_ui(a: BigInt, b: uint) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_sub_ui(this.mpz, a_.mpz, b.safeCast(c_ulong));

        if acopy then delete a_;
      }
    }

    proc ui_sub(a: uint, b: BigInt) {
      on this {
        var (bcopy, b_) = b.maybeCopy();

        mpz_ui_sub(this.mpz, a.safeCast(c_ulong), b_.mpz);

        if bcopy then delete b_;
      }
    }

    proc mul(a: BigInt, b: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();

        mpz_mul(this.mpz, a_.mpz, b_.mpz);

        if acopy then delete a_;
        if bcopy then delete b_;
      }
    }

    proc mul_si(a: BigInt, b: int) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_mul_si(this.mpz, a_.mpz, b.safeCast(c_long));

        if acopy then delete a_;
      }
    }

    proc mul_ui(a: BigInt, b: uint) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_mul_ui(this.mpz, a_.mpz, b.safeCast(c_ulong));

        if acopy then delete a_;
      }
    }

    proc addmul(a: BigInt, b: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();

        mpz_addmul(this.mpz, a_.mpz, b_.mpz);

        if acopy then delete a_;
        if bcopy then delete b_;
      }
    }

    proc addmul_ui(a: BigInt, b: uint) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_addmul_ui(this.mpz, a_.mpz, b.safeCast(c_ulong));

        if acopy then delete a_;
      }
    }

    proc submul(a: BigInt, b: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();

        mpz_submul(this.mpz, a_.mpz, b_.mpz);

        if acopy then delete a_;
        if bcopy then delete b_;
      }
    }

    proc submul_ui(a: BigInt, b: uint) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_submul_ui(this.mpz, a_.mpz, b.safeCast(c_ulong));

        if acopy then delete a_;
      }
    }

    proc mul_2exp(a: BigInt, b: uint) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_mul_2exp(this.mpz, a_.mpz, b.safeCast(c_ulong));

        if acopy then delete a_;
      }
    }

    proc neg(a: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_neg(this.mpz, a_.mpz);

        if acopy then delete a_;
      }
    }

    proc abs(a: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_abs(this.mpz, a_.mpz);

        if acopy then delete a_;
      }
    }

    // Division Functions
    // These functions take in a constant rounding mode.
    proc div_q(param rounding: Round, n: BigInt, d: BigInt) {
      on this {
        var (ncopy, n_) = n.maybeCopy();
        var (dcopy, d_) = d.maybeCopy();

        select rounding {
          when Round.UP   do mpz_cdiv_q(this.mpz, n_.mpz, d_.mpz);
          when Round.DOWN do mpz_fdiv_q(this.mpz, n_.mpz, d_.mpz);
          when Round.ZERO do mpz_tdiv_q(this.mpz, n_.mpz, d_.mpz);
        }

        if ncopy then delete n_;
        if dcopy then delete d_;
      }
    }

    proc div_r(param rounding: Round, n: BigInt, d: BigInt) {
      on this {
        var (ncopy, n_) = n.maybeCopy();
        var (dcopy, d_) = d.maybeCopy();

        select rounding {
          when Round.UP   do mpz_cdiv_r(this.mpz, n_.mpz, d_.mpz);
          when Round.DOWN do mpz_fdiv_r(this.mpz, n_.mpz, d_.mpz);
          when Round.ZERO do mpz_tdiv_r(this.mpz, n_.mpz, d_.mpz);
        }

        if ncopy then delete n_;
        if dcopy then delete d_;
      }
    }


    // this gets quotient, r gets remainder
    proc div_qr(param rounding: Round, r: BigInt, n: BigInt, d: BigInt) {
      on this {
        var (rcopy, r_) = r.maybeCopy();
        var (ncopy, n_) = n.maybeCopy();
        var (dcopy, d_) = d.maybeCopy();

        select rounding {
          when Round.UP   do mpz_cdiv_qr(this.mpz, r_.mpz, n_.mpz, d_.mpz);
          when Round.DOWN do mpz_fdiv_qr(this.mpz, r_.mpz, n_.mpz, d_.mpz);
          when Round.ZERO do mpz_tdiv_qr(this.mpz, r_.mpz, n_.mpz, d_.mpz);
        }

        if rcopy {
          r.set(r_);
          delete r_;
        }

        if ncopy then delete n_;
        if dcopy then delete d_;
      }
    }

    proc div_q_ui(param rounding: Round, n: BigInt, d: uint) : uint {
      var ret: c_ulong;

      on this {
        var   (ncopy, n_) = n.maybeCopy();
        const cd          = d.safeCast(c_ulong);

        select rounding {
          when Round.UP   do ret = mpz_cdiv_q_ui(this.mpz, n_.mpz, cd);
          when Round.DOWN do ret = mpz_fdiv_q_ui(this.mpz, n_.mpz, cd);
          when Round.ZERO do ret = mpz_tdiv_q_ui(this.mpz, n_.mpz, cd);
        }

        if ncopy then delete n_;
      }

      return ret.safeCast(uint);
    }

    proc div_r_ui(param rounding: Round, n: BigInt, d: uint) : uint {
      var ret: c_ulong;

      on this {
        var   (ncopy, n_) = n.maybeCopy();
        const cd          = d.safeCast(c_ulong);

        select rounding {
          when Round.UP   do ret = mpz_cdiv_r_ui(this.mpz, n_.mpz, cd);
          when Round.DOWN do ret = mpz_fdiv_r_ui(this.mpz, n_.mpz, cd);
          when Round.ZERO do ret = mpz_tdiv_r_ui(this.mpz, n_.mpz, cd);
        }

        if ncopy then delete n_;
      }

      return ret.safeCast(uint);
    }

    // this gets quotient, r gets remainder
    proc div_qr_ui(param rounding: Round,
                   r: BigInt,
                   n: BigInt,
                   d: uint) : uint {
      var   ret: c_ulong;
      const cd = d.safeCast(c_ulong);

      on this {
        var (rcopy, r_) = r.maybeCopy();
        var (ncopy, n_) = n.maybeCopy();

        select rounding {
          when Round.UP   do
            ret = mpz_cdiv_qr_ui(this.mpz, r_.mpz, n_.mpz, cd);

          when Round.DOWN do
            ret = mpz_fdiv_qr_ui(this.mpz, r_.mpz, n_.mpz, cd);

          when Round.ZERO do
            ret = mpz_tdiv_qr_ui(this.mpz, r_.mpz, n_.mpz, cd);
        }

        if rcopy {
          r.set(r_);
          delete r_;
        }

        if ncopy then delete n_;
      }

      return ret.safeCast(uint);
    }

    proc div_ui(param rounding: Round, n: BigInt, d: uint) : uint {
      var   ret: c_ulong;
      const cd = d.safeCast(c_ulong);

      on this {
        var (ncopy, n_) = n.maybeCopy();

        select rounding {
          when Round.UP   do ret = mpz_cdiv_ui(this.mpz, n_.mpz, cd);
          when Round.DOWN do ret = mpz_fdiv_ui(this.mpz, n_.mpz, cd);
          when Round.ZERO do ret = mpz_tdiv_ui(this.mpz, n_.mpz, cd);
        }

        if ncopy then delete n_;
      }

      return ret.safeCast(uint);
    }

    proc div_q_2exp(param rounding: Round, n: BigInt, b: uint) {
      on this {
        var   (ncopy, n_) = n.maybeCopy();
        const cb          = b.safeCast(c_ulong);

        select rounding {
          when Round.UP   do mpz_cdiv_q_2exp(this.mpz, n_.mpz, cb);
          when Round.DOWN do mpz_fdiv_q_2exp(this.mpz, n_.mpz, cb);
          when Round.ZERO do mpz_tdiv_q_2exp(this.mpz, n_.mpz, cb);
        }

        if ncopy then delete n_;
      }
    }

    proc div_r_2exp(param rounding: Round, n: BigInt, b: uint) {
      on this {
        var   (ncopy, n_) = n.maybeCopy();
        const cb          = b.safeCast(c_ulong);

        select rounding {
          when Round.UP   do mpz_cdiv_r_2exp(this.mpz, n_.mpz, cb);
          when Round.DOWN do mpz_fdiv_r_2exp(this.mpz, n_.mpz, cb);
          when Round.ZERO do mpz_tdiv_r_2exp(this.mpz, n_.mpz, cb);
        }

        if ncopy then delete n_;
      }
    }

    proc mod(n: BigInt, d: BigInt) {
      on this {
        var (ncopy, n_) = n.maybeCopy();
        var (dcopy, d_) = d.maybeCopy();

        mpz_mod(this.mpz, n_.mpz, d_.mpz);

        if ncopy then delete n_;
        if dcopy then delete d_;
      }
    }

    proc mod_ui(n: BigInt, d: uint) : uint {
      var ret: c_ulong;

      on this {
        var (ncopy, n_) = n.maybeCopy();

        ret = mpz_mod_ui(this.mpz, n_.mpz, d.safeCast(c_ulong));

        if ncopy then delete n_;
      }

      return ret.safeCast(uint);
    }

    proc divexact(n: BigInt, d: BigInt) {
      on this {
        var (ncopy, n_) = n.maybeCopy();
        var (dcopy, d_) = d.maybeCopy();

        mpz_divexact(this.mpz, n_.mpz, d_.mpz);

        if ncopy then delete n_;
        if dcopy then delete d_;
      }
    }

    proc divexact_ui(n: BigInt, d: uint) {
      on this {
        var (ncopy, n_) = n.maybeCopy();

        mpz_divexact(this.mpz, n_.mpz, d.safeCast(c_ulong));

        if ncopy then delete n_;
      }
    }

    proc divisible_p(d: BigInt) : int {
      var ret: c_int;

      on this {
        var (dcopy, d_) = d.maybeCopy();

        ret = mpz_divisible_p(this.mpz, d_.mpz);

        if dcopy then delete d_;
      }

     return ret.safeCast(int);
    }

    proc divisible_ui_p(d: uint) : int {
      var ret: c_int;

      on this {
        ret = mpz_divisible_ui_p(this.mpz, d.safeCast(c_ulong));
      }

      return ret.safeCast(int);
    }

    proc divisible_2exp_p(b: uint) : int {
      var ret: c_int;

      on this {
        mpz_divisible_2exp_p(this.mpz, b.safeCast(c_ulong));
      }

      return ret.safeCast(int);
    }

    proc congruent_p(c: BigInt, d: BigInt) : int {
      var ret: c_int;

      on this {
        var (ccopy, c_) = c.maybeCopy();
        var (dcopy, d_) = d.maybeCopy();

        ret = mpz_congruent_p(this.mpz, c_.mpz, d_.mpz);

        if ccopy then delete c_;
        if dcopy then delete d_;
      }

      return ret.safeCast(int);
    }

    proc congruent_ui_p(c: uint, d: uint) : int {
      var ret: c_int;

      on this {
        ret = mpz_congruent_ui_p(this.mpz,
                                 c.safeCast(c_ulong),
                                 d.safeCast(c_ulong));
      }

      return ret.safeCast(int);
    }

    proc congruent_2exp_p(c: BigInt, b: uint) : int {
      var ret: c_int;

      on this {
        var (ccopy, c_) = c.maybeCopy();

        ret = mpz_congruent_2exp_p(this.mpz, c_.mpz, b.safeCast(c_ulong));

        if ccopy then delete c_;
      }

      return ret.safeCast(int);
    }

    // Exponentiation Functions
    proc powm(base: BigInt, exp: BigInt, mod: BigInt) {
      on this {
        var (bcopy, b_) = base.maybeCopy();
        var (ecopy, e_) = exp.maybeCopy();
        var (mcopy, m_) = mod.maybeCopy();

        mpz_powm(this.mpz, b_.mpz, e_.mpz, m_.mpz);

        if bcopy then delete b_;
        if ecopy then delete e_;
        if mcopy then delete m_;
      }
    }

    proc powm_ui(base: BigInt, exp: uint, mod: BigInt) {
      on this {
        var (bcopy, b_) = base.maybeCopy();
        var (mcopy, m_) = mod.maybeCopy();

        mpz_powm_ui(this.mpz, b_.mpz, exp.safeCast(c_ulong), m_.mpz);

        if bcopy then delete b_;
        if mcopy then delete m_;
      }
    }

    proc pow_ui(base: BigInt, exp: uint) {
      on this {
        var (bcopy, b_) = base.maybeCopy();

        mpz_pow_ui(this.mpz, b_.mpz, exp.safeCast(c_ulong));

        if bcopy then delete b_;
      }
    }

    proc ui_pow_ui(base: uint, exp: uint) {
      on this {
        mpz_ui_pow_ui(this.mpz, base.safeCast(c_ulong), exp.safeCast(c_ulong));
      }
    }

    // Root Extraction Functions
    proc root(a: BigInt, n: uint) : int {
      var ret: c_int;

      on this {
        var (acopy, a_) = a.maybeCopy();

        ret = mpz_root(this.mpz, a_.mpz, n.safeCast(c_ulong));

        if acopy then delete a_;
      }

      return ret.safeCast(int);
    }

    // this gets root, rem gets remainder.
    proc mpz_rootrem(rem: BigInt, u: BigInt, n: uint) {
      on this {
        var (rcopy, r_) = rem.maybeCopy();
        var (ucopy, u_) = u.maybeCopy();

        mpz_rootrem(this.mpz, r_.mpz, u_.mpz, n.safeCast(c_ulong));

        if rcopy {
          rem.set(r_);
          delete r_;
        }

        if ucopy then delete u_;
      }
    }

    proc sqrt(a: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_sqrt(this.mpz, a_.mpz);

        if acopy then delete a_;
      }
    }

    // this gets root, rem gets remainder of a-root*root.
    proc sqrtrem(rem: BigInt, a: BigInt) {
      on this {
        var (rcopy, r_) = rem.maybeCopy();
        var (acopy, a_) = a.maybeCopy();

        mpz_sqrtrem(this.mpz, r_.mpz, a_.mpz);

        if rcopy {
          rem.set(r_);
          delete r_;
        }

        if acopy then delete a_;
      }
    }

    proc perfect_power_p() : int {
      var ret: c_int;

      on this {
        ret = mpz_perfect_power_p(this.mpz);
      }

      return ret.safeCast(int);
    }

    proc perfect_square() : int {
      var ret: c_int;

      on this {
        ret = mpz_perfect_square(this.mpz);
      }

      return ret.safeCast(int);
    }

    // Number Theoretic Functions
    proc probab_prime_p(reps: int) : int {
      var ret: c_int;

      on this {
        ret = mpz_probab_prime_p(this.mpz, reps.safeCast(c_int));
      }

      return ret.safeCast(int);
    }

    proc nextprime(a: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_nextprime(this.mpz, a_.mpz);

        if acopy then delete a_;
      }
    }

    proc gcd(a: BigInt, b: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();

        mpz_gcd(this.mpz, a_.mpz, b_.mpz);

        if acopy then delete a_;
        if bcopy then delete b_;
      }
    }

    proc gcd_ui(a: BigInt, b: uint) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_gcd_ui(this.mpz, a_.mpz, b.safeCast(c_ulong));

        if acopy then delete a_;
      }
    }

    // sets this to gcd(a,b)
    // set s and t to to coefficients satisfying a*s + b*t == g
    proc gcdext(s: BigInt, t: BigInt, a: BigInt, b: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();
        var (scopy, s_) = s.maybeCopy();
        var (tcopy, t_) = t.maybeCopy();

        mpz_gcdext(this.mpz, s_.mpz, t_.mpz, a_.mpz, b_.mpz);

        if acopy then delete a_;
        if bcopy then delete b_;

        if scopy {
          s.set(s_);
          delete s_;
        }

        if tcopy {
          t.set(t_);
          delete t_;
        }
      }
    }

    proc lcm(a: BigInt, b: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();

        mpz_lcm(this.mpz, a_.mpz, b_.mpz);

        if acopy then delete a_;
        if bcopy then delete b_;
      }
    }

    proc lcm_ui(a: BigInt, b: uint) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_lcm_ui(this.mpz, a_.mpz, b.safeCast(c_ulong));

        if acopy then delete a_;
      }
    }

    proc invert(a: BigInt, b: BigInt) : int {
      var ret: c_int;

      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();

        ret = mpz_invert(this.mpz, a_.mpz, b_.mpz);

        if acopy then delete a_;
        if bcopy then delete b_;
      }

      return ret.safeCast(int);
    }

    // jacobi, legendre, kronecker are procedures outside this class.


    proc remove(a: BigInt, f: BigInt) : uint {
      var ret: c_ulong;

      on this {
        var (acopy, a_) = a.maybeCopy();
        var (fcopy, f_) = f.maybeCopy();

        ret = mpz_remove(this.mpz, a_.mpz, f_.mpz);

        if acopy then delete a_;
        if fcopy then delete f_;
      }

      return ret.safeCast(uint);
    }

    proc fac_ui(a: uint) {
      on this {
        mpz_fac_ui(this.mpz, a.safeCast(c_ulong));
      }
    }

    proc bin_ui(n: BigInt, k: uint) {
      on this {
        var (ncopy, n_) = n.maybeCopy();

        mpz_bin_ui(this.mpz, n_.mpz, k.safeCast(c_ulong));

        if ncopy then delete n_;
      }
    }

    proc bin_uiui(n: uint, k: uint) {
      on this {
        mpz_bin_uiui(this.mpz, n.safeCast(c_ulong), k.safeCast(c_ulong));
      }
    }

    proc fib_ui(n: uint) {
      on this {
        mpz_fib_ui(this.mpz, n.safeCast(c_ulong));
      }
    }

    proc fib2_ui(fnsub1: BigInt, n: uint) {
      on this {
        var (fcopy, f_) = fnsub1.maybeCopy();

        mpz_fib2_ui(this.mpz, f_.mpz, n.safeCast(c_ulong));

        if fcopy {
          fnsub1.set(f_);
          delete f_;
        }
      }
    }

    proc lucnum_ui(n: uint) {
      on this {
        mpz_lucnum_ui(this.mpz, n.safeCast(c_ulong));
      }
    }

    proc lucnum2_ui(lnsub1: BigInt, n: uint) {
      on this {
        var (fcopy, f_) = lnsub1.maybeCopy();

        mpz_lucnum2_ui(this.mpz, f_.mpz, n.safeCast(c_ulong));

        if fcopy {
          lnsub1.set(f_);
          delete f_;
        }
      }
    }

    // Comparison Functions
    proc cmp(b: BigInt) : int {
      var ret: c_int;

      on this {
        var (bcopy, b_) = b.maybeCopy();

        ret = mpz_cmp(this.mpz,b_.mpz);

        if bcopy then delete b_;
      }

      return ret.safeCast(int);
    }

    proc cmp_d(b: real) : int {
      var ret: c_int;

      on this {
        ret = mpz_cmp_d(this.mpz, b: c_double);
      }

      return ret.safeCast(int);
    }

    proc cmp_si(b: int) : int {
      var ret: c_int;

      on this {
        ret = mpz_cmp_si(this.mpz, b.safeCast(c_long));
      }

      return ret.safeCast(int);
    }

    proc cmp_ui(b: uint) : int {
      var ret: c_int;

      on this {
        ret = mpz_cmp_ui(this.mpz, b.safeCast(c_ulong));
      }

      return ret.safeCast(int);
    }

    proc cmpabs(b: BigInt) : int {
      var ret: c_int;

      on this {
        var (acopy, b_) = b.maybeCopy();

        ret = mpz_cmpabs(this.mpz,b_.mpz);

        if acopy then delete b_;
      }

      return ret.safeCast(int);
    }

    proc cmpabs_d(b: real) : int {
      var ret: c_int;

      on this {
        ret = mpz_cmpabs_d(this.mpz, b: c_double);
      }

      return ret.safeCast(int);
    }

    proc cmp_abs_ui(b: uint) : int {
      var ret: c_int;

      on this {
        ret = mpz_cmpabs_ui(this.mpz, b.safeCast(c_ulong));
      }

      return ret.safeCast(int);
    }

    proc sgn() : int {
      var ret: c_int;

      on this {
        ret = mpz_sgn(this.mpz);
      }

      return ret.safeCast(int);
    }

    // Logical and Bit Manipulation Functions
    proc and(a: BigInt, b: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();

        mpz_and(this.mpz, a_.mpz, b_.mpz);

        if acopy then delete a_;
        if bcopy then delete b_;
      }
    }

    proc ior(a: BigInt, b: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();

        mpz_ior(this.mpz, a_.mpz, b_.mpz);


        if acopy then delete a_;
        if bcopy then delete b_;
      }
    }

    proc xor(a: BigInt, b: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();
        var (bcopy, b_) = b.maybeCopy();

        mpz_xor(this.mpz, a_.mpz, b_.mpz);

        if acopy then delete a_;
        if bcopy then delete b_;
      }
    }

    proc com(a: BigInt) {
      on this {
        var (acopy, a_) = a.maybeCopy();

        mpz_com(this.mpz, a_.mpz);

        if acopy then delete a_;
      }
    }

    proc popcount() : uint {
      var ret: c_ulong;

      on this {
        ret = mpz_popcount(this.mpz);
      }

      return ret.safeCast(uint);
    }

    proc hamdist(b: BigInt) : uint {
      var ret: c_ulong;

      on this {
        var (bcopy, b_) = b.maybeCopy();

        ret = mpz_hamdist(this.mpz, b_.mpz);

        if bcopy then delete b_;
      }

      return ret.safeCast(uint);
    }

    proc scan0(starting_bit: uint) : uint {
      var ret: c_ulong;

      on this {
        ret = mpz_scan0(this.mpz, starting_bit.safeCast(c_ulong));
      }

      return ret.safeCast(uint);
    }

    proc scan1(starting_bit: uint) : uint {
      var ret: c_ulong;

      on this {
        ret = mpz_scan1(this.mpz, starting_bit.safeCast(c_ulong));
      }

      return ret.safeCast(uint);
    }

    proc setbit(bit_index: uint) {
      on this {
        mpz_setbit(this.mpz, bit_index.safeCast(c_ulong));
      }
    }

    proc clrbit(bit_index: uint) {
      on this {
        mpz_clrbit(this.mpz, bit_index.safeCast(c_ulong));
      }
    }

    proc combit(bit_index: uint) {
      on this {
        mpz_combit(this.mpz, bit_index.safeCast(c_ulong));
      }
    }

    proc tstbit(bit_index: uint) : int {
      var ret: c_int;

      on this {
        ret = mpz_tstbit(this.mpz, bit_index.safeCast(c_ulong));
      }

      return ret.safeCast(int);
    }

    // Miscellaneous Functions
    proc fits_ulong_p() : int {
      var ret: c_int;

      on this {
        ret = mpz_fits_ulong_p(this.mpz);
      }

      return ret.safeCast(int);
    }

    proc fits_slong_p() : int {
      var ret: c_int;

      on this {
        ret = mpz_fits_ulong_p(this.mpz);
      }

      return ret.safeCast(int);
    }

    proc fits_uint_p() : int {
      var ret: c_int;

      on this {
        ret = mpz_fits_uint_p(this.mpz);
      }

      return ret.safeCast(int);
    }

    proc fits_sint_p() : int {
      var ret: c_int;

      on this {
        ret = mpz_fits_sint_p(this.mpz);
      }

      return ret.safeCast(int);
    }

    proc fits_ushort_p() : int {
      var ret: c_int;

      on this {
        ret = mpz_fits_ushort_p(this.mpz);
      }

      return ret.safeCast(int);
    }

    proc fits_sshort_p() : int {
      var ret: c_int;

      on this {
        ret = mpz_fits_sshort_p(this.mpz);
      }

      return ret.safeCast(int);
    }

    proc odd_p() : int {
      var ret: c_int;

      on this {
        ret = mpz_odd_p(this.mpz);
      }

      return ret.safeCast(int);
    }

    proc even_p() : int {
      var ret: c_int;

      on this {
        ret = mpz_even_p(this.mpz);
      }

      return ret.safeCast(int);
    }

    proc sizeinbase(base: int) : uint {
      var ret: size_t;

      on this {
        ret = mpz_sizeinbase(this.mpz, base.safeCast(c_int));
      }

      return ret.safeCast(uint);
    }

    // left out integer random functions
    // these are in the GMPRandom class.
    proc realloc2(nbits: uint) {
      on this {
        mpz_realloc2(this.mpz, nbits.safeCast(c_ulong));
      }
    }

    proc get_limbn(n: uint) : uint {
      var ret: mp_limb_t;

      on this {
        ret = mpz_getlimbn(this.mpz, n.safeCast(mp_size_t));
      }

      return ret.safeCast(uint);
    }

    proc size() : size_t {
      var ret: size_t;

      on this {
        ret = mpz_size(this.mpz);
      }

      return ret;
    }

    proc debugprint() {
      writeln("On locale ",this.locale);

      on this {
        chpl_gmp_mpz_print(this.mpz);
      }
    }
  }

  proc BigInt.writeThis(writer) {
    var (acopy, a_) = this.maybeCopy();
    var s: string  = a_.get_str();

    writer.write(s);

    if acopy then delete a_;
  }

  proc jacobi(a: BigInt, b: BigInt) : int {
    var ret: c_int;

    on a {
      var (bcopy, b_) = b.maybeCopy();

      ret = mpz_jacobi(a.mpz, b_.mpz);

      if bcopy then delete b_;
    }

    return ret.safeCast(int);
  }

  proc legendre(a: BigInt, p: BigInt) : int {
    var ret: c_int;

    on a {
      var (pcopy, p_) = p.maybeCopy();

      ret = mpz_legendre(a.mpz, p_.mpz);

      if pcopy then delete p_;
    }

    return ret.safeCast(int);
  }

  proc kronecker(a: BigInt, b: BigInt) : int {
    var ret: c_int;

    on a {
      var (bcopy, b_) = b.maybeCopy();

      ret = mpz_kronecker(a.mpz, b_.mpz);

      if bcopy then delete b_;
    }

    return ret.safeCast(int);
  }

  proc kronecker_si(a: BigInt, b: int) : int {
    var ret: c_int;

    on a {
      ret = mpz_kronecker_si(a.mpz, b.safeCast(c_long));
    }

    return ret.safeCast(int);
  }

  proc kronecker_ui(a: BigInt, b: uint) : int {
    var ret: c_int;

    on a {
      ret = mpz_kronecker_ui(a.mpz, b.safeCast(c_ulong));
    }

    return ret.safeCast(int);
  }

  proc si_kronecker(a: int, b: BigInt) : int {
    var ret: c_int;

    on b {
      ret = mpz_si_kronecker(b.mpz.safeCast(c_long, a));
    }

    return ret.safeCast(int);
  }

  proc ui_kronecker(a: uint, b: BigInt) : int {
    var ret: c_int;

    on b {
      ret = mpz_ui_kronecker(b.mpz.safeCast(c_ulong, a));
    }

    return ret.safeCast(int);
  }

  class GMPRandom {
    var state: gmp_randstate_t;

    proc GMPRandom() {
      gmp_randinit_default(this.state);
    }

    // Creates a Mersenne Twister (probably same as init_default)
    proc GMPRandom(twister: bool) {
      gmp_randinit_mt(this.state);
    }

    proc GMPRandom(a: bigint, c: uint, m2exp: uint) {
      // Rely on bigint assignment operator to obtain a local copy
      var a_ = a;

      gmp_randinit_lc_2exp(this.state,
                           a_.mpz,
                           c.safeCast(c_ulong),
                           m2exp.safeCast(c_ulong));
    }

    proc GMPRandom(size: uint) {
      gmp_randinit_lc_2exp_size(this.state, size.safeCast(c_ulong));
    }

    proc GMPRandom(a: GMPRandom) {
      if a.locale == here {
        gmp_randinit_set(this.state, a.state);
      } else {
        chpl_gmp_get_randstate(this.state, a.locale.id, a.state[1]);
      }
    }

    proc ~GMPRandom() {
      on this {
        gmp_randclear(this.state);
      }
    }

    proc seed(seed: bigint) {
      on this {
        // Rely on bigint assignment operator to obtain a local copy
        var s_ = seed;

        gmp_randseed(this.state, s_.mpz);
      }
    }

    proc seed(seed: uint) {
      on this {
        gmp_randseed_ui(this.state, seed.safeCast(c_ulong));
      }
    }

    proc urandomb(nbits: uint) : uint {
      var ret: c_ulong;

      on this {
        ret = gmp_urandomb_ui(this.state, nbits.safeCast(c_ulong));
      }

      return ret.safeCast(uint);
    }

    proc urandomm(n: uint) : uint {
      var ret: c_ulong;

      on this {
        ret = gmp_urandomm_ui(this.state, n.safeCast(c_ulong));
      }

      return ret.safeCast(uint);
    }


    // TO DEPRECATE
    proc urandomb_ui(nbits: uint) : uint {
      var val: c_ulong;

      on this {
        val = gmp_urandomb_ui(this.state, nbits.safeCast(c_ulong));
      }

      return val.safeCast(uint);
    }

    // TO DEPRECATE
    proc urandomm_ui(n: uint) : uint {
      var val: c_ulong;

      on this {
        val = gmp_urandomm_ui(this.state, n.safeCast(c_ulong));
      }

      return val.safeCast(uint);
    }

    proc urandomb(ref r: bigint, nbits: uint) {
      on this {
        // Rely on bigint assignment operator to obtain a local copy
        var r_ = r;

        mpz_urandomb(r_.mpz, this.state, nbits.safeCast(c_ulong));

        r = r_;
      }
    }

    proc urandomm(ref r: bigint, n: bigint) {
      on this {
        // Rely on bigint assignment operator to obtain a local copy
        var r_ = r;
        var n_ = n;

        mpz_urandomm(r_.mpz, this.state, n_.mpz);

        r = r_;
      }
    }

    proc rrandomb(ref r: bigint, nbits: uint) {
      on this {
        // Rely on bigint assignment operator to obtain a local copy
        var r_ = r;

        mpz_rrandomb(r_.mpz, this.state, nbits.safeCast(c_ulong));

        r = r_;
      }
    }
  }

  /* FUTURE -- GMP numbers with record semantics,
      expression and operator overloads.
  */

  // calls mp_set_memory_functions to use chpl_malloc, etc.
  chpl_gmp_init();
}
