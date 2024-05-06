package io.github.rami3l.angela;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.telegram.telegrambots.abilitybots.api.bot.AbilityBot;
import org.telegram.telegrambots.abilitybots.api.objects.Ability;
import org.telegram.telegrambots.abilitybots.api.objects.Locality;
import org.telegram.telegrambots.abilitybots.api.objects.Privacy;
import org.telegram.telegrambots.client.okhttp.OkHttpTelegramClient;
import org.telegram.telegrambots.longpolling.BotSession;
import org.telegram.telegrambots.longpolling.interfaces.LongPollingUpdateConsumer;
import org.telegram.telegrambots.longpolling.starter.AfterBotRegistration;
import org.telegram.telegrambots.longpolling.starter.SpringLongPollingBot;

@Component
public class Bot extends AbilityBot implements SpringLongPollingBot {
  private final String token;

  @Autowired
  public Bot(Environment env) {
    this(
        env.getProperty("angela.telegram.bot.token"),
        env.getProperty("angela.telegram.bot.username"));
  }

  public Bot(String token, String username) {
    super(new OkHttpTelegramClient(token), username);
    this.token = token;
  }

  @Override
  public String getBotToken() {
    return token;
  }

  @Override
  public long creatorId() {
    return 1337L; // TODO: Your ID here
  }

  public Ability saysHelloWorld() {
    return Ability.builder()
        .name("hello") // Name and command (/hello)
        .info("Says hello world!") // Necessary if you want it to be reported via /commands
        .privacy(Privacy.PUBLIC) // Choose from Privacy Class (Public, Admin, Creator)
        .locality(Locality.ALL) // Choose from Locality enum Class (User, Group, PUBLIC)
        .input(0) // Arguments required for command (0 for ignore)
        .action(
            ctx -> {
              /*
              ctx has the following main fields that you can utilize:
              - ctx.update() -> the actual Telegram update from the basic API
              - ctx.user() -> the user behind the update
              - ctx.firstArg()/secondArg()/thirdArg() -> quick accessors for message arguments (if any)
              - ctx.arguments() -> all arguments
              - ctx.chatId() -> the chat where the update has emerged

              NOTE that chat ID and user are fetched no matter what the update carries.
              If the update does not have a message, but it has a callback query, the chatId and user will be fetched from that query.
               */
              // Custom sender implementation
              silent.send("Hello World!", ctx.chatId());
            })
        .build();
  }

  @AfterBotRegistration
  public void afterRegistration(BotSession botSession) {
    this.onRegister();
  }

  @Override
  public LongPollingUpdateConsumer getUpdatesConsumer() {
    return this;
  }
}
