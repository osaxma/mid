import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/common/io_utils.dart';

abstract class MIDCommand extends Command<void> {
  /// see [ArgParser.allowTrailingOptions]
  bool get allowTrailingOptions => true;
  Logger get logger => globalResults!['verbose'] as bool ? Logger.verbose() : Logger.standard();

  @override
  late final ArgParser argParser = ArgParser(
    usageLineLength: terminalWidth,
    allowTrailingOptions: allowTrailingOptions,
  );
}