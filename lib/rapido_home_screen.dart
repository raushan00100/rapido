import 'package:flutter/material.dart';
import 'package:rapido/place_api_model.dart';
import 'package:rapido/show_map_screen.dart';

import 'map_api_services.dart';

class RapidoHomeScreen extends StatefulWidget {
  const RapidoHomeScreen({super.key});

  @override
  State<RapidoHomeScreen> createState() => _RapidoHomeScreenState();
}

class _RapidoHomeScreenState extends State<RapidoHomeScreen> {
  TextEditingController _currentController = TextEditingController();
  TextEditingController _dropController = TextEditingController();

  List<Place> _searchResults = [];
  bool _isLoading = false;
  bool isSearchingCurrent = true;

  Place? selectedCurrent;
  Place? selectedDrop;

  void searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);

    final result = await RapidoServices.searchLocation(query);
    if (result != null && result.places != null) {
      setState(() {
        _searchResults = result.places!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  void handlePlaceTap(Place place) {
    setState(() {
      if (isSearchingCurrent) {
        selectedCurrent = place;
        _currentController.text = place.displayName?.text ?? '';
      } else {
        selectedDrop = place;
        _dropController.text = place.displayName?.text ?? '';
      }
      _searchResults = [];
    });
  }

  void goToMap() {
    if (selectedCurrent != null && selectedDrop != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShowMapScreen(
            startAddress: selectedCurrent!.formattedAddress!,
            endAddress: selectedDrop!.formattedAddress!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: Center(
          child: const Text("Rapido", style: TextStyle(color: Colors.black)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _currentController,
              decoration: InputDecoration(
                labelText: "current location",
                prefixIcon: Icon(Icons.location_on, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28.0),
                ),
              ),
              onTap: () {
                isSearchingCurrent = true;
              },
              onChanged: searchLocation,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _dropController,
              decoration: InputDecoration(
                labelText: "Drop location",
                prefixIcon: Icon(Icons.location_on, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28.0),
                ),
              ),

              onSubmitted: (value) => goToMap(),

              onTap: () {
                isSearchingCurrent = false;
              },
              onChanged: searchLocation,
            ),
            const SizedBox(height: 12),

            if (_isLoading) const CircularProgressIndicator(),
            if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final place = _searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.pin_drop),
                      title: Text(place.displayName?.text ?? ''),
                      subtitle: Text(place.formattedAddress ?? ''),
                      onTap: () => handlePlaceTap(place),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
