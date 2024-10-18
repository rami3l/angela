# Angela

## Quick Start

Some required environment variables should be set up before running this bot
(replace the token with your own):

```txt
ANGELA_TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
```

Alternatively, you can create a `.env` file to include these variables.

### Running the Bot in Polling Mode

No further setup is needed.

### Running the Bot in Webhook Mode

To run the bot in webhook (serverless) mode, you will need to set up the webhook URL as well.

Here we use Zeabur's domain as an example (replace the public domain with your own):

```txt
ANGELA_TELEGRAM_BOT_WEBHOOK_LISTEN=https://<your-public-domain>.zeabur.app
```

After successfully deploying the bot to your FaaS,
go to `https://<your-public-domain>` to see if it is up and running.

If you see `OK`, then you can register this webhook at Telegram to make it work by
going to `https://<your-public-domain>/webhook`.

If you see `OK, set` at this point, then the bot should be able to work properly.
