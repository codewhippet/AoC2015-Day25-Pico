# AoC2015-Day25-Pico

The RNG for [2015 Day 25](https://adventofcode.com/2015/day/25) requires 64-bit maths to get the correct answer. On the [Raspberry Pi Pico](https://www.raspberrypi.com/documentation/microcontrollers/pico-series.html#pico1) this has to be implemented in software and the standard library implementations have a lot of overhead when we're trying to do 17M+ multiplies and modulos. We can do better if we manually split the calculation into 32-bit maths and address the divider hardware directly.

## Results

Timings will be input dependent, these are the timings for my input:

| Solution | Time |
|--|--|
| Unoptimised C++ | 27.004s |
| Optimised C++ | 8.489s |
| Optimised Asm | 4.998s |

## Main optimisations

The 64-bit multiplication is reduced to 32-bit using the [Grid Method](https://en.wikipedia.org/wiki/Grid_method_multiplication#Computing).

The 64-bit modulo is reduce to 32-bit using the following identity:

[hi:lo] % 33,554,393 ≡ (2<sup>32</sup> * hi + lo) % 33,554,393

[hi:lo] % 33,554,393 ≡ ((2<sup>32</sup> * hi) % 33,554,393) + (lo % 33,554,393)

[hi:lo] % 33,554,393 ≡ (((2<sup>32</sup> % 33,554,393) * hi) + (lo % 33,554,393) // hi will be no higher than 1972

[hi:lo] % 33,554,393 ≡ ((4,992 * hi) % 33,554,393) + (lo % 33,554,393) // 4,992 * hi will be no higher than 9,844,244

[hi:lo] % 33,5543,93 ≡ (4,992 * hi) + (lo % 33,554,393)

We only need the one modulo operation on lo, and then at most a single -= 33,554,393.

Using Asm allows us to make use of the 8 cycle delay to do something productive while waiting for the hardware divider.

## Licenses

All original code is covered by the MIT license. This covers the puzzle solution itself.

pico_sdk_import.cmake is copyright Raspberry Pi (Trading) Ltd and is covered by its own license.
