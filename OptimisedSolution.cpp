#include "hardware/divider.h"
#include <string.h>
#include <stdint.h>
#include <stdio.h>

using namespace std;

extern const char* PuzzleInput;

extern "C" int32_t IterateRngAsm(int32_t seed, int32_t iterations);

static uint32_t GridIndexFromRowColumn(uint32_t row, uint32_t column)
{
	// Get the 'starting' position [r0,1] of the diagonal containing [row,column]
	uint32_t r0 = row + (column - 1);

	// The starting grid index for each row [r0,1] is TriangleNumber(r0-1) + 1
	uint32_t triangleNumber = ((r0 - 1) * (r0)) / 2;
	uint32_t startingGridIndex = triangleNumber + 1;

	// Then add back on the row count we took away
	uint32_t gridIndex = startingGridIndex + (r0 - row);
	return gridIndex;
}

static uint32_t IterateRngCpp(uint32_t seed, uint32_t iterations)
{
	sio_hw->div_udivisor = 33554393;

	uint32_t answer = seed;
	for (uint32_t i = 1; i < iterations; i++)
	{
		// b:a * d:c - split 32-bit integers into upper and lower 16-bit values
		// 
		// hi:lo - 64-bit result =
		// bd:00 +
		//  b:c0 +
		//  a:d0 +
		//   :ac

		uint32_t a = answer & 0xffff;
		uint32_t b = answer >> 16;
		uint32_t c = 252533 & 0xffff;
		uint32_t d = 252533 >> 16;

		uint32_t bd = b * d;
		uint32_t bc = b * c;
		uint32_t ad = a * d;
		uint32_t ac = a * c;

		unsigned int carry = 0;

		uint32_t hi = bd;
		uint32_t lo = ac;
		lo = __builtin_addc(lo, bc << 16, 0, &carry);		// lo := ac + c0
		hi = __builtin_addc(hi, bc >> 16, carry, &carry);	// hi := bd + 0b
		lo = __builtin_addc(lo, ad << 16, 0, &carry);		// lo := ac + c0 + d0
		hi = __builtin_addc(hi, ad >> 16, carry, &carry);	// hi := bd + 0b + 0a

		// answer === (2^32 * hi) + lo  (mod m)
		// 
		// 2^32 * hi === (2^32 % m) * hi  (mod m)
		// 2^32 * hi === 4992 * hi  (mod m)
		//
		// answer === (4992 * hi) + (lo % m)  (mod m)
		// 
		// answer will be at most one iteration of -= 33554393 above fully reduced answer

		sio_hw->div_udividend = lo;
		uint32_t hi_mod = 4992 * hi;
		uint32_t lo_mod = hw_divider_u32_remainder_wait();

		uint32_t hilo_mod = hi_mod + lo_mod;
		if (hilo_mod >= 33554393)
			hilo_mod -= 33554393;

		answer = hilo_mod;
	}

	return answer;
}

int32_t Optimised_Part1_Cpp()
{
	uint32_t row = 0;
	uint32_t column = 0;
	sscanf(PuzzleInput, "To continue, please consult the code grid in the manual.  Enter the code at row %u, column %u.",
		&row,
		&column);

	uint32_t rngIterations = GridIndexFromRowColumn(row, column);
	uint32_t answer = IterateRngCpp(20151125, rngIterations);

	return answer;
}

int32_t Optimised_Part1_Asm()
{
	uint32_t row = 0;
	uint32_t column = 0;
	sscanf(PuzzleInput, "To continue, please consult the code grid in the manual.  Enter the code at row %u, column %u.",
		&row,
		&column);

	uint32_t rngIterations = GridIndexFromRowColumn(row, column);
	uint32_t answer = IterateRngAsm(20151125, rngIterations);

	return answer;
}
