// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:recase/recase.dart';
import 'package:version/version.dart';
import 'package:pub_semver/pub_semver.dart' as pub;

/// A map which adjusts icon ids starting with a number
///
/// Some icons cannot keep their id as identifier, as dart does not allow
/// numbers as the beginning of a variable names. The chosen solution is, to
/// write those parts out.
const Map<String, String> nameAdjustments = {
  "500px": "fiveHundredPx",
  "360-degrees": "threeHundredSixtyDegrees",
  "1": "one",
  "2": "two",
  "3": "three",
  "4": "four",
  "5": "five",
  "6": "six",
  "7": "seven",
  "8": "eight",
  "9": "nine",
  "0": "zero",
  "42-group": "fortyTwoGroup",
  "00": "zeroZero",
  // found in aliases
  "100": "hundred",
};

/// Some aliases clash with reserved words of dartlang. Those are ignored.
const List<String> ignoredAliases = ["try"];

/// Generated by [readAndPickMetadata] for each icon
class IconMetadata {
  final String name;
  final String label;
  final String unicode;
  final List<String> searchTerms;
  final List<String> styles;
  final List<String> aliases;

  IconMetadata(
    this.name,
    this.label,
    this.unicode,
    this.searchTerms,
    this.styles,
    this.aliases,
  );
}

final AnsiPen red = AnsiPen()..xterm(009);
final AnsiPen blue = AnsiPen()..xterm(012);
final AnsiPen yellow = AnsiPen()..xterm(011);

/// Utility program to customize font awesome flutter
///
/// For usage information see [displayHelp]
///
/// Steps:
/// 1. Check if icons.json exists in project root (or in lib/fonts)
/// if icons.json does not exist:
///   1.1 download official, free icons.json from github
///     https://raw.githubusercontent.com/FortAwesome/Font-Awesome/master/metadata/icons.json
///   1.2 download official, free icons and replace existing
///     https://raw.githubusercontent.com/FortAwesome/Font-Awesome/master/webfonts/fa-brands-400.ttf
///     https://raw.githubusercontent.com/FortAwesome/Font-Awesome/master/webfonts/fa-regular-400.ttf
///     https://raw.githubusercontent.com/FortAwesome/Font-Awesome/master/webfonts/fa-solid-900.ttf
/// 3. filter out unwanted icon styles
/// 4. build icons, example
/// if dynamic icons requested:
///   4.1 create map
/// 5. format all generated files
/// 6. if icons.json was downloaded by this tool, remove icons.json
void main(List<String> rawArgs) async {
  print(blue('''
####  #   #####################################################################
###  ###  ############ Font Awesome Flutter Configurator ######################
#   #   # #####################################################################
  '''));

  final argParser = setUpArgParser();
  final args = argParser.parse(rawArgs);

  if (args['help']) {
    displayHelp(argParser);
    exit(0);
  }

  // await printVersionNotice('fluttercommunity/font_awesome_flutter');

  File iconsJson = File('lib/fonts/icons.json');
  final hasCustomIconsJson = iconsJson.existsSync();

  if (!hasCustomIconsJson) {
    print(blue('No icons.json found, updating free icons'));
    const repositoryName = 'FortAwesome/Font-Awesome';
    final defaultBranch = await getRepositoryDefaultBranch(repositoryName);
    print(blue(
        'Choosing branch "$defaultBranch" of repository https://github.com/$repositoryName'));
    await download(
        'https://raw.githubusercontent.com/FortAwesome/Font-Awesome/$defaultBranch/metadata/icons.json',
        File('lib/fonts/icons.json'));
  } else {
    print(blue('Custom icons.json found, generating files'));
  }

  // A list of all versions mentioned in the metadata
  final List<String> versions = [];
  final List<IconMetadata> metadata = [];
  final Set<String> styles = {};
  // duotone icons are no longer supported
  final List<String> excludedStyles = ['duotone', ...args['exclude']];
  var hasDuotoneIcons = readAndPickMetadata(
      iconsJson, metadata, styles, versions, excludedStyles);
  if (hasDuotoneIcons) {
    // Duotone are no longer supported - temporarily added notice to avoid
    // confusion
    print(red(
        'Duotone icons are no longer supported. Automatically disabled them.'));
  }
  hasDuotoneIcons = false;

  writeCodeToFile(
    () => generateIconNameMap(metadata),
    'lib/src/name_icon_mapping.dart',
  );

  if (!hasCustomIconsJson) {
    print('Deleting icons.json');
    iconsJson.deleteSync();
  }
}

/// Returns this package's current version
String getPackageVersion() {
  var pubspecFile = File('pubspec.yaml');
  var pubspec = pubspecFile.readAsLinesSync();
  for (final line in pubspec) {
    if (line.startsWith('version:')) {
      return line.substring('version'.length + 1).trim();
    }
  }
  return 'no version found';
}

/// Comments out a line of yaml code. Does nothing if already commented
String commentYamlLine(String line) {
  if (line.startsWith('#')) return line;
  return '#$line';
}

/// Uncomments a line of yaml code. Does nothing if not commented.
///
/// Expects the rest of the line to be valid yaml and to have the correct
/// indention after removing the first #.
String uncommentYamlLine(String line) {
  if (!line.startsWith('#')) return line;
  return line.substring(1);
}

/// Writes lines of code created by a [generator] to [filePath] and formats it
void writeCodeToFile(List<String> Function() generator, String filePath) {
  List<String> generated = generator();
  File(filePath).writeAsStringSync(generated.join('\n'));
  final result = Process.runSync('dart', ['format', filePath]);
  stdout.write(result.stdout);
  stderr.write(red(result.stderr));
}

/// Enables the use of a map to dynamically load icons by their name
///
/// To use, import:
/// `import 'package:font_awesome_flutter/name_icon_mapping.dart'`
/// And then either use faIconNameMapping directly to look up specific icons,
/// or use the getIconFromCss helper function.
List<String> generateIconNameMap(List<IconMetadata> icons) {
  print(yellow('''

------------------------------- IMPORTANT NOTICE -------------------------------
Dynamic icon retrieval by name disables icon tree shaking. This means unused
icons will not be automatically removed and thus make the overall app size
larger. It is highly recommended to use this option only in combination with
the "exclude" option, to remove styles which are not needed.
You may need to pass --no-tree-shake-icons to the flutter build command for it
to complete successfully.
--------------------------------------------------------------------------------
'''));

  print(blue('Generating name to icon mapping'));

  List<String> output = [
    "import 'package:flutter/widgets.dart';",
    "import 'package:font_awesome_flutter/font_awesome_flutter.dart';",
    '',
    '// THIS FILE IS AUTOMATICALLY GENERATED!',
    '',
    '/// Utility function retrieve icons based on their css classes',
    '///',
    '/// [cssClasses] may contain other classes as well. This tool searches',
    '/// for the known font awesome classes (far, fas, fab, ...) and an icon',
    '/// name starting with `fa-`. Should multiple classes fulfill these',
    '/// requirements, the first occurrence is chosen.',
    '/// ',
    '/// Returns [FontAwesomeIcons.circleQuestion] if no icon matches.',
    'IconData getIconFromCss(String cssClasses) {',
    '  const Map<String, String> cssStyles = {',
    "    'far': 'regular', 'fas': 'solid', 'fab': 'brands',",
    "    'fad': 'duotone', 'fal': 'light', 'fat': 'thin',",
    '  };',
    '',
    "var separatedCssClasses = cssClasses.split(' ');",
    'try {',
    '  var style = separatedCssClasses.firstWhere((c) => cssStyles.containsKey(c));',
    '  // fas -> solid',
    '  style = cssStyles[style]!;',
    '',
    "  var icon = separatedCssClasses.firstWhere((c) => c.startsWith('fa-'));",
    "  icon = icon.replaceFirst('fa-', '');",
    '',
    "  return getIconFromStyleAndName(style, icon);",
    '  } on StateError {',
    '  return FontAwesomeIcons.circleQuestion;',
    '  }',
    '}',
    '',
    '/// Utility function retrieve icons based on their style and name',
    '///',
    '/// Returns [FontAwesomeIcons.circleQuestion] if no icon matches.',
    'IconData getIconFromStyleAndName(String style, String name) {',
    r"  return faIconNameMapping['$style $name'] ?? FontAwesomeIcons.circleQuestion;",
    '}',
    '',
    '/// Icon name to icon mapping for font awesome icons',
    '///',
    '/// Keys are in the following format: "style iconName"',
    'const Map<String, IconData> faIconNameMapping = {',
  ];

  String iconName;
  for (var icon in icons) {
    for (var style in icon.styles) {
      iconName = normalizeIconName(icon.name, style, icon.styles.length);
      output.add("'$style ${icon.name}': FontAwesomeIcons.$iconName,");
    }
  }

  output.add('};');

  return output;
}

/// Returns a normalized version of [iconName] which can be used as const name
///
/// [nameAdjustments] lists some icons which need special treatment to be valid
/// const identifiers, as they cannot start with a number.
/// The [style] name is automatically appended if necessary - deemed by the
/// number of [styleCompetitors] (number of styles) for this icon.
String normalizeIconName(String iconName, String style, int styleCompetitors) {
  iconName = nameAdjustments[iconName] ?? iconName;

  if (styleCompetitors > 1 && style != "regular") {
    iconName = "${style}_$iconName";
  }

  return iconName.camelCase;
}

/// Gets the default branch from github's metadata
///
/// Font awesome no longer uses the master branch, but instead version specific
/// ones, like 5.x and 6.x. Master is no longer updated. In the spirit of always
/// using the latest version, this tool always selects the default branch.
Future<String> getRepositoryDefaultBranch(String repositoryName) async {
  final tmpFile = File('fa-repo-metadata.tmp');
  await download('https://api.github.com/repos/$repositoryName', tmpFile);
  try {
    String rawGithubMetadata = await tmpFile.readAsString();
    Map<String, dynamic> githubMetadata = json.decode(rawGithubMetadata);
    return githubMetadata["default_branch"];
  } catch (_) {
    print(red('Error while getting font awesome\'s default branch. Aborting.'));
  } finally {
    tmpFile.delete();
  }
  exit(1);
}

/// Prints a notice should the current font_awesome_flutter version not be the
/// latest.
Future printVersionNotice(String repositoryName) async {
  final tmpFile = File('faf-releases-metadata.tmp');

  try {
    final packageVersion = pub.Version.parse(getPackageVersion());

    print(blue('Using font_awesome_flutter version $packageVersion'));

    await download(
        'https://api.github.com/repos/$repositoryName/releases', tmpFile);

    String rawReleasesData = await tmpFile.readAsString();
    List releasesData = json.decode(rawReleasesData);
    List<pub.Version> releases = [];
    List<pub.Version> preReleases = [];
    for (final Map<String, dynamic> release in releasesData) {
      var releaseName = release["name"] as String;
      releaseName = releaseName.isEmpty ? release["tag_name"] : releaseName;
      // remove possible prefixes
      releaseName = releaseName
          .toLowerCase()
          .replaceAll('version', '')
          .replaceAll('v.', '')
          .replaceAll('v', '')
          .trim();
      final version = pub.Version.parse(releaseName);
      if (version.isPreRelease) {
        preReleases.add(version);
      } else {
        releases.add(version);
      }
    }

    final primaryRelease = pub.Version.primary(releases);
    final primaryPreRelease = pub.Version.primary(preReleases);

    if (primaryRelease > packageVersion) {
      print(red(
          'A new version ($primaryRelease) of font_awesome_flutter is available. Please update before reporting any errors. You can update via `git pull` or by downloading the source code from github. (https://github.com/$repositoryName)'));
    }
    if (primaryPreRelease > packageVersion &&
        primaryPreRelease > primaryRelease) {
      print(yellow(
          'A pre-release version ($primaryPreRelease) of font_awesome_flutter is available. Should you encounter any problems, have a look if it fixes them.'));
    }
  } on FormatException catch (_) {
    print(red(
        'Error while getting font awesome flutter\'s version information. Could not determine whether you are using the latest version.'));
  } finally {
    tmpFile.delete();
  }
  // do not exit
  print('');
}

/// Reads the [iconsJson] metadata and picks out relevant data
///
/// Relevant data includes search-terms, label, unicode, styles, changes and is
/// saved to [metadata] as [IconMetadata].
/// Changes versions are all put into the [versions] list to calculate the
/// latest font awesome version.
/// [excludedStyles], which can be set in the program arguments, are removed.
/// Returns whether the dataset contains duotone icons.
bool readAndPickMetadata(File iconsJson, List<IconMetadata> metadata,
    Set<String> styles, List<String> versions, List<String> excludedStyles) {
  var hasDuotoneIcons = false;

  dynamic rawMetadata;
  try {
    final content = iconsJson.readAsStringSync();
    rawMetadata = json.decode(content);
  } catch (_) {
    print(
        'Error: Invalid icons.json. Please make sure you copied the correct file.');
    exit(1);
  }

  Map<String, dynamic> icon;
  for (var iconName in rawMetadata.keys) {
    icon = rawMetadata[iconName];

    // Add all changes to the list
    for (var v in icon['changes'] as List) {
      versions.add(v);
    }

    List<String> iconStyles = (icon['styles'] as List).cast<String>();

    //NOTE: Remove line once duotone support discontinuation notice is removed
    if (iconStyles.contains('duotone')) hasDuotoneIcons = true;

    for (var excluded in excludedStyles) {
      iconStyles.remove(excluded);
    }

    if (iconStyles.isEmpty) continue;

    if (icon.containsKey('private') && icon['private']) continue;

    styles.addAll(iconStyles);

    final List searchTermsRaw = (icon['search']?['terms'] ?? []);
    final searchTerms = searchTermsRaw.map((e) => e.toString()).toList();

    final List aliasesRaw = (icon['aliases']?['names'] ?? []);
    final aliases = aliasesRaw.map((e) => e.toString()).toList();

    metadata.add(IconMetadata(
      iconName,
      icon['label'],
      icon['unicode'],
      searchTerms,
      iconStyles,
      aliases,
    ));
  }

  return hasDuotoneIcons;
}

/// Calculates the highest version number found in the metadata
///
/// Expects a list of all versions listed in the metadata.
/// See [readAndPickMetadata].
Version calculateFontAwesomeVersion(List<String> versions) {
  final sortedVersions = versions.map((version) {
    try {
      return Version.parse(version);
    } on FormatException {
      return Version(0, 0, 0);
    }
  }).toList()
    ..sort();

  return sortedVersions.last;
}

/// Downloads the content from [url] and saves it to [target]
Future download(String url, File target) async {
  print('Downloading $url');
  final request = await HttpClient().getUrl(Uri.parse(url));
  final response = await request.close();
  return response.pipe(target.openWrite());
}

/// Defines possible command line arguments for this program
ArgParser setUpArgParser() {
  final argParser = ArgParser();

  argParser.addFlag('help',
      abbr: 'h',
      defaultsTo: false,
      negatable: false,
      help: 'display program options and usage information');

  argParser.addMultiOption('exclude',
      abbr: 'e',
      defaultsTo: [],
      allowed: ['brands', 'regular', 'solid', 'duotone', 'light', 'thin'],
      help: 'icon styles which are excluded by the generator');

  argParser.addFlag('dynamic',
      abbr: 'd',
      defaultsTo: false,
      negatable: false,
      help: 'builds a map, which allows to dynamically retrieve icons by name');

  return argParser;
}

/// Displays the program help page. Accessible via the --help command line arg
void displayHelp(ArgParser argParser) {
  var fileType = Platform.isWindows ? 'bat' : 'sh';
  print('''
This script helps you to customize the font awesome flutter package to fit your
individual needs. Please follow the "customizing font awesome flutter" guide on
github.

By default, this tool acts as an updater. It retrieves the newest version of
free font awesome icons from the web and generates all necessary files.
If an icons.json exists within the lib/fonts folder, no update is performed and
files in this folder are used for generation instead.
To exclude styles from generation, pass the "exclude" option with a comma
separated list of styles to ignore.

Usage:
configurator.$fileType [options]

Options:''');
  print(argParser.usage);
}
