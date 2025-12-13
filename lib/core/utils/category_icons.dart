import 'package:flutter/material.dart';

/// Maps category names to Material Icons
class CategoryIcons {
  static IconData? getIconForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    
    // Food & Dining
    if (name.contains('food') || name.contains('dining') || name.contains('restaurant')) {
      return Icons.restaurant;
    }
    if (name.contains('cafe') || name.contains('coffee')) {
      return Icons.local_cafe;
    }
    if (name.contains('bar') || name.contains('pub') || name.contains('alcohol')) {
      return Icons.local_bar;
    }
    if (name.contains('grocery') || name.contains('groceries')) {
      return Icons.shopping_cart;
    }
    
    // Transportation - Check specific types first before general transport
    if (name.contains('flight') || name.contains('airplane') || name.contains('airline')) {
      return Icons.flight;
    }
    if (name.contains('train')) {
      return Icons.train;
    }
    if (name.contains('bus')) {
      return Icons.directions_bus;
    }
    if (name.contains('taxi') || name.contains('ride') || name.contains('uber') || name.contains('bolt') || name.contains('grab')) {
      return Icons.local_taxi;
    }
    if (name.contains('fuel') || name.contains('gas')) {
      return Icons.local_gas_station;
    }
    if (name.contains('parking')) {
      return Icons.local_parking;
    }
    if (name.contains('metro') || name.contains('subway')) {
      return Icons.subway;
    }
    if (name.contains('transport') || name.contains('travel')) {
      return Icons.directions_car;
    }
    if (name.contains('train')) {
      return Icons.train;
    }
    if (name.contains('bus')) {
      return Icons.directions_bus;
    }
    if (name.contains('taxi') || name.contains('ride') || name.contains('uber') || name.contains('bolt') || name.contains('grab')) {
      return Icons.local_taxi;
    }
    if (name.contains('fuel') || name.contains('gas')) {
      return Icons.local_gas_station;
    }
    if (name.contains('parking')) {
      return Icons.local_parking;
    }
    if (name.contains('metro') || name.contains('subway')) {
      return Icons.subway;
    }
    
    // Accommodation
    if (name.contains('accommodation') || name.contains('hotel') || name.contains('hostel') || name.contains('airbnb')) {
      return Icons.hotel;
    }
    if (name.contains('camping')) {
      return Icons.forest;
    }
    
    // Activities & Entertainment
    if (name.contains('activity') || name.contains('entertainment')) {
      return Icons.sports_esports;
    }
    if (name.contains('movie') || name.contains('cinema')) {
      return Icons.movie;
    }
    if (name.contains('music') || name.contains('concert')) {
      return Icons.music_note;
    }
    if (name.contains('sport') || name.contains('gym') || name.contains('fitness')) {
      return Icons.fitness_center;
    }
    if (name.contains('museum') || name.contains('gallery')) {
      return Icons.museum;
    }
    if (name.contains('park') || name.contains('attraction')) {
      return Icons.park;
    }
    
    // Shopping
    if (name.contains('shopping') || name.contains('store')) {
      return Icons.shopping_bag;
    }
    if (name.contains('souvenir')) {
      return Icons.card_giftcard;
    }
    if (name.contains('clothing') || name.contains('clothes')) {
      return Icons.checkroom;
    }
    
    // Health & Medical
    if (name.contains('health') || name.contains('medical') || name.contains('pharmacy')) {
      return Icons.local_pharmacy;
    }
    if (name.contains('doctor') || name.contains('hospital')) {
      return Icons.medical_services;
    }
    
    // Communication
    if (name.contains('communication') || name.contains('phone') || name.contains('internet') || name.contains('wifi')) {
      return Icons.phone_android;
    }
    if (name.contains('sim') || name.contains('data')) {
      return Icons.sim_card;
    }
    
    // Banking & Fees
    if (name.contains('banking') || name.contains('fee') || name.contains('atm')) {
      return Icons.account_balance;
    }
    if (name.contains('exchange') || name.contains('currency')) {
      return Icons.currency_exchange;
    }
    
    // Tips & Gratuities
    if (name.contains('tip') || name.contains('gratuity')) {
      return Icons.attach_money;
    }
    
    // Travel Essentials
    if (name.contains('travel') && name.contains('essential')) {
      return Icons.luggage;
    }
    if (name.contains('insurance')) {
      return Icons.security;
    }
    if (name.contains('visa') || name.contains('document')) {
      return Icons.description;
    }
    
    // Miscellaneous
    if (name.contains('other') || name.contains('misc')) {
      return Icons.category;
    }
    if (name.contains('uncategorized')) {
      return Icons.help_outline;
    }
    
    // Default
    return Icons.category;
  }
  
  /// Maps subcategory names to Material Icons
  static IconData? getIconForSubcategory(String subcategoryName) {
    final name = subcategoryName.toLowerCase();
    
    // Food subcategories
    if (name.contains('restaurant')) return Icons.restaurant;
    if (name.contains('fast food')) return Icons.fastfood;
    if (name.contains('street food')) return Icons.streetview;
    if (name.contains('cafe') || name.contains('coffee')) return Icons.local_cafe;
    if (name.contains('bar') || name.contains('pub')) return Icons.local_bar;
    if (name.contains('alcohol')) return Icons.wine_bar;
    if (name.contains('grocery')) return Icons.shopping_cart;
    if (name.contains('snack')) return Icons.cookie;
    if (name.contains('breakfast')) return Icons.free_breakfast;
    if (name.contains('lunch')) return Icons.lunch_dining;
    if (name.contains('dinner')) return Icons.dinner_dining;
    if (name.contains('delivery')) return Icons.delivery_dining;
    
    // Transport subcategories - Check flight first
    if (name.contains('flight') || name.contains('airplane') || name.contains('airline')) return Icons.flight;
    if (name.contains('train')) return Icons.train;
    if (name.contains('bus')) return Icons.directions_bus;
    if (name.contains('taxi') || name.contains('ride') || name.contains('uber') || name.contains('bolt') || name.contains('grab')) {
      return Icons.local_taxi;
    }
    if (name.contains('car rental')) return Icons.car_rental;
    if (name.contains('fuel') || name.contains('gas')) return Icons.local_gas_station;
    if (name.contains('parking')) return Icons.local_parking;
    if (name.contains('metro') || name.contains('subway')) return Icons.subway;
    if (name.contains('ferry') || name.contains('boat')) return Icons.directions_boat;
    if (name.contains('airport')) return Icons.airport_shuttle;
    if (name.contains('bike') || name.contains('scooter')) return Icons.two_wheeler;
    
    // Accommodation subcategories
    if (name.contains('hotel')) return Icons.hotel;
    if (name.contains('hostel')) return Icons.bed;
    if (name.contains('airbnb')) return Icons.home;
    if (name.contains('resort')) return Icons.beach_access;
    if (name.contains('camping')) return Icons.forest;
    if (name.contains('apartment') || name.contains('villa')) return Icons.apartment;
    
    // Shopping subcategories
    if (name.contains('souvenir')) return Icons.card_giftcard;
    if (name.contains('clothing') || name.contains('clothes')) return Icons.checkroom;
    if (name.contains('electronics')) return Icons.devices;
    
    // Health subcategories
    if (name.contains('pharmacy')) return Icons.local_pharmacy;
    if (name.contains('doctor') || name.contains('hospital')) return Icons.medical_services;
    
    // Communication subcategories
    if (name.contains('sim') || name.contains('data')) return Icons.sim_card;
    if (name.contains('wifi') || name.contains('internet')) return Icons.wifi;
    
    // Banking subcategories
    if (name.contains('atm')) return Icons.atm;
    if (name.contains('exchange')) return Icons.currency_exchange;
    
    // Default to category icon
    return Icons.category;
  }
  
  /// Get color for category
  static Color getColorForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    
    if (name.contains('food') || name.contains('dining')) return Colors.orange;
    if (name.contains('transport') || name.contains('travel')) return Colors.blue;
    if (name.contains('accommodation') || name.contains('hotel')) return Colors.purple;
    if (name.contains('activity') || name.contains('entertainment')) return Colors.pink;
    if (name.contains('shopping')) return Colors.teal;
    if (name.contains('health') || name.contains('medical')) return Colors.red;
    if (name.contains('communication')) return Colors.green;
    if (name.contains('banking') || name.contains('fee')) return Colors.indigo;
    if (name.contains('tip')) return Colors.amber;
    if (name.contains('other') || name.contains('misc')) return Colors.grey;
    
    return Colors.blueGrey;
  }
}

