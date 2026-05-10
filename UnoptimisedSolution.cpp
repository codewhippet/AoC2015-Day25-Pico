#include <stdio.h>
#include <stdint.h>
#include <string.h>

using namespace std;

extern const char* PuzzleInput;

static int32_t GridIndexFromRowColumn(int32_t row, int32_t column)
{
	// Get the 'starting' position [r0,1] of the diagonal containing [row,column]
	int32_t r0 = row + (column - 1);

	// The starting grid index for each row [r0,1] is TriangleNumber(r0-1) + 1
	int32_t triangleNumber = ((r0 - 1) * (r0)) / 2;
	int32_t startingGridIndex = triangleNumber + 1;

	// Then add back on the row count we took away
	int32_t gridIndex = startingGridIndex + (r0 - row);
	return gridIndex;
}

int32_t Unoptimised_Part1()
{
	int32_t row = 0;
	int32_t column = 0;
	sscanf(PuzzleInput, "To continue, please consult the code grid in the manual.  Enter the code at row %d, column %d.",
		&row,
		&column);

	int32_t rngIterations = GridIndexFromRowColumn(row, column);

	int64_t answer = 20151125;
	for (int32_t i = 1; i < rngIterations; i++)
	{
		answer = (answer * 252533) % 33554393;
	}

	return answer;
}
