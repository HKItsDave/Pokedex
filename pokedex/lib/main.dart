import 'dart:convert';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class Pokemon {
  final String name;
  final int number;
  final String imageUrl;
  final String type;
  final String shinyImageUrl;

  Pokemon({
    required this.name,
    required this.number,
    required this.imageUrl,
    required this.type,
    required this.shinyImageUrl,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final int number = int.parse(json['url'].split('/')[6]);
    final imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$number.png';
    final shinyImageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$number.png';
    final type = (json['types'] != null && json['types'].isNotEmpty)
        ? json['types'][0]['type']['name']
        : 'Tipo desconocido';

    return Pokemon(
      name: json['name'],
      number: number,
      imageUrl: imageUrl,
      type: type,
      shinyImageUrl: shinyImageUrl,
    );
  }
}

//Aqui se obtiene la lista de Pokémon desde la API de Pokémon. Realiza una solicitud HTTP a la API de Pokémon para obtener la lista de Pokémon y Convierte la respuesta JSON en una lista de objetos
Future<List<Pokemon>> fetchPokemonList() async {
  final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=151'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body)['results'];

    final List<Pokemon> pokemonList = [];

    for (final pokemonData in data) {
      final pokemon = Pokemon.fromJson(pokemonData);
      pokemonList.add(pokemon);
    }

    return pokemonList;
  } else {
    throw Exception('Failed to load Pokemon');
  }
}


//Aqui va el "tema" principal de la app osea la apariencia
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PokemonListScreen(),
    );
  }
}


//La pantalla principal al abrir la app
class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PokemonListScreenState createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  late Future<List<Pokemon>> pokemonList;
  List<Pokemon> favoritePokemon = [];

  @override
  void initState() {
    super.initState();
    pokemonList = fetchPokemonList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritePokemonScreen(favoritePokemon: favoritePokemon),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<Pokemon>>(
          future: pokemonList,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final List<Pokemon> pokemon = snapshot.data ?? [];

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: pokemon.length,
              itemBuilder: (context, index) {
                final currentPokemon = pokemon[index];
                final isFavorite = favoritePokemon.contains(currentPokemon);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isFavorite) {
                        favoritePokemon.remove(currentPokemon);
                      } else {
                        favoritePokemon.add(currentPokemon);
                      }
                    });
                  },
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          currentPokemon.imageUrl,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                        Text('${currentPokemon.number}. ${currentPokemon.name}'),
                        Text('Tipo: ${currentPokemon.type}'),
                        Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class FavoritePokemonScreen extends StatelessWidget {
  final List<Pokemon> favoritePokemon;

  const FavoritePokemonScreen({super.key, required this.favoritePokemon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Favoritos'),
      ),
      body: ListView.builder(
        itemCount: favoritePokemon.length,
        itemBuilder: (context, index) {
          final currentPokemon = favoritePokemon[index];
          return Card(
            child: ListTile(
              title: Text('${currentPokemon.number}. ${currentPokemon.name}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PokemonDetailScreen(pokemon: currentPokemon),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PokemonDetailScreen extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonDetailScreen({super.key, required this.pokemon});

  @override
  // ignore: library_private_types_in_public_api
  _PokemonDetailScreenState createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  bool showShiny = false;

  @override
  Widget build(BuildContext context) {
    final currentPokemon = showShiny ? widget.pokemon.shinyImageUrl : widget.pokemon.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de ${widget.pokemon.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.network(
              currentPokemon,
              fit: BoxFit.cover,
              width: 200,
              height: 200,
            ),
            Text('${widget.pokemon.number}. ${widget.pokemon.name}'),
            Text('Tipo: ${widget.pokemon.type}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Versión Normal'),
                Switch(
                  value: showShiny,
                  onChanged: (value) {
                    setState(() {
                      showShiny = value;
                    });
                  },
                ),
                const Text('Versión Shiny'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}