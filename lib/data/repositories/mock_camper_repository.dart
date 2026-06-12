import '../models/camper_place.dart';
import '../models/checklist_item.dart';
import '../models/journal_entry.dart';
import '../models/trip_plan.dart';

abstract final class MockCamperRepository {
  static const places = <CamperPlace>[
    CamperPlace(
      name: 'Quiet lakeside camper area',
      type: 'Aire',
      distance: '8.4 km',
      rating: '4.8',
      tags: ['24h', 'Water', 'Shade', 'Pets'],
    ),
    CamperPlace(
      name: 'Mountain pass stop',
      type: 'Free parking',
      distance: '12 km',
      rating: '4.6',
      tags: ['Quiet', 'No height limit', 'Sunrise'],
    ),
    CamperPlace(
      name: 'Service point',
      type: 'Water and dump',
      distance: '4 km',
      rating: '4.2',
      tags: ['Fresh water', 'Grey water', 'Easy access'],
    ),
  ];

  static const trips = <TripPlan>[
    TripPlan(
      title: 'Dolomites long weekend',
      summary: '3 days - 412 km - estimated cost EUR 148',
      progress: 0.55,
    ),
    TripPlan(
      title: 'Lake Garda slow loop',
      summary: '5 days - 287 km - 4 saved overnight stops',
      progress: 0.24,
    ),
  ];

  static const checklist = <CamperChecklistItem>[
    CamperChecklistItem(
      title: 'Fresh water filled',
      checked: true,
      subtitle: 'Target at least 80 percent before departure',
    ),
    CamperChecklistItem(
      title: 'Gas bottle checked',
      checked: true,
      subtitle: 'Confirm reserve bottle and adapter',
    ),
    CamperChecklistItem(
      title: 'Fridge on travel mode',
      checked: false,
    ),
    CamperChecklistItem(
      title: 'Documents and insurance',
      checked: true,
    ),
    CamperChecklistItem(
      title: 'Tire pressure checked',
      checked: false,
    ),
  ];

  static const journal = <JournalEntry>[
    JournalEntry(
      title: 'Sunset near the lake',
      summary: 'Day 2 - 128 km - clear evening',
    ),
    JournalEntry(
      title: 'First mountain breakfast',
      summary: 'Day 3 - 64 km - cold morning',
    ),
  ];
}
