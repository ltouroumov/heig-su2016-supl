#!/bin/bash

rm test/*.sux 2>/dev/null

for test in test_samples/*.su; do
    echo "Building $test"
    ./suplc $test
    echo "Running $test"
    ./suvm $test
done