package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

func startContainer() {
	// worldDir is the absolute path to the world dir
	worldDir, _ := filepath.Abs("../world")

	// start a docker container
	c := exec.Command(
		"docker",
		"run",
		"--name", "minecraft-test",
		"-d",
		"--rm",
		"-p", "25565:25565",
		"-p", "9090:9090",
		"-v", fmt.Sprintf("%s:/minecraft/world", worldDir),
		"-e", "MODS_BACKUP=https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/mods/mods.tar.gz",
		"hashicraft/minecraft:v1.20.1-fabric")

	c.Stdout = os.Stdout
	c.Stderr = os.Stderr

	if err := c.Run(); err != nil {
		fmt.Println("failed to start container:", err)
		os.Exit(1)
	}
}

// stop the docker container
func stopContainer() {
	c := exec.Command(
		"docker",
		"stop",
		"minecraft-test")

	if err := c.Run(); err != nil {
		fmt.Println("failed to stop container: ", err)
		os.Exit(1)
	}
}

// wait for the server to start
func waitForServer() error {
	// wait for the server to start
	for i := 0; i < 120; i++ {
		// try to connect to the servers http health check endpoint
		req, err := http.Get("http://localhost:9090/v1/health")
		if err == nil && req.StatusCode == http.StatusOK {
			// server is up
			return nil
		}

		// wait and check later
		time.Sleep(1 * time.Second)
	}

	// server is not up
	return fmt.Errorf("timeout waiting for server to start")
}

// block is a struct that represents a block in the world, it is used to unmarshal the JSON response
type block struct {
	// x is the x position of the block
	X int `json:"x"`
	// y is the y position of the block
	Y int `json:"y"`
	//z is the z position of the block
	Z int `json:"z"`
	// material is the material of the block
	Material string `json:"material"`
	// facing is the direction the block is facing
	Facing string `json:"facing"`
}

// get a block at the position x,y,z
func getBlock(x, y, z int) (*block, error) {
	// create a http request to get the block at the given position
	req, _ := http.NewRequest("GET", fmt.Sprintf("http://localhost:9090/v1/block/%d/%d/%d", x, y, z), nil)
	req.Header.Set("X-API-Key", "supertopsecret")

	// execute the request
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}

	// read the response
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	// test the status code
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	// unmarshal the response into a block
	var b block
	if err := json.Unmarshal(body, &b); err != nil {
		return nil, err
	}

	return &b, nil
}
