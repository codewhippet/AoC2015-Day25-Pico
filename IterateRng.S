#include "pico/asm_helper.S"
#include "hardware/regs/addressmap.h"
#include "hardware/regs/sio.h"

pico_default_asm_setup

// ----------------------------------------------------------------------------

// Arguments:
//  r0 = int32_t seed
//  r1 = int32_t iterations
//  
// Returns:
//  int32_t
// Clobbers:
//  r0-3

regular_func IterateRngAsm
    push { r4, r5, r6, r7, lr }

    ldr r7, =(SIO_BASE)
    ldr r2, =33554393
    str r2, [r7, #SIO_DIV_UDIVISOR_OFFSET]
    ldr r3, =252533

    subs r1, r1, #1     // iterations -= 1;
    beq 9f              // if (iterations == 0) goto exit;

0:
    // for (uint32_t i = 1; i < iterations; i++)
    // {

    // b:a * d:c - split 32-bit integers into upper and lower 16-bit values
    // 
    // hi:lo - 64-bit result =
    // bd:00 +
    //  b:c0 +
    //  a:d0 +
    //   :ac

    uxth r6, r0         //  r6 := a
    lsrs r0, r0, #16    //  r0 := b
    uxth r2, r3         //  r2 := c
    lsrs r3, r3, #16    //  r3 := d

    movs r4, r0
    muls r4, r4, r3     //  r4 := bd
    muls r0, r0, r2     //  r0 := bc
    movs r5, r6
    muls r5, r5, r3     //  r5 := ad
    muls r6, r6, r2     //  r6 := ac

    // r4 := hi
    // r6 := lo

    lsls r2, r0, #16    //  r2:= c0
    lsrs r0, r0, #16    //	r0:= 0b
    adds r6, r6, r2     //  lo := ac + c0
    adcs r4, r4, r0     //  hi := bd + 0b + carry

    lsls r3, r5, #16    //  r3 := d0
    lsrs r5, r5, #16    //  r5 := 0a
    adds r6, r6, r3     //  lo := ac + c0 + d0

    // str doesn't affect the carry flags, so we can move this final add after triggering the divider
    //adcs r4, r4, r5     //  hi := bd + 0b + 0a + carry

    // answer === (2^32 * hi) + lo  (mod m)
    // 
    // 2^32 * hi === (2^32 % m) * hi  (mod m)
    // 2^32 * hi === 4992 * hi  (mod m)
    //
    // answer === (4992 * hi) + (lo % m)  (mod m)
    // 
    // answer will be at most one iteration of -= 33554393 above fully reduced answer

    // Trigger the divider hardware
    str r6, [r7, #SIO_DIV_UDIVIDEND_OFFSET] //  r0 := r6 % 33554393;    // r0 := lo_mod;

    // Need an 8 cycle wait before reading results
    adcs r4, r4, r5     //  hi := bd + 0b + 0a + carry
    ldr r5, =33554393
    ldr r2, =4992
    muls r2, r2, r4     //  r2 := hi_mod
    ldr r3, =252533

    // Now we're safe to read the results
    ldr r0, [r7, #SIO_DIV_REMAINDER_OFFSET] // r0 := lo % 33554393;
    ldr r6, [r7, #SIO_DIV_QUOTIENT_OFFSET]  // Dummy read the quotient register to clear the dirty flag

    adds r0, r0, r2     //  r0 := hi_mod + lo_mod

    cmp r0, r5
    blo 1f              //  if (hilo_mod >= 33554393)
    subs r0, r0, r5     //      hilo_mod -= 33554393;
1:

    subs r1, r1, #1     //  iterations -= 1;
    bne 0b              //  if (iterations != 0) goto loop;

    // }

9:
    pop { r4, r5, r6, r7, pc }
    .ltorg
