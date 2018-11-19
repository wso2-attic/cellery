/*
 * Copyright (c) 2018 WSO2 Inc. (http:www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http:www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package main

import (
	"fmt"
	"github.com/spf13/cobra"
	"github.com/tj/go-spin"
	"github.com/wso2/cellery/cli/util"
	"os/exec"
	"bufio"
	"os"
	"time"
)

func newRunCommand() *cobra.Command {
	var cellImage string
	cmd := &cobra.Command{
		Use:   "run [OPTIONS]",
		Short: "Use a cell image to create a running instance",
		RunE: func(cmd *cobra.Command, args []string) error {
			if (len(args) == 0) {
				cmd.Help()
				return nil
			}
			cellImage = args[0]
			err := run(cellImage)
			if err != nil{
				cmd.Help()
				return err
			}
			return nil
		},
		Example: "  cellery run hrApp",
	}
	return cmd
}

func run(cellImage string) error {
	if cellImage == "" {
		return fmt.Errorf("no cellImage name specified")
	}

	if _, err := os.Stat(cellImage + ".zip"); os.IsNotExist(err) {
		return fmt.Errorf("cellImage does not exist")
	}

	s := spin.New()
	for i := 0; i < 40; i++ {
		fmt.Printf("\r\033[36m%s\033[m Running %s %q", s.Next(), "image", cellImage)
		time.Sleep(100 * time.Millisecond)
	}
	fmt.Printf("\n")
	util.Unzip(cellImage + ".zip", cellImage)

	cmd := exec.Command("kubectl", "apply", "-f", cellImage + "/cellery/test.yaml")
	stdoutReader, _ := cmd.StdoutPipe()
	stdoutScanner := bufio.NewScanner(stdoutReader)
	go func() {
		for stdoutScanner.Scan() {
			fmt.Println(stdoutScanner.Text())
		}
	}()
	stderrReader, _ := cmd.StderrPipe()
	stderrScanner := bufio.NewScanner(stderrReader)
	go func() {
		for stderrScanner.Scan() {
			fmt.Println(stderrScanner.Text())
		}
	}()
	err := cmd.Start()
	if err != nil {
		fmt.Printf("Error in executing cell run: %v \n", err)
		os.Exit(1)
	}
	err = cmd.Wait()
	if err != nil {
		fmt.Printf("\x1b[31;1m Cell run finished with error: \x1b[0m %v \n", err)
		os.Exit(1)
	}

	fmt.Printf("\r\033[32m Successfully created cell instance \033[m  \n")

	return nil
}
