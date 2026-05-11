#include "pico/stdlib.h"
#include <stdio.h>

// ----------------------------------------------------------------------------

const char *PuzzleInput = "To continue, please consult the code grid in the manual.  Enter the code at row 1, column 5."; // Your input here

// ----------------------------------------------------------------------------

void PicoInitLED();
void PicoSetLED(bool on);
void InitialiseStdIn();

void TimeOptimisedSolutionCpp();
void TimeOptimisedSolutionAsm();
void TimeUnoptimisedSolution();

// ----------------------------------------------------------------------------

int main()
{
    InitialiseStdIn();

	while (true)
	{
		TimeOptimisedSolutionCpp();
		printf("\n");

		TimeOptimisedSolutionAsm();
		printf("\n");

		TimeUnoptimisedSolution();
		printf("\n");

        sleep_ms(1000);
    }
}

// ----------------------------------------------------------------------------

int32_t Unoptimised_Part1();
int32_t Optimised_Part1_Cpp();
int32_t Optimised_Part1_Asm();

// ----------------------------------------------------------------------------

void TimeUnoptimisedSolution()
{
    {
        printf("Starting unoptimised Part 1...\n");

		uint64_t startUs = time_us_64();
		int32_t part1 = Unoptimised_Part1();
		uint64_t durationUs = time_us_64() - startUs;

		printf("  Part1 [%d][%0.3f]\n", part1, durationUs / 1000000.0);	
    }
}

void TimeOptimisedSolutionCpp()
{
    {
        printf("Starting optimised C++ Part 1...\n");

		uint64_t startUs = time_us_64();
		int32_t part1 = Optimised_Part1_Cpp();
		uint64_t durationUs = time_us_64() - startUs;

		printf("  Part1 [%d][%0.3f]\n", part1, durationUs / 1000000.0);	
    }
}

void TimeOptimisedSolutionAsm()
{
    {
        printf("Starting optimised Asm Part 1...\n");

		uint64_t startUs = time_us_64();
		int32_t part1 = Optimised_Part1_Asm();
		uint64_t durationUs = time_us_64() - startUs;

		printf("  Part1 [%d][%0.3f]\n", part1, durationUs / 1000000.0);	
    }
}

// ----------------------------------------------------------------------------

void PicoInitLED()
{
	gpio_init(PICO_DEFAULT_LED_PIN);
	gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);
}

void PicoSetLED(bool on)
{
	gpio_put(PICO_DEFAULT_LED_PIN, on);
}

void InitialiseStdIn()
{
	PicoInitLED();

	stdio_init_all();

	bool ledState = true;
	while (!stdio_usb_connected())
	{
		PicoSetLED(ledState);
		sleep_ms(250);
		ledState = !ledState;
	}

	PicoSetLED(false);
}
