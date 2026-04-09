import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/bean.dart';
import '../models/brew.dart';
import '../models/tasting_note.dart';

class AiService {
  static const String _baseUrl = 'https://api.bean.ai/v1';
  String? _apiKey;

  AiService({String? apiKey}) : _apiKey = apiKey;

  void setApiKey(String key) => _apiKey = key;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
  };

  Future<Map<String, dynamic>> analyzeBeanImage(String imagePath) async {
    // In production, this sends the image to a vision model (GPT-4V, Gemini Pro Vision)
    // to extract bean information from the bag/label
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/scan/analyze'),
        headers: _headers,
        body: jsonEncode({
          'image': imagePath,
          'extract': [
            'brand',
            'name',
            'origin',
            'roast_level',
            'varietal',
            'process',
            'tasting_notes',
            'roast_date',
            'weight',
            'price',
          ],
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw AiServiceException('Failed to analyze image: ${response.statusCode}');
    } catch (e) {
      // Fallback with mock data for development
      return _mockBeanAnalysis();
    }
  }

  Future<Map<String, dynamic>> generateBrewRecipe({
    required Bean bean,
    required String method,
    String? grinder,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/brew/recipe'),
        headers: _headers,
        body: jsonEncode({
          'bean': {
            'origin': bean.origin,
            'roast_level': bean.roastLevel,
            'process': bean.process,
            'varietal': bean.varietal,
            'days_from_roast': bean.daysFromRoast,
            'tasting_notes': bean.tastingNotes,
          },
          'method': method,
          'grinder': grinder,
          'preferences': preferences,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw AiServiceException('Failed to generate recipe: ${response.statusCode}');
    } catch (e) {
      return _mockBrewRecipe(bean, method);
    }
  }

  Future<Map<String, dynamic>> analyzeBrewFeedback({
    required Brew brew,
    required Bean bean,
    required double rating,
    String? issue,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/brew/feedback'),
        headers: _headers,
        body: jsonEncode({
          'brew': brew.toJson(),
          'bean': {
            'origin': bean.origin,
            'roast_level': bean.roastLevel,
            'process': bean.process,
          },
          'rating': rating,
          'issue': issue,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw AiServiceException('Failed to analyze brew: ${response.statusCode}');
    } catch (e) {
      return _mockBrewFeedback(brew, rating);
    }
  }

  Future<Map<String, dynamic>> generatePalateInsights({
    required List<TastingNote> notes,
    required List<Bean> beans,
    required List<Brew> brews,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/insights/palate'),
        headers: _headers,
        body: jsonEncode({
          'notes': notes.map((n) => n.toJson()).toList(),
          'bean_count': beans.length,
          'brew_count': brews.length,
          'avg_rating': brews.isEmpty
              ? 0
              : brews.map((b) => b.rating).reduce((a, b) => a + b) /
                  brews.length,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw AiServiceException('Insights generation failed');
    } catch (e) {
      return _mockPalateInsights();
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendations({
    required List<Bean> likedBeans,
    required List<String> preferredFlavors,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/discover/recommend'),
        headers: _headers,
        body: jsonEncode({
          'liked_beans': likedBeans
              .map((b) => {
                'origin': b.origin,
                'roast': b.roastLevel,
                'process': b.process,
                'rating': b.rating,
              })
              .toList(),
          'preferred_flavors': preferredFlavors,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['recommendations'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
      throw AiServiceException('Recommendations failed');
    } catch (e) {
      return _mockRecommendations();
    }
  }

  Future<String> getBrewCoaching(String question) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/coaching/ask'),
        headers: _headers,
        body: jsonEncode({'question': question}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['answer'] as String;
      }
      throw AiServiceException('Coaching failed');
    } catch (e) {
      return 'Try adjusting your grind size finer and water temperature to 93°C. '
          'For this bean, a 1:16 ratio with a 2:30 brew time should help balance the flavors.';
    }
  }

  // Development mock responses
  Map<String, dynamic> _mockBeanAnalysis() => {
    'name': 'Yirgacheffe Single Origin',
    'roaster': 'Onyx Coffee Lab',
    'origin': 'Ethiopia',
    'region': 'Yirgacheffe, Gedeo Zone',
    'varietal': 'Heirloom',
    'process': 'Washed',
    'roastLevel': 'Light',
    'tastingNotes': ['Jasmine', 'Bergamot', 'Peach', 'Honey'],
    'description': 'A stunning washed Ethiopian with delicate floral notes '
        'and stone fruit sweetness.',
    'elevation': 1950.0,
    'confidence': 0.92,
  };

  Map<String, dynamic> _mockBrewRecipe(Bean bean, String method) {
    final isEspresso = method.toLowerCase().contains('espresso');
    return {
      'dose_grams': isEspresso ? 18.0 : 15.0,
      'water_ml': isEspresso ? 36.0 : 250.0,
      'ratio': isEspresso ? '1:2' : '1:16.5',
      'water_temp_celsius': bean.roastLevel == 'Light' ? 96.0 : 93.0,
      'grind_setting': isEspresso ? 8 : 22,
      'brew_time_seconds': isEspresso ? 28 : 180,
      'bloom_time_seconds': isEspresso ? 0 : 30,
      'bloom_water_ml': isEspresso ? 0 : 45,
      'instructions': [
        if (!isEspresso) 'Rinse filter with hot water',
        'Add ${isEspresso ? "18g" : "15g"} of freshly ground coffee',
        if (!isEspresso)
          'Bloom with 45ml water for 30 seconds, stir gently'
        else
          'Distribute evenly and tamp flat',
        if (!isEspresso)
          'Pour in slow concentric circles to 250ml total'
        else
          'Extract for 25-30 seconds',
        if (!isEspresso) 'Target total brew time: 3:00',
        'Enjoy the ${bean.tastingNotes.take(2).join(" and ")} notes!',
      ],
      'tips': [
        'This ${bean.origin} ${bean.process} works well with '
            '${bean.roastLevel == "Light" ? "higher" : "standard"} temperatures',
        if (bean.daysFromRoast > 0 && bean.daysFromRoast < 7)
          'Bean is fresh—consider a slightly coarser grind',
        if (bean.daysFromRoast > 21)
          'Bean is aging—try grinding finer to extract more sweetness',
      ],
    };
  }

  Map<String, dynamic> _mockBrewFeedback(Brew brew, double rating) => {
    'overall': rating >= 4
        ? 'Great brew! Your parameters are well-dialed for this bean.'
        : 'Here are some adjustments to improve your next cup.',
    'adjustments': [
      if (rating < 4 && brew.waterTempCelsius < 94)
        {'parameter': 'temperature', 'suggestion': 'Try increasing to 94-96°C for better extraction'},
      if (rating < 4)
        {'parameter': 'grind', 'suggestion': 'Adjust 1-2 clicks finer for more sweetness'},
      if (brew.ratio > 17)
        {'parameter': 'ratio', 'suggestion': 'Your ratio is quite high—try 1:16 for more body'},
    ],
    'pattern_note': 'Based on your history, you tend to prefer brews at 93-94°C '
        'with a 1:15-1:16 ratio.',
  };

  Map<String, dynamic> _mockPalateInsights() => {
    'summary': 'You gravitate toward bright, fruity coffees with clean finishes. '
        'African origins make up 60% of your highest-rated beans.',
    'top_origins': ['Ethiopia', 'Kenya', 'Colombia'],
    'preferred_flavors': ['Fruity', 'Floral', 'Sweet'],
    'avg_acidity_preference': 4.2,
    'avg_body_preference': 3.5,
    'brew_consistency': 0.78,
    'trend': 'Your brewing has improved 15% over the last month—keep dialing in!',
    'suggestion': 'Try a natural process Colombian for a sweeter, fruitier twist '
        'on your usual favorites.',
  };

  List<Map<String, dynamic>> _mockRecommendations() => [
    {
      'name': 'Burundi Kibira Natural',
      'roaster': 'Passenger Coffee',
      'origin': 'Burundi',
      'tasting_notes': ['Raspberry', 'Dark Chocolate', 'Plum'],
      'match_score': 0.94,
      'reason': 'Similar to your highly-rated Kenyan naturals',
    },
    {
      'name': 'Guatemala Huehuetenango',
      'roaster': 'Counter Culture',
      'origin': 'Guatemala',
      'tasting_notes': ['Caramel', 'Orange', 'Toffee'],
      'match_score': 0.89,
      'reason': 'Sweet and balanced—matches your preference for clean cups',
    },
    {
      'name': 'Panama Gesha Washed',
      'roaster': 'Sey Coffee',
      'origin': 'Panama',
      'tasting_notes': ['Jasmine', 'Bergamot', 'Tropical Fruit'],
      'match_score': 0.87,
      'reason': 'You love floral Ethiopian profiles—this Gesha will wow you',
    },
  ];
}

class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);

  @override
  String toString() => 'AiServiceException: $message';
}
