package cmd

import (
	"os"

	"github.com/joho/godotenv"
	"github.com/rami3l/angela/lib"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func App() (app *cobra.Command) {
	app = &cobra.Command{
		Use:   "angela",
		Short: "Launch the `angela` bot",
	}

	viper.SetEnvPrefix("angela")
	viper.AutomaticEnv()
	flags := app.Flags()
	flags.SortFlags = true

	const verbosity = "verbosity"
	defaultVerbosityStr := "INFO"
	app.Flags().StringP(verbosity, "v", defaultVerbosityStr, "Logging verbosity")
	_ = viper.BindPFlag(verbosity, flags.Lookup(verbosity))

	app.Run = func(_ *cobra.Command, args []string) {
		inner := func() (err error) {
			if err1 := godotenv.Load(); err1 != nil {
				log.Info("`.env` is missing, relying on env vars")
			}
			verbosityLvl, err := log.ParseLevel(viper.GetString(verbosity))
			if err != nil {
				verbosityLvl, _ = log.ParseLevel(defaultVerbosityStr)
			}
			log.SetLevel(verbosityLvl)

			log.Info("angela is waking up...")
			log.Infof("current verbosity level: %s", verbosityLvl)

			return lib.NewBotFromEnv().Launch()
		}

		if err := inner(); err != nil {
			os.Exit(1)
		}
	}
	return
}
