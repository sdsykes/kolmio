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

### Solver description

The solution is found using a recursive algorithm that evaluates a set of rules one by one,
placing triangles to satisfy the rules at each step.

Each rule specifies two edges that must match. If you watch the visualisation, you can see
how this algorithm works.

As an optimisation, certain triangle piece / orientation combinations are discarded before placing them
because we know through counting the number of matching pictures that only certain pictures can appear
on the outside edge of the megakolmio.

These optimisations are a huge win, reducing the number of placings tried by about 73%.

Secondly, as we know exactly what pictures must go on the outer edges, we can eliminate further
branches by not proceeding if there aren't enough sides left to fill the those edges. This is
a further reduction of 40%.

In total, the steps needed to solve the puzzle are reduced by 83.5% as opposed to a simple algorithm.

### Speed

This solution has not been heavily optimised for speed, clarity is more important.

However, even though Ruby is an interpreted language, it's pretty quick - tests show it completes
within 180mS - 500mS depending on processor speed.

It takes exactly 720 placings to find all the solutions.

### Solution

There are 2 distinct solutions, and, of course, 3 different rotations of each one.

    [P1, P3, P7, P6, P5, P9, P4, P8, P2]
    [P2, P6, P8, P4, P1, P7, P3, P9, P5]
    [P3, P1, P4, P5, P9, P2, P7, P6, P8]
    [P5, P4, P9, P3, P2, P8, P6, P7, P1]
    [P8, P5, P6, P7, P3, P4, P1, P2, P9]
    [P9, P7, P2, P1, P8, P6, P5, P4, P3]

### Webgen

With the webgen option, the solver generates png images of the finished solutions using a png library.
This works by compositing the pre-rotated images from the images directory.

The steps.json file is simply a record of each position tried, with the position
and rotation of each piece.

### Thanks

Thanks to Wunderdog for [posing this puzzle](http://www.wunderdog.fi/wundernut-megakolmio).
