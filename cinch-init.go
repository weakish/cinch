package main

import (
  "log"
  "os"
  "os/exec")

func main() {
  cmd := exec.Command("git", "config", "--global", "filter.sha256.clean", "sha256")
  err := cmd.Run()
  if err != nil {
    log.Fatal(err)
    os.Exit(1)
  }
}
