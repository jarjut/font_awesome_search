import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_search/font_awesome_search.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Font Awesome Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Font Awesome Search'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading = false;
  final _searchController = TextEditingController();
  List<IconData> _icons = [];

  Future<void> search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _icons.clear();
      });
      return;
    }
    setState(() {
      _loading = true;
    });

    final icons = await searchFontAwesomeIcons(query);
    setState(() {
      _loading = false;
      _icons = icons;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for an icon',
                    ),
                    onSubmitted: (_) => search(),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : search,
                  icon: const FaIcon(FontAwesomeIcons.magnifyingGlass),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _icons.isEmpty
                    ? const Center(
                        child: Text('No icons'),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 100,
                          mainAxisExtent: 100,
                        ),
                        itemCount: _icons.length,
                        itemBuilder: (context, index) {
                          final icon = _icons[index];
                          return Center(
                            child: FaIcon(
                              icon,
                              size: 50,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
