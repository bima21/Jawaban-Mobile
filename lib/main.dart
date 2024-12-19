import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(AmiiboApp());

class AmiiboApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nitendo Amiibo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Widget> _screens = [AmiiboListScreen(), FavoriteScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AmiiboListScreen extends StatefulWidget {
  @override
  _AmiiboListScreenState createState() => _AmiiboListScreenState();
}

class _AmiiboListScreenState extends State<AmiiboListScreen> {
  List _amiibos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAmiiboData();
  }

  Future<void> _fetchAmiiboData() async {
    final response = await http.get(Uri.parse('https://www.amiiboapi.com/api/amiibo'));
    if (response.statusCode == 200) {
      setState(() {
        _amiibos = json.decode(response.body)['amiibo'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Amiibo List')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _amiibos.length,
        itemBuilder: (context, index) {
          final amiibo = _amiibos[index];
          return ListTile(
            leading: Image.network(amiibo['image']),
            title: Text(amiibo['name']),
            subtitle: Text(amiibo['gameSeries']),
            trailing: IconButton(
              icon: Icon(Icons.favorite_border),
              onPressed: () => _addToFavorites(amiibo),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(amiibo: amiibo),
              ),
            ),
          );
        },
      ),
    );
  }

  void _addToFavorites(Map amiibo) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];
    favorites.add(json.encode(amiibo));
    await prefs.setStringList('favorites', favorites);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${amiibo['name']} added to favorites')));
  }
}

class DetailScreen extends StatelessWidget {
  final Map amiibo;

  DetailScreen({required this.amiibo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(amiibo['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(amiibo['image']),
            SizedBox(height: 8),
            Text('Name: ${amiibo['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Game Series: ${amiibo['gameSeries']}', style: TextStyle(fontSize: 16)),
            Text('Type: ${amiibo['type']}', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class FavoriteScreen extends StatefulWidget {
  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Map> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];
    setState(() {
      _favorites = favorites.map((item) => json.decode(item) as Map).toList();
    });
  }

  void _removeFavorite(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];
    favorites.removeAt(index);
    await prefs.setStringList('favorites', favorites);
    setState(() {
      _favorites.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item removed from favorites')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favorites')),
      body: ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final amiibo = _favorites[index];
          return Dismissible(
            key: Key(amiibo['head']),
            onDismissed: (direction) => _removeFavorite(index),
            background: Container(color: Colors.red),
            child: ListTile(
              leading: Image.network(amiibo['image']),
              title: Text(amiibo['name']),
              subtitle: Text(amiibo['gameSeries']),
            ),
          );
        },
      ),
    );
  }
}
