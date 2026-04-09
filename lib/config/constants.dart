class AppConstants {
  static const String appName = 'Bean.ai';
  static const String appTagline = 'Your AI Coffee Companion';
  static const String appVersion = '1.0.0';

  static const double monthlyPrice = 4.99;
  static const double yearlyPrice = 49.00;
  static const double lifetimePrice = 99.00;

  static const int freeScansLimit = 10;
  static const int freeBrewLogsLimit = 20;
  static const int freeBeansLimit = 5;

  static const String monthlyProductId = 'bean_ai_monthly';
  static const String yearlyProductId = 'bean_ai_yearly';
  static const String lifetimeProductId = 'bean_ai_lifetime';

  static const Duration freshnessDuration = Duration(days: 21);
  static const Duration stalenessWarning = Duration(days: 14);

  static const List<String> roastLevels = [
    'Light',
    'Medium-Light',
    'Medium',
    'Medium-Dark',
    'Dark',
  ];

  static const List<String> brewMethods = [
    'Pour Over (V60)',
    'Chemex',
    'AeroPress',
    'French Press',
    'Espresso',
    'Moka Pot',
    'Cold Brew',
    'Drip/Filter',
    'Siphon',
    'Turkish',
    'Clever Dripper',
    'Kalita Wave',
  ];

  static const List<String> grinders = [
    'Comandante C40',
    'Baratza Encore',
    'Baratza Virtuoso+',
    'Fellow Ode',
    'Niche Zero',
    'Eureka Mignon',
    'Timemore C2',
    'Hario Skerton',
    '1Zpresso JX',
    '1Zpresso K-Plus',
    'Mazzer Mini',
    'Other',
  ];

  static const List<String> origins = [
    'Ethiopia',
    'Colombia',
    'Brazil',
    'Kenya',
    'Guatemala',
    'Costa Rica',
    'Peru',
    'Indonesia',
    'Honduras',
    'Rwanda',
    'Panama',
    'Yemen',
    'Mexico',
    'India',
    'Burundi',
    'El Salvador',
    'Nicaragua',
    'Tanzania',
    'Uganda',
    'Blend',
  ];

  static const List<String> processes = [
    'Washed',
    'Natural',
    'Honey',
    'Anaerobic',
    'Wet-Hulled',
    'Carbonic Maceration',
    'Double Fermented',
    'Experimental',
  ];

  static const List<String> flavorCategories = [
    'Fruity',
    'Floral',
    'Sweet',
    'Nutty',
    'Chocolatey',
    'Spicy',
    'Roasty',
    'Herbal',
    'Savory',
    'Fermented',
  ];

  static const Map<String, List<String>> flavorWheel = {
    'Fruity': [
      'Berry', 'Citrus', 'Stone Fruit', 'Tropical', 'Apple',
      'Grape', 'Cherry', 'Blueberry', 'Raspberry', 'Lemon',
      'Orange', 'Grapefruit', 'Peach', 'Plum', 'Mango',
      'Pineapple', 'Passion Fruit', 'Dried Fruit',
    ],
    'Floral': [
      'Jasmine', 'Rose', 'Lavender', 'Chamomile', 'Hibiscus',
      'Orange Blossom', 'Elderflower',
    ],
    'Sweet': [
      'Caramel', 'Honey', 'Brown Sugar', 'Maple', 'Molasses',
      'Vanilla', 'Toffee', 'Butterscotch', 'Cane Sugar',
    ],
    'Nutty': [
      'Almond', 'Hazelnut', 'Peanut', 'Walnut', 'Cashew',
      'Pecan', 'Macadamia', 'Coconut',
    ],
    'Chocolatey': [
      'Dark Chocolate', 'Milk Chocolate', 'Cocoa', 'Cacao Nib',
      'White Chocolate', 'Mocha',
    ],
    'Spicy': [
      'Cinnamon', 'Clove', 'Nutmeg', 'Black Pepper', 'Cardamom',
      'Ginger', 'Anise',
    ],
    'Roasty': [
      'Smoky', 'Ashy', 'Toasty', 'Charred', 'Pipe Tobacco',
      'Burnt Sugar',
    ],
    'Herbal': [
      'Tea-like', 'Mint', 'Basil', 'Sage', 'Thyme',
      'Eucalyptus', 'Grassy',
    ],
    'Savory': [
      'Tomato', 'Olive', 'Umami', 'Brothy', 'Leather',
    ],
    'Fermented': [
      'Wine-like', 'Winey', 'Boozy', 'Vinous', 'Yeasty',
      'Kombucha',
    ],
  };
}
