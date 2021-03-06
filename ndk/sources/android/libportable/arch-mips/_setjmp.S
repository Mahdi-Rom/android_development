/* Derived from: $OpenBSD: _setjmp.S,v 1.4 2005/08/07 16:40:15 espie Exp $ */

/*
 * Copyright (c) 2002 Opsycon AB  (www.opsycon.se / www.opsycon.com)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Opsycon AB nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

#include <machine/asm.h>
#include <machine/regnum.h>

#include "jboffsets.h"

/*
 * _setjmp, _longjmp (not restoring signal state)
 *
 * XXX FPSET should probably be taken from SR setting. hmmm...
 *  GPOFF and FRAMESIZE must be the same for both _setjmp and _longjmp!
 *
 */

FRAMESZ= MKFSIZ(0,4)
GPOFF= FRAMESZ-2*REGSZ

#define FPREG64_S(FPR, OFF, BASE)       \
        swc1    FPR, OFF(BASE)  ;       \
        mfhc1   t0, FPR         ;       \
        sw      t0, OFF+4(BASE) ;

#define FPREG64_L(FPR, OFF, BASE)       \
        lw      t0, OFF+4(BASE) ;       \
        lw      t1, OFF(BASE)   ;       \
        mtc1    t1, FPR         ;       \
        mthc1   t0, FPR         ;       \

LEAF(_setjmp_portable, FRAMESZ)
        PTR_SUBU sp, FRAMESZ
        SETUP_GP64(GPOFF, _setjmp)
        SAVE_GP(GPOFF)
        .set    noreorder
#if defined(__mips64)
        dli     v0, MAGIC__SETJMP
#else
        li      v0, MAGIC__SETJMP
#endif
        REG_S   v0, JB_MAGIC(a0)
        REG_S   s0, JB_S0(a0)
        REG_S   s1, JB_S1(a0)
        REG_S   s2, JB_S2(a0)
        REG_S   s3, JB_S3(a0)
        REG_S   s4, JB_S4(a0)
        REG_S   s5, JB_S5(a0)
        REG_S   s6, JB_S6(a0)
        REG_S   s7, JB_S7(a0)
        REG_S   s8, JB_S8(a0)
        REG_L   v0, GPOFF(sp)
        REG_S   v0, JB_GP(a0)
        PTR_ADDU v0, sp, FRAMESZ
        REG_S   v0, JB_SP(a0)
        REG_S   ra, JB_PC(a0)

#if !defined(SOFTFLOAT)
        /*
         * Would be nice if we could tell if the FP registers are currently being used;
         * Assume they are, and use pointer to jmp_buf in a0 to save FP registers and the
         * jmp_buf.fpused flag.
         */
        li      v0, 1                           # v0 = 1
        REG_S   v0, JB_FPUSED(a0)               # a0->jb_fpused = v0:1
        cfc1    v0, $31
#if _MIPS_FPSET == 32
        FPREG64_S($f20, JB_F20, a0)
        FPREG64_S($f21, JB_F21, a0)
        FPREG64_S($f22, JB_F22, a0)
        FPREG64_S($f23, JB_F23, a0)
        FPREG64_S($f24, JB_F24, a0)
        FPREG64_S($f25, JB_F25, a0)
        FPREG64_S($f26, JB_F26, a0)
        FPREG64_S($f27, JB_F27, a0)
        FPREG64_S($f28, JB_F28, a0)
        FPREG64_S($f29, JB_F29, a0)
        FPREG64_S($f30, JB_F30, a0)
        FPREG64_S($f31, JB_F31, a0)
#else
        swc1    $f20, JB_F20(a0)
        swc1    $f21, JB_F21(a0)
        swc1    $f22, JB_F22(a0)
        swc1    $f23, JB_F23(a0)
        swc1    $f24, JB_F24(a0)
        swc1    $f25, JB_F25(a0)
        swc1    $f26, JB_F26(a0)
        swc1    $f27, JB_F27(a0)
        swc1    $f28, JB_F28(a0)
        swc1    $f29, JB_F29(a0)
        swc1    $f30, JB_F30(a0)
        swc1    $f31, JB_F31(a0)
#endif
        REG_S   v0, JB_FSR(a0)
#endif /* !SOFTFLOAT */
        RESTORE_GP64
        PTR_ADDU sp, FRAMESZ
        j       ra
         move   v0, zero
END(_setjmp_portable)

LEAF(_longjmp_portable, FRAMESZ)
        PTR_SUBU sp, FRAMESZ
        SETUP_GP64(GPOFF, _longjmp)
        SAVE_GP(GPOFF)
        .set    noreorder
        REG_L   v0, JB_MAGIC(a0)
        bne     v0, MAGIC__SETJMP, botch                # jump if error
        REG_L   ra, JB_PC(a0)
        REG_L   v0, JB_FSR(a0)
        REG_L   s0, JB_S0(a0)
        REG_L   s1, JB_S1(a0)
        REG_L   s2, JB_S2(a0)
        REG_L   s3, JB_S3(a0)
        REG_L   s4, JB_S4(a0)
        REG_L   s5, JB_S5(a0)
        REG_L   s6, JB_S6(a0)
        REG_L   s7, JB_S7(a0)
        REG_L   s8, JB_S8(a0)
        REG_L   gp, JB_GP(a0)
        REG_L   sp, JB_SP(a0)
#if !defined(SOFTFLOAT)
        ctc1    v0, $31
#if _MIPS_FPSET == 32
        FPREG64_L($f20, JB_F20, a0)
        FPREG64_L($f21, JB_F21, a0)
        FPREG64_L($f22, JB_F22, a0)
        FPREG64_L($f23, JB_F23, a0)
        FPREG64_L($f24, JB_F24, a0)
        FPREG64_L($f25, JB_F25, a0)
        FPREG64_L($f26, JB_F26, a0)
        FPREG64_L($f27, JB_F27, a0)
        FPREG64_L($f28, JB_F28, a0)
        FPREG64_L($f29, JB_F29, a0)
        FPREG64_L($f30, JB_F30, a0)
        FPREG64_L($f31, JB_F31, a0)
#else
        lwc1    $f20, JB_F20(a0)
        lwc1    $f21, JB_F21(a0)
        lwc1    $f22, JB_F22(a0)
        lwc1    $f23, JB_F23(a0)
        lwc1    $f24, JB_F24(a0)
        lwc1    $f25, JB_F25(a0)
        lwc1    $f26, JB_F26(a0)
        lwc1    $f27, JB_F27(a0)
        lwc1    $f28, JB_F28(a0)
        lwc1    $f29, JB_F29(a0)
        lwc1    $f30, JB_F30(a0)
        lwc1    $f31, JB_F31(a0)
#endif
#endif /* !SOFTFLOAT */
        bne     a1, zero, 1f
         nop
        li      a1, 1                   # never return 0!
1:
        j       ra
         move   v0, a1

botch:
        jal     longjmperror
        nop
        jal     abort
        nop
        RESTORE_GP64
        PTR_ADDU sp, FRAMESZ
END(_longjmp_portable)
