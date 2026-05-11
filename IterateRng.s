.syntax unified
.cpu cortex-m0plus
.thumb

.section .text
.align 2

// ----------------------------------------------------------------------------

.global IterateRngAsm
.type IterateRngAsm,%function
.thumb_func

// Arguments:
//  r0 = int32_t seed
//  r1 = int32_t iterations
//  
// Returns:
//  int32_t
// Clobbers:
//  r0-3

IterateRngAsm:
    push { r4, r5, r6, r7, lr }

    ldr r7, =0xd0000000 // SIO_BASE
    ldr r2, =33554393
    str r2, [r7, #0x64] // SIO_DIV_UDIVISOR_OFFSET

    subs r1, r1, #1     // r1 -= 1;
    beq exit            //    if (r1 == 0)
                        //		goto exit;
loop:
                        //	//for (uint32_t i = 1; i < r1; i++)
                        //	{

    // b:a * d:c - split 32-bit integers into upper and lower 16-bit values
    // 
    // hi:lo - 64-bit result =
    // bd:00 +
    //  b:c0 +
    //  a:d0 +
    //   :ac

    ldr r3, =252533     //		r3 = 252533;

    uxth r6, r0         //		r6 = r0 & 0xffff;	// r6 := a
    lsrs r0, r0, #16    //		r0 = r0 >> 16;		// r0 := b
    uxth r2, r3         //		r2 = r3 & 0xffff;	// r2 := c
    lsrs r3, r3, #16    //		r3 = r3 >> 16;		// r3 := d

    movs r4, r0         //		r4 = r0;
    muls r4, r4, r3     //		r4 *= r3;			// r4 := bd
    muls r0, r0, r2     //		r0 *= r2;			// r0 := bc
    movs r5, r6         //		r5 = r6;
    muls r5, r5, r3     //		r5 *= r3;			// r5 := ad
    muls r6, r6, r2     //		r6 *= r2;			// r6 := ac

    // r4 := hi
    // r6 := lo

    lsls r2, r0, #16    //		r2 = r0 << 16;
    lsrs r0, r0, #16    //		r0 = r0 >> 16;
    adds r6, r6, r2     //		carry = _addcarry_u32(0, r6, r2, &r6);	// lo := ac + c0
    adcs r4, r4, r0     //		_addcarry_u32(carry, r4, r0, &r4);		// hi := bd + 0b
                        //
    lsls r3, r5, #16    //		r3 = r5 << 16;
    lsrs r5, r5, #16    //		r5 = r5 >> 16;
    adds r6, r6, r3     //		carry = _addcarry_u32(0, r6, r3, &r6);	// lo := ac + c0 + d0

    // str doesn't affect the carry flags, so we can move this final add after triggering the divider
    //adcs r4, r4, r5     //		_addcarry_u32(carry, r4, r5, &r4);		// hi := bd + 0b + 0a

    // answer === (2^32 * hi) + lo  (mod m)
    // 
    // 2^32 * hi === (2^32 % m) * hi  (mod m)
    // 2^32 * hi === 4992 * hi  (mod m)
    //
    // answer === (4992 * hi) + (lo % m)  (mod m)
    // 
    // answer will be at most one iteration of -= 33554393 above fully reduced answer

    // Trigger the divider hardware
    str r6, [r7, #0x60]   //		r0 = r6 % r3;	// r0 := lo_mod; // SIO_DIV_UDIVIDEND_OFFSET

    // Need an 8 cycle wait before reading results
    adcs r4, r4, r5     //		_addcarry_u32(carry, r4, r5, &r4);		// hi := bd + 0b + 0a
    ldr r3, =33554393   //		r3 = 33554393;
    ldr r2, = 4992      //		r2 = 4992;
    muls r2, r2, r4     //		r2 *= r4;		// r2 := hi_mod
    nop
    nop

    // Now we're safe to read the results
    ldr r0, [r7, #0x74]  // SIO_DIV_REMAINDER_OFFSET: Remainder
    ldr r6, [r7, #0x70]  // SIO_DIV_QUOTIENT_OFFSET: Dummy read the quotient register to clear the dirty flag

    adds r0, r0, r2     //		r0 += r2;		// r0 := hilo_mod

    cmp r0, r3
    blo skipDecrement   //		if (r0 >= r3)
    subs r0, r0, r3     //			r0 -= r3;
skipDecrement:

    subs r1, r1, #1     //	r1 -= 1;
    bne loop            //	if (r1 != 0) goto loop;

exit:
    pop { r4, r5, r6, r7, pc }

    .ltorg
