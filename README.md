# MEGAKOLMIO solver

## Stephen Sykes

This solver is written in Ruby. Oh, and there's one in Go too.

But first, the Ruby solution.

It has output in the competition specified format, and optionally generates png images
of the solutions, and records the steps taken to get to each solution in a json file.

There is a web front-end that can read these files, and display an animation of how the
puzzle was solved. [You can find the web page here.](http://sdsykes.github.io/kolmio/)

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

### Go

Because there is an obvious way the solution search can be parallelised, I wrote a solution in Go
to try this out.

It runs essentially the same algorithm, but with a little more emphasis on speed.

Goroutines are fired off to work on solutions starting with each of the 9 pieces in the top
position. The first solution to be found is printed out, and the program exits.

    $ go build
    $ ./kolmio
    [P9, P7, P2, P1, P8, P6, P5, P4, P3]

This typically runs in less than 2mS on my machine.

By removing the break statement at line 223 you could see all the solutions, which will be slightly slower.
But still a couple of orders of magnitude faster than Ruby.

### Further ideas

Because there are only 2 distinct solutions, eliminating the search for rotations of them could be
done early on. However, it is rather fun to watch the animation of the search for all 6 solutions.

### Thanks

Thanks to Wunderdog for [posing this puzzle](http://www.wunderdog.fi/wundernut-megakolmio).
