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
	"bufio"
	"encoding/json"
	"fmt"
	"github.com/fatih/color"
	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
	"os"
	"os/exec"
)

type Config struct {
	Contexts []Context `json:"contexts"`
}
type Context struct {
	Name string `json:"name"`
}

func newConfigureCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "configure",
		Short: "configure the cellery installation",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runConfigure()
		},
	}
	return cmd
}

func runConfigure() error {
	yellow := color.New(color.FgYellow).SprintFunc()
	faint := color.New(color.Faint).SprintFunc()
	green := color.New(color.FgGreen).SprintFunc()
	white := color.New(color.FgWhite)
	boldWhite := white.Add(color.Bold).SprintFunc()

	cellTemplate := &promptui.SelectTemplates{
		Label:    "{{ . }}",
		Active:   "\U000027A4 {{ .| cyan }}",
		Inactive: "  {{ . | white }}",
		Selected: green("\U00002713 ") + boldWhite("cell context: ") + "{{ .  | faint }}",
		Help: faint("[Use arrow keys]"),
	}

	cellPrompt := promptui.Select{
		Label: yellow("?") + " Select a cell context",
		Items: getContexts(),
		Templates: cellTemplate,
	}
	_, value, err := cellPrompt.Run()
	if err != nil {
		return fmt.Errorf("failed to select context: %v", err)
	}

	setContext(value)
	fmt.Printf("\rCellery is configured succesfully \n")
	return nil
}

func getContexts() []string {
	contexts := []string{}
	cmd := exec.Command("kubectl", "config", "view", "-o", "json")
	stdoutReader, _ := cmd.StdoutPipe()
	stdoutScanner := bufio.NewScanner(stdoutReader)
	output := ""
	go func() {
		for stdoutScanner.Scan() {
			output = output + stdoutScanner.Text()
		}
	}()
	stderrReader, _ := cmd.StderrPipe()
	stderrScanner := bufio.NewScanner(stderrReader)

	execError := ""
	go func() {
		for stderrScanner.Scan() {
			execError += stderrScanner.Text()
		}
	}()
	err := cmd.Start()
	if err != nil {
		fmt.Printf("Error in executing cellery configure: %v \n", err)
		os.Exit(1)
	}
	err = cmd.Wait()
	if err != nil {
		fmt.Printf("\x1b[31;1m Error occurred while configuring cellery: \x1b[0m %v \n", execError)
		os.Exit(1)
	}
	jsonOutput := &Config{}
	errJson := json.Unmarshal([]byte(output), jsonOutput)
	if errJson!= nil{
		fmt.Println(errJson)
	}

	for i:=0; i<len(jsonOutput.Contexts); i++ {
		contexts = append(contexts, jsonOutput.Contexts[i].Name)
	}
	return contexts
}

func setContext(context string) error {
	cmd := exec.Command("kubectl", "config", "use-context", context)
	stderrReader, _ := cmd.StderrPipe()
	stderrScanner := bufio.NewScanner(stderrReader)

	execError := ""
	go func() {
		for stderrScanner.Scan() {
			execError += stderrScanner.Text()
		}
	}()
	err := cmd.Start()
	if err != nil {
		fmt.Printf("Error in executing cellery apis: %v \n", err)
		os.Exit(1)
	}
	err = cmd.Wait()
	if err != nil {
		fmt.Printf("\x1b[31;1m Error occurred while configuring cellery: \x1b[0m %v \n", execError)
		os.Exit(1)
	}
	return nil
}
