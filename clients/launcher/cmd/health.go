package cmd

import (
	"github.com/dazeb/botron/clients/launcher/internal/compose"
	"github.com/dazeb/botron/clients/launcher/internal/ui"
	"github.com/spf13/cobra"
)

var healthCmd = &cobra.Command{
	Use:     "kg-health",
	Aliases: []string{"graph-health"},
	Short:   "Run LangGraph health diagnostics",
	RunE: func(cmd *cobra.Command, args []string) error {
		ui.Info("Running LangGraph health diagnostics...")
		return compose.New().Exec("langgraph", "python", "-m", "botron.tools.research.health")
	},
}

func init() {
	rootCmd.AddCommand(healthCmd)
}
