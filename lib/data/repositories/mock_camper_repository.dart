import '../models/camper_place.dart';
import '../models/checklist_item.dart';
import '../models/journal_entry.dart';
import '../models/trip_plan.dart';

abstract final class MockCamperRepository {
  static const places = <CamperPlace>[
    CamperPlace(
      name: 'Area Sosta Lago',
      category: 'sosta',
      type: 'Sosta camper',
      distance: '8.4 km',
      rating: '4.8',
      tags: ['24h', 'Pets'],
      latitude: 45.6049,
      longitude: 10.6351,
      address: 'Via del Porto 12',
      city: 'Peschiera del Garda',
      services: ['Carico acqua', 'Scarico', 'Elettricita'],
      source: 'Dataset locale POI',
    ),
    CamperPlace(
      name: 'Camping Bella Vista',
      category: 'camping',
      type: 'Camping',
      distance: '12 km',
      rating: '4.6',
      tags: ['Docce', 'Market'],
      latitude: 45.623,
      longitude: 10.728,
      address: 'Strada Panoramica 4',
      city: 'Lazise',
      services: ['Piazzole', 'Docce', 'Lavanderia'],
      source: 'Dataset locale POI',
    ),
    CamperPlace(
      name: 'Parcheggio Centro',
      category: 'parcheggio',
      type: 'Parcheggio',
      distance: '4 km',
      rating: '4.2',
      tags: ['Bus', 'Centro'],
      latitude: 45.439,
      longitude: 10.991,
      address: 'Piazzale Europa 2',
      city: 'Verona',
      services: ['Parcheggio giornaliero', 'Navetta'],
      source: 'Dataset locale POI',
    ),
    CamperPlace(
      name: 'Punto Acqua Nord',
      category: 'acqua',
      type: 'Acqua',
      distance: '6 km',
      rating: '4.4',
      tags: ['Acqua potabile'],
      latitude: 45.563,
      longitude: 10.544,
      address: 'Via Gardesana 18',
      city: 'Bardolino',
      services: ['Acqua potabile'],
      source: 'Dataset locale POI',
    ),
    CamperPlace(
      name: 'Scarico Sud',
      category: 'scarico',
      type: 'Scarico',
      distance: '9 km',
      rating: '4.3',
      tags: ['Grigie', 'Nere'],
      latitude: 45.482,
      longitude: 10.689,
      address: 'Via Servizi 7',
      city: 'Desenzano del Garda',
      services: ['Scarico acque grigie', 'Scarico wc chimico'],
      source: 'Dataset locale POI',
    ),
    CamperPlace(
      name: 'GPL Service Ovest',
      category: 'gpl',
      type: 'GPL',
      distance: '11 km',
      rating: '4.5',
      tags: ['GPL', '24h'],
      latitude: 45.547,
      longitude: 10.481,
      address: 'Tangenziale Ovest 21',
      city: 'Peschiera del Garda',
      services: ['GPL', 'Aria gomme'],
      source: 'Dataset locale POI',
    ),
    CamperPlace(
      name: 'Officina Camper Help',
      category: 'assistenza',
      type: 'Assistenza',
      distance: '14 km',
      rating: '4.7',
      tags: ['Officina', 'Ricambi'],
      latitude: 45.515,
      longitude: 10.612,
      address: 'Via Artigiani 3',
      city: 'Sirmione',
      services: ['Officina camper', 'Ricambi', 'Elettrauto'],
      source: 'Dataset locale POI',
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
