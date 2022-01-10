package cmd

import (
	"os"

	"github.com/joho/godotenv"
	"github.com/rami3l/angela/lib"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func App() (app *cobra.Command) {
	app = &cobra.Command{
		Use:   "angela",
		Short: "Launch the `angela` bot",
	}

	app.Flags().SortFlags = true
	defaultVerbosityStr := "INFO"
	verbosity := app.Flags().StringP("verbosity", "v", defaultVerbosityStr, "Logging verbosity")

	app.Run = func(_ *cobra.Command, args []string) {
		inner := func() (err error) {
			verbosityLvl, err := log.ParseLevel(*verbosity)
			if err != nil {
				verbosityLvl, _ = log.ParseLevel(defaultVerbosityStr)
			}
			log.SetLevel(verbosityLvl)
			if err := godotenv.Load(); err != nil {
				log.Warn("Error loading .env file")
			}
			botToken := os.Getenv("ANGELA_TELEGRAM_BOT_TOKEN")

			log.Info("Angela is waking up...")
			return lib.LaunchBot(botToken)
		}

		if err := inner(); err != nil {
			os.Exit(1)
		}
	}
	return
}
