#!/bin/bash

rm test/*.sux 2>/dev/null

for test in tests/*.su; do
    echo "Building $test"
    ./suplc $test
    echo "Running $test"
    ./suvm $test
done