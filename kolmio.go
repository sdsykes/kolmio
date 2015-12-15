package main

import (
	"fmt"
	"strings"
)

// A Side of a piece
type Side struct {
	sym   string
	isTop bool
	name  string
	used  bool
}

// A Triangle piece
type Triangle struct {
	sides    []Side
	rotation int
	number   int
	present  bool
}

// Solution return values
type Solution struct {
	placings [9]Triangle
	success  bool
}

var triangles [9]Triangle
var outerSides [9]Side

func sideMatches(side Side, otherSide Side) bool {
	if side.name == otherSide.name && side.isTop != otherSide.isTop {
		return true
	}
	return false
}

func rotate(triangle Triangle) Triangle {
	sides := triangle.sides
	first, rest := sides[0], sides[1:]
	triangle.sides = append(rest, first)
	triangle.rotation = (triangle.rotation + 1) % 3
	return triangle
}

func makeTriangles() {
	triangleDefs := [][]string{
		{"fox t", "fox b", "deer t"},
		{"deer t", "fox b", "raccoon b"},
		{"deer t", "fox b", "fox t"},
		{"deer t", "deer b", "fox b"},
		{"deer t", "raccoon b", "deer b"},
		{"raccoon b", "fox b", "raccoon t"},
		{"fox b", "raccoon t", "fox t"},
		{"raccoon t", "deer t", "raccoon b"},
		{"fox b", "deer b", "deer t"},
	}

	for n, sides := range triangleDefs {
		var sideStructs []Side
		for _, side := range sides {
			fields := strings.Fields(side)
			sideStructs = append(sideStructs, Side{sym: side, name: fields[0], isTop: fields[1] == "t"})
		}
		triangles[n] = Triangle{sides: sideStructs, rotation: 0, number: n + 1, present: true}
	}
}

func makeOuterSides() {
	outerSideComposition := []string{
		"fox b", "fox b", "fox b", "fox b", "deer t", "deer t", "deer t", "deer t", "raccoon b",
	}

	for n, side := range outerSideComposition {
		fields := strings.Fields(side)
		outerSides[n] = Side{sym: side, name: fields[0], isTop: fields[1] == "t", used: false}
	}
}

var conditions = [][]int{
	{0, 2, 2, 0},
	{1, 1, 2, 2},
	{1, 2, 5, 0},
	{4, 1, 5, 2},
	{2, 1, 3, 0},
	{3, 2, 7, 0},
	{5, 1, 6, 0},
	{6, 1, 7, 2},
	{7, 1, 8, 0},
}

func unusedPieces(placings [9]Triangle) [9]Triangle {
	unusedArray := triangles
	for _, placedTriangle := range placings {
		if placedTriangle.present {
			unusedArray[placedTriangle.number-1].present = false
		}
	}
	return unusedArray
}

var outerEdges = [][]int{
	{0, 1},
	{0},
	{},
	{1},
	{0, 2},
	{},
	{2},
	{},
	{1, 2},
}

func canPlace(piece Triangle, pos int, unusedOuterSides [9]Side) ([9]Side, bool) {
	relevantSides := outerEdges[pos]

	originalUnusedSides := unusedOuterSides
	for _, sideIndex := range relevantSides {
		side := piece.sides[sideIndex]
		found := false
		for i, unusedSide := range unusedOuterSides {
			if !unusedSide.used && side.name == unusedSide.name {
				unusedOuterSides[i].used = true
				found = true
				break
			}
		}
		if !found {
			return originalUnusedSides, false
		}
	}
	return unusedOuterSides, true
}

func solve(placings [9]Triangle, level int) Solution {
	if level == len(conditions) {
		return Solution{placings, true}
	}

	condition := conditions[level]
	pos1, side1, pos2, side2 := condition[0], condition[1], condition[2], condition[3]

	if placings[pos1].present && placings[pos2].present {
		if sideMatches(placings[pos1].sides[side1], placings[pos2].sides[side2]) {
			return solve(placings, level+1)
		}
		return Solution{placings, false}
	}
	unfilledPos := pos1
	if placings[pos1].present {
		unfilledPos = pos2
	}

	unused := unusedPieces(placings)
	for _, unusedPiece := range unused {
		if !unusedPiece.present {
			continue
		}

		rotatedPiece := unusedPiece
		for i := 0; i < 3; i++ {
			rotatedPiece = rotate(rotatedPiece)
			placings[unfilledPos] = rotatedPiece
			if sideMatches(placings[pos1].sides[side1], placings[pos2].sides[side2]) {
				solution := solve(placings, level+1)
				if solution.success {
					return Solution{solution.placings, true}
				}
			}
		}
	}

	return Solution{placings, false}
}

func printSolution(solution [9]Triangle) {
	fmt.Print("[")
	for i := 0; i < 9; i++ {
		fmt.Print("P", solution[i].number)
		if i < 8 {
			fmt.Print(", ")
		}
	}
	fmt.Print("]\n")
}

func solveWithFirstTriangle(triangle Triangle, solutionChan chan Solution) {
	var placings [9]Triangle
	for i := 0; i < 9; i++ {
		placings[i] = Triangle{present: false}
	}
	var result Solution
	for i := 0; i < 3; i++ {
		triangle = rotate(triangle)
		_, allowed := canPlace(triangle, 0, outerSides)
		if !allowed {
			continue
		}
		placings[0] = triangle
		result = solve(placings, 0)
		if result.success {
			break
		}
	}
	solutionChan <- result
}

func main() {
	makeTriangles()
	makeOuterSides()
	solutionChan := make(chan Solution)

	// Spin up 9 goroutines, one for each starting piece
	for i := 0; i < 9; i++ {
		go solveWithFirstTriangle(triangles[i], solutionChan)
	}
	for i := 0; i < 9; i++ {
		result := <-solutionChan
		if result.success {
			printSolution(result.placings)
			break // remove this if you want all the solutions
		}
	}
}
