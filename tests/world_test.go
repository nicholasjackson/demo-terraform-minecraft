package main

import (
	"fmt"
	"testing"
	"os"

	"github.com/stretchr/testify/require"
)

// run the sub tests
func TestMain(m *testing.M) {
	// start a docker container
	startContainer()

	// stop the docker container after the tests
	defer stopContainer()

	// wait for the server to start
	err := waitForServer()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// if a test panics catch the panic and fail the test
	defer func() {
		if r := recover(); r != nil {
			stopContainer()
			panic(r)
		}
	}()

	// run the sub tests
	m.Run()

}

// test that the comparitor exists
func TestComparitorExists(t *testing.T) {
	// get a block at the position 10,33,32
	block, err := getBlock(209, -1, 1078)
	require.NoError(t, err)

	// check that the block material is a comparitor
	require.Equal(t, "minecraft:comparator", block.Material)
}

func TestPowererdRailExists(t*testing.T) {
	block, err := getBlock(172, -8, 1081)
	require.NoError(t, err)

	// check that the block material is a comparitor
	require.Equal(t, "minecraft:powered_rail", block.Material)
}