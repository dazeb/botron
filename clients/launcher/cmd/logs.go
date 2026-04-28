package cmd

import (
	"github.com/dazeb/botron/clients/launcher/internal/compose"
	"github.com/spf13/cobra"
)

var logsCmd = &cobra.Command{
	Use:   "logs [service]",
	Short: "Follow service logs (default: langgraph)",
	Args:  cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		service := "langgraph"
		if len(args) > 0 {
			service = args[0]
		}
		return compose.New().Logs(service)
	},
}

func init() {
	rootCmd.AddCommand(logsCmd)
}
