import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

// Quick and dirty way to test the quick start tutorial 
// 
// make sure to activate the latest `mid` from path 
//  i.e. melos activate 
void main() async {
  Process? frontendProcess;
  Process? serverProcess;

  tearDownAll(() {
    frontendProcess?.kill();
    serverProcess?.kill();
  });

  test('test quick start tutorial', () async {
    final tempDir = Directory.systemTemp.path;
    final time = DateTime.now().microsecondsSinceEpoch;
    final projectName = 'mid_quick_start_tutorial_test_$time';
    final clientName = 'MidQuickStartTutorialTest${time}Client';
    final dirName = p.join(tempDir, projectName);

    Directory(dirName).createSync();

    print('creating project at $dirName');
    final createProjectProcess = await Process.run(
      'mid',
      ['create', '.', '--force'],
      workingDirectory: dirName,
    );

    if (createProjectProcess.exitCode != 0) {
      throw 'failed to create mid project';
    }

    // add pubspec overrides
    final clientPath = p.join(dirName, '${projectName}_client');
    final serverPath = p.join(dirName, '${projectName}_server');

    print('adding pubspec_overrides.yaml');
    final pubspecOverridesClientFile = File(p.join(clientPath, 'pubspec_overrides.yaml'));
    final pubspecOverridesServerFile = File(p.join(serverPath, 'pubspec_overrides.yaml'));
    pubspecOverridesClientFile.writeAsString(pubspecOverridesClientContents);
    pubspecOverridesServerFile.writeAsString(pubspecOverridesServerContents);

    await Future.delayed(Duration(seconds: 3));
    print('running dart pub get for client');
    if (runPubGet(clientPath) != 0) {
      throw 'failed to run dart pub get on client project';
    }

    print('running dart pub get for server');
    if (runPubGet(serverPath) != 0) {
      throw 'failed to run dart pub get on server project';
    }

    /// Follow tutorial

    // create end point
    createEndPointFile(serverPath);
    updateGetEndPointFunction(projectName, serverPath);

    final midGenerateAllProcess = await Process.run(
      'mid',
      [
        'generate',
        'all',
      ],
      workingDirectory: dirName,
    );

    if (midGenerateAllProcess.exitCode != 0) {
      throw 'failed to run `mid generate all due to the following error ${midGenerateAllProcess.stderr}`';
    }

    // create frontend
    createFrontend(projectName, clientPath, clientName);

    // run the server
    print('running the server process');
    serverProcess = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      workingDirectory: serverPath,
    );

    serverProcess!.stdout.pipe(stdout);

    print('running the frontend process');
    frontendProcess = await Process.start(
      'dart',
      ['run', 'bin/frontend.dart'],
      workingDirectory: clientPath,
    );

    final result = [];
    final sub = frontendProcess!.stdout
        .map((e) => utf8.decode(e).replaceAll('\n', ''))
        .where((event) => event.isNotEmpty)
        .listen((event) {
      result.add(event);
    });

    await sub.asFuture().timeout(Duration(seconds: 15));

    print('got results $result');
    expect(result, expectedResult);
  }, timeout: Timeout(Duration(seconds: 60)));
}

int runPubGet(String path) {
  return Process.runSync(
    'dart',
    ['pub', 'get'],
    workingDirectory: path,
  ).exitCode;
}

// $serverProject/lib/src/quick_start.dart
void createEndPointFile(String serverProjectPath) {
  final content = r'''
    import 'package:mid/endpoints.dart';

    class Example extends EndPoints {
    
      // Regular endpoint example
      String hello(String name) => 'Hello $name!';

      // Streaming endpoint example
      Stream<int> countdown([int from = 10]) async* {
        int i = 0;
        while (from >= i) {
          yield from - i;
          i++;
          await Future.delayed(Duration(seconds: 1));
        }
      }
      
      /* feel free to add other functions here */

    }
''';

  File(p.join(serverProjectPath, 'lib/src/example.dart')).writeAsStringSync(content);
}

void updateGetEndPointFunction(String projectName, String serverProjectPath) {
  final content = '''
    import 'package:mid/mid.dart';
    import 'package:${projectName}_server/src/example.dart';

    Future<List<EndPoints>> getEndPoints() async {
        return <EndPoints>[
            Example(),
        ];
    }
''';

  File(p.join(serverProjectPath, 'lib/mid/endpoints.dart')).writeAsStringSync(content);
}

void createFrontend(String projectName, String clientProjectPath, String clientName) {
  final contents = '''

    import 'package:${projectName}_client/${projectName}_client.dart';

    void main() async {
        // initialize the client
        final client = $clientName(url: 'localhost:8000'); 
        
        // call the regular endpoint
        final response = await client.example.hello('World');
        print(response);

        // listen to the streaming endpoint
        client.example.countdown().listen((event) {
            print('countdown: \$event');
        });
    }
''';

  File(p.join(clientProjectPath, 'bin', 'frontend.dart')).writeAsStringSync(contents);
}

final expectedResult = [
  'Hello World!',
  'countdown: 10',
  'countdown: 9',
  'countdown: 8',
  'countdown: 7',
  'countdown: 6',
  'countdown: 5',
  'countdown: 4',
  'countdown: 3',
  'countdown: 2',
  'countdown: 1',
  'countdown: 0',
];


const pubspecOverridesClientContents = '''
dependency_overrides:
  mid_client:
    path: /Users/osaxma/Projects/mid/packages/mid_client
  mid_protocol:
    path: /Users/osaxma/Projects/mid/packages/mid_protocol
  mid_common:
    path: /Users/osaxma/Projects/mid/packages/mid_common
''';

const pubspecOverridesServerContents = '''
dependency_overrides:
  mid_server:
    path: /Users/osaxma/Projects/mid/packages/mid_server
  mid_protocol:
    path: /Users/osaxma/Projects/mid/packages/mid_protocol
  mid_common:
    path: /Users/osaxma/Projects/mid/packages/mid_common
''';
