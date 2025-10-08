import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
    @EnviedField(varName: 'DISCORD_BOT_TOKEN')
    static const String discordBotToken = _Env.discordBotToken;
}