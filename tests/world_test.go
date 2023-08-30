package main

import (
	"testing"

	"github.com/stretchr/testify/require"
)

// run the sub tests
func TestMain(m *testing.M) {
	// start a docker container
	startContainer()

	// wait for the server to start
	waitForServer()

	// if a test panics cath the panic and fail the test
	defer func() {
		if r := recover(); r != nil {
			stopContainer()
			panic(r)
		}
	}()

	// run the sub tests
	m.Run()

	// stop the docker container after the tests
	stopContainer()
}

// test that the comparitor exists
func TestComparitorExists(t *testing.T) {
	// get a block at the position 10,33,32
	block, err := getBlock(209, -1, 1078)
	require.NoError(t, err)

	// check that the block material is a comparitor
	require.Equal(t, "minecraft:comparator", block.Material)
}
