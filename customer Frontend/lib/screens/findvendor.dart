import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class Vendor {
  String name;
  String category;
  String location;
  double rating;
  String image;
  bool isFavorite;

  Vendor({
    required this.name,
    required this.category,
    required this.location,
    required this.rating,
    required this.image,
    this.isFavorite = false,
  });
}

class FindVendorScreen extends StatefulWidget {
  @override
  State<FindVendorScreen> createState() => _FindVendorScreenState();
}

class _FindVendorScreenState extends State<FindVendorScreen> {
  List<Vendor> _vendors = [
    Vendor(
      name: "Elegant Photography",
      category: "Photographer",
      location: "Anuradhapura",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1519681393784-d120267933ba",
    ),
    Vendor(
      name: "Bloom Florist",
      category: "Florist",
      location: "Colombo",
      rating: 4.5,
      image: "https://images.unsplash.com/photo-1501004318641-b39e6451bec6",
    ),
    Vendor(
      name: "Glamour Makeup Studio",
      category: "Makeup Artist",
      location: "Matara",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1556228724-4b96c1f4e1b8",
    ),
    Vendor(
      name: "Royal Decor",
      category: "Decorator",
      location: "Kandy",
      rating: 4.7,
      image: "https://images.unsplash.com/photo-1576402187873-725e6e0b6f28",
    ),
  ];

  String _searchQuery = "";
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final filteredVendors =
        _vendors
            .where(
              (v) =>
                  v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  v.category.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  v.location.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Find Vendors", style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              child:
                  _isGridView
                      ? _buildGridView(filteredVendors)
                      : _buildListView(filteredVendors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search vendor, category, location...",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildGridView(List<Vendor> vendors) {
    return GridView.builder(
      key: ValueKey(true),
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 250,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: vendors.length,
      itemBuilder: (context, index) => _buildVendorCard(vendors[index]),
    );
  }

  Widget _buildListView(List<Vendor> vendors) {
    return ListView.builder(
      key: ValueKey(false),
      padding: const EdgeInsets.all(12),
      itemCount: vendors.length,
      itemBuilder: (context, index) => _buildVendorCard(vendors[index]),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    return GestureDetector(
      onTap: () => _showVendorDetails(vendor),
      child: Hero(
        tag: vendor.name,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Ink.image(
                image: NetworkImage(vendor.image),
                fit: BoxFit.cover,
                height: double.infinity,
                child: Container(),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      vendor.category,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 4),
                    RatingBarIndicator(
                      rating: vendor.rating,
                      itemBuilder:
                          (context, _) => Icon(Icons.star, color: Colors.amber),
                      itemSize: 18,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    vendor.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: vendor.isFavorite ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () {
                    setState(() => vendor.isFavorite = !vendor.isFavorite);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVendorDetails(Vendor vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Text(
                vendor.name,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                vendor.category,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 10),
              RatingBarIndicator(
                rating: vendor.rating,
                itemBuilder:
                    (context, _) => Icon(Icons.star, color: Colors.amber),
                itemSize: 20,
              ),
              SizedBox(height: 10),
              Text(
                "Location: ${vendor.location}",
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.call),
                    label: Text("Contact"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.mail_outline),
                    label: Text("Message"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.place),
              title: Text("Filter by Location"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.category),
              title: Text("Filter by Category"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.star_rate),
              title: Text("Filter by Rating"),
              onTap: () {},
            ),
          ],
        );
      },
    );
  }
}
