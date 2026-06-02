class Project {
  final String id;
  final String type;
  final String location;
  final double plotSize;
  final double budget;
  final String timeline;
  final String currentStage;
  
  Project({
    required this.id,
    required this.type,
    required this.location,
    required this.plotSize,
    required this.budget,
    required this.timeline,
    required this.currentStage,
  });
}

class Quote {
  final String id;
  final String providerId;
  final String providerName;
  final double estimatedCost;
  final String timeline;
  final String notes;

  Quote({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.estimatedCost,
    required this.timeline,
    required this.notes,
  });
}
