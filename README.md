# MEGAKOLMIO solver

## Stephen Sykes

This solver is written in Ruby.

It has output in the competition specified format, and optionally generates png images
of the solutions, and records the steps taken to get to each solution in a json file.

There is a web front-end that can read these files, and display an animation of how the
puzzle was solved. [You can find the web page here.](http://sdsykes.github.io/kolmio/index.html)

In order to run the solver and verify it works, use bundler to setup the required gems, then
just run the ruby file.

    bundle install
    ruby kolmio.rb

### Usage

    ruby kolmio.rb [webgen]

Running without the webgen parameter just produces the
results in the format specified by the competition rules.
Adding the webgen parameter enables output of results images
and the steps file needed for the web page. Generating the
png files is very slow, so this takes much longer to run.

### Description

The solution is found using a recursive algorithm that evaluates a set of rules one by one,
placing triangles to satisfy the rules at each step.

Each rule specifies two edges that must match. If you watch the visualisation, you can see
how this algorithm works.

As an optimisation, certain triangle piece / orientation combinations are discarded before placing them
because we know through counting the number of matching pictures that only certain pictures can appear
on the outside edge of the megakolmio.

### Speed

This solution has not been heavily optimised for speed, clarity is more important.

However, even though Ruby is an interpreted language, it's pretty quick - tests show it completes
within 180mS - 400mS depending on processor speed.

It takes exactly 1784 calls to solve() to find all the solutions.

### Thanks

Thanks to Wunderdog for [posting this puzzle](http://www.wunderdog.fi/wundernut-megakolmio).
