import 'package:flutter_test/flutter_test.dart';

import 'package:bean_ai/models/bean.dart';
import 'package:bean_ai/models/brew.dart';
import 'package:bean_ai/models/tasting_note.dart';

void main() {
  group('Bean Model', () {
    test('creates bean with defaults', () {
      final bean = Bean(
        name: 'Test Ethiopian',
        roaster: 'Test Roasters',
        origin: 'Ethiopia',
      );

      expect(bean.name, 'Test Ethiopian');
      expect(bean.roaster, 'Test Roasters');
      expect(bean.origin, 'Ethiopia');
      expect(bean.process, 'Washed');
      expect(bean.roastLevel, 'Medium');
      expect(bean.rating, 0);
      expect(bean.brewCount, 0);
      expect(bean.isFavorite, false);
      expect(bean.isArchived, false);
      expect(bean.id, isNotEmpty);
    });

    test('calculates freshness correctly', () {
      final peakBean = Bean(
        name: 'Peak Bean',
        roaster: 'Test',
        origin: 'Colombia',
        roastDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(peakBean.freshnessLevel, FreshnessLevel.peak);
      expect(peakBean.freshnessLabel, 'Peak');

      final agingBean = Bean(
        name: 'Aging Bean',
        roaster: 'Test',
        origin: 'Brazil',
        roastDate: DateTime.now().subtract(const Duration(days: 25)),
      );
      expect(agingBean.freshnessLevel, FreshnessLevel.aging);

      final staleBean = Bean(
        name: 'Stale Bean',
        roaster: 'Test',
        origin: 'Kenya',
        roastDate: DateTime.now().subtract(const Duration(days: 35)),
      );
      expect(staleBean.freshnessLevel, FreshnessLevel.stale);
    });

    test('calculates cost per cup', () {
      final bean = Bean(
        name: 'Priced Bean',
        roaster: 'Test',
        origin: 'Guatemala',
        price: 18.0,
        weightGrams: 340.0,
      );

      expect(bean.costPerCup, isNotNull);
      expect(bean.costPerCup!, closeTo(0.953, 0.01));
    });

    test('serializes and deserializes to JSON', () {
      final bean = Bean(
        name: 'JSON Bean',
        roaster: 'Serializer Co.',
        origin: 'Peru',
        roastLevel: 'Light',
        process: 'Natural',
        tastingNotes: ['Berry', 'Citrus'],
        price: 22.0,
        weightGrams: 250.0,
      );

      final json = bean.toJson();
      final restored = Bean.fromJson(json);

      expect(restored.name, bean.name);
      expect(restored.roaster, bean.roaster);
      expect(restored.origin, bean.origin);
      expect(restored.roastLevel, bean.roastLevel);
      expect(restored.process, bean.process);
      expect(restored.tastingNotes, bean.tastingNotes);
      expect(restored.price, bean.price);
      expect(restored.id, bean.id);
    });

    test('copyWith preserves unchanged fields', () {
      final original = Bean(
        name: 'Original',
        roaster: 'Test',
        origin: 'Ethiopia',
        rating: 4.5,
      );

      final updated = original.copyWith(name: 'Updated');

      expect(updated.name, 'Updated');
      expect(updated.roaster, 'Test');
      expect(updated.origin, 'Ethiopia');
      expect(updated.rating, 4.5);
      expect(updated.id, original.id);
    });
  });

  group('Brew Model', () {
    test('creates brew with defaults', () {
      final brew = Brew(
        beanId: 'test-bean-id',
        method: 'Pour Over (V60)',
        doseGrams: 15,
        waterMl: 250,
      );

      expect(brew.beanId, 'test-bean-id');
      expect(brew.method, 'Pour Over (V60)');
      expect(brew.doseGrams, 15);
      expect(brew.waterMl, 250);
      expect(brew.waterTempCelsius, 93);
    });

    test('calculates ratio', () {
      final brew = Brew(
        beanId: 'test',
        method: 'V60',
        doseGrams: 15,
        waterMl: 250,
      );

      expect(brew.ratio, closeTo(16.67, 0.01));
      expect(brew.ratioLabel, '1:16.7');
    });

    test('formats brew time', () {
      final brew = Brew(
        beanId: 'test',
        method: 'V60',
        doseGrams: 15,
        waterMl: 250,
        brewTime: const Duration(minutes: 3, seconds: 15),
      );

      expect(brew.brewTimeLabel, '3:15');
    });

    test('serializes and deserializes', () {
      final brew = Brew(
        beanId: 'bean-123',
        method: 'Espresso',
        doseGrams: 18,
        waterMl: 36,
        waterTempCelsius: 93,
        grindSetting: 8,
        rating: 4.0,
      );

      final json = brew.toJson();
      final restored = Brew.fromJson(json);

      expect(restored.beanId, brew.beanId);
      expect(restored.method, brew.method);
      expect(restored.doseGrams, brew.doseGrams);
      expect(restored.waterMl, brew.waterMl);
      expect(restored.rating, brew.rating);
      expect(restored.id, brew.id);
    });
  });

  group('TastingNote Model', () {
    test('creates note with defaults', () {
      final note = TastingNote(
        beanId: 'bean-id',
        overallScore: 8.5,
        aroma: 8,
        acidity: 7,
        sweetness: 9,
        body: 6,
        balance: 8,
        aftertaste: 7,
        cleanliness: 8,
        descriptors: ['Jasmine', 'Peach'],
      );

      expect(note.overallScore, 8.5);
      expect(note.descriptors.length, 2);
      expect(note.radarData.length, 7);
    });

    test('radar data contains all attributes', () {
      final note = TastingNote(
        aroma: 8,
        acidity: 7,
        sweetness: 9,
        body: 6,
        balance: 8,
        aftertaste: 7,
        cleanliness: 8,
      );

      final radar = note.radarData;
      expect(radar['Aroma'], 8);
      expect(radar['Acidity'], 7);
      expect(radar['Sweetness'], 9);
      expect(radar['Body'], 6);
      expect(radar['Balance'], 8);
      expect(radar['Aftertaste'], 7);
      expect(radar['Clean'], 8);
    });
  });
}
