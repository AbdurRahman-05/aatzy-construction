
class ProjectProgressResult {
  final double progressValue; // 0.0 to 1.0
  final int percentage; // 0 to 100
  final String progressText; // e.g. "50% Done"
  final String stageDisplayName; // e.g. "Tracking", "Design & Planning"
  final int completedTasksCount;
  final int totalTasksCount;

  const ProjectProgressResult({
    required this.progressValue,
    required this.percentage,
    required this.progressText,
    required this.stageDisplayName,
    required this.completedTasksCount,
    required this.totalTasksCount,
  });
}

class ProjectProgressHelper {
  /// Calculates the project completion progress based on its live stage,
  /// task completion status, and quote milestones.
  ///
  /// Stages lifecycle in construction:
  /// 1. Planning (15% - 20%)
  /// 2. Design & Planning (25% - 40%)
  /// 3. Tracking / Execution (50% - 90% scaled with task completion)
  /// 4. Finished Pending Approval (95%)
  /// 5. Completed / Finished (100%)
  static ProjectProgressResult calculate({
    required String? stage,
    List<dynamic>? tasks,
    int? quotesCount,
    bool? hasAcceptedQuote,
  }) {
    final rawStage = (stage ?? 'Planning').trim();
    final stageLower = rawStage.toLowerCase();

    final tasksList = tasks ?? [];
    final totalTasks = tasksList.length;
    final completedTasks = tasksList.where((t) {
      final status = (t['status'] ?? '').toString().toLowerCase().trim();
      return status == 'completed';
    }).length;

    final hasQuotes = (quotesCount ?? 0) > 0;
    final isQuoteAccepted = hasAcceptedQuote == true;

    final isCancelled = stageLower == 'cancelled';
    final isCompleted = stageLower == 'completed' || stageLower == 'finished';
    final isPendingApproval = stageLower == 'finished pending approval' ||
        stageLower.contains('pending approval');
    final isExecution = stageLower.contains('track') ||
        stageLower.contains('execut') ||
        stageLower == 'on hold' ||
        isQuoteAccepted;
    final isDesign = stageLower.contains('design');
    final isPlanning = stageLower == 'planning';

    double progress;

    if (isCancelled) {
      progress = 0.15;
    } else if (isCompleted) {
      progress = 1.0;
    } else if (isPendingApproval) {
      progress = 0.95;
    } else if (isExecution) {
      // Base progress for Execution is 50% because Planning (25%) & Design (25%) are complete.
      // Execution tasks advance progress from 50% up to 90% (a 40% span).
      if (totalTasks > 0) {
        final taskRatio = (completedTasks / totalTasks).clamp(0.0, 1.0);
        progress = 0.50 + (0.40 * taskRatio);
      } else {
        progress = 0.50;
      }
    } else if (isDesign) {
      // Planning (25%) is done. Design phase progresses between 25% and 45%.
      if (totalTasks > 0) {
        final taskRatio = (completedTasks / totalTasks).clamp(0.0, 1.0);
        progress = 0.25 + (0.20 * taskRatio);
      } else if (hasQuotes) {
        // Quotes received from providers for architectural design/execution
        progress = 0.35;
      } else {
        progress = 0.25;
      }
    } else if (isPlanning) {
      progress = hasQuotes ? 0.20 : 0.15;
    } else {
      // Default fallback
      progress = 0.25;
    }

    // Clamp value between 0.0 and 1.0
    progress = progress.clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

    String progressText;
    if (isCancelled) {
      progressText = 'Cancelled';
    } else if (isCompleted) {
      progressText = '100% Done';
    } else {
      progressText = '$percentage% Done';
    }

    return ProjectProgressResult(
      progressValue: progress,
      percentage: percentage,
      progressText: progressText,
      stageDisplayName: rawStage.isEmpty ? 'Planning' : rawStage,
      completedTasksCount: completedTasks,
      totalTasksCount: totalTasks,
    );
  }

  /// Convenience method accepting a dynamic Project map/object
  static ProjectProgressResult calculateFromProject(dynamic project) {
    if (project == null || project is! Map) {
      return const ProjectProgressResult(
        progressValue: 0.25,
        percentage: 25,
        progressText: '25% Done',
        stageDisplayName: 'Planning',
        completedTasksCount: 0,
        totalTasksCount: 0,
      );
    }

    final stage = project['currentStage']?.toString();
    final tasks = project['tasks'] as List<dynamic>?;
    final quotes = project['quotes'] as List<dynamic>?;
    final countQuotes = project['_count']?['quotes'] as int?;
    final quotesCount = countQuotes ?? quotes?.length ?? 0;
    final hasAcceptedQuote = quotes?.any((q) => q['isAccepted'] == true) ?? false;

    return calculate(
      stage: stage,
      tasks: tasks,
      quotesCount: quotesCount,
      hasAcceptedQuote: hasAcceptedQuote,
    );
  }
}
