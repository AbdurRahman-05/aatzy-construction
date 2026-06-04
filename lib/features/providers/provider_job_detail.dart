import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../core/constants.dart';
import '../../core/wallpaper_background.dart';
import '../chat/chat_detail_screen.dart';

class Worker {
  final String id;
  final String name;
  final String role;
  final double dailyWage;
  bool isPresentToday;
  int daysPresent;
  double amountPaid;

  Worker({
    required this.id,
    required this.name,
    required this.role,
    required this.dailyWage,
    this.isPresentToday = false,
    this.daysPresent = 0,
    this.amountPaid = 0.0,
  });

  double get totalEarned => daysPresent * dailyWage;
  double get remainingSalary => totalEarned - amountPaid;
}

class ProviderJobDetail extends ConsumerStatefulWidget {
  final String projectId;
  const ProviderJobDetail({super.key, required this.projectId});

  @override
  ConsumerState<ProviderJobDetail> createState() => _ProviderJobDetailState();
}

class _ProviderJobDetailState extends ConsumerState<ProviderJobDetail> {
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Pending, 1: Ongoing, 2: Finished, 3: Financials, 4: Workers, 5: Daily Logs
  final ImagePicker _picker = ImagePicker();
  List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();
    _initializeWorkers();
    _fetchProjectDetails();
  }

  void _initializeWorkers() {
    if (_workers.isEmpty) {
      _workers = [
        Worker(id: 'w1', name: 'Rajesh Kumar', role: 'Mason (Lead)', dailyWage: 25.0, daysPresent: 12, amountPaid: 200.0, isPresentToday: true),
        Worker(id: 'w2', name: 'Amit Singh', role: 'Helper Labor', dailyWage: 15.0, daysPresent: 10, amountPaid: 150.0, isPresentToday: true),
        Worker(id: 'w3', name: 'Sunil Verma', role: 'Carpenter', dailyWage: 22.0, daysPresent: 8, amountPaid: 100.0, isPresentToday: false),
        Worker(id: 'w4', name: 'Vijay Yadav', role: 'Plumber', dailyWage: 20.0, daysPresent: 5, amountPaid: 100.0, isPresentToday: false),
      ];
    }
  }

  Future<void> _fetchProjectDetails() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/projects/${widget.projectId}'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _project = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching project: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateTemplateTasks() async {
    final typeString = _project?['type'] as String? ?? '';
    final services = typeString.split(',').map((s) => s.trim().toLowerCase()).toList();

    List<Map<String, dynamic>> templateTasks = [];

    // Add kickoff task
    templateTasks.add({
      'stage': 'Initial Phase',
      'title': 'Project Kickoff & Site Survey',
      'duration': 3,
    });

    for (final service in services) {
      if (service.contains('land') || service.contains('legal')) {
        templateTasks.add({
          'stage': 'Land & Legal',
          'title': 'Soil Testing & Site Investigation',
          'duration': 5,
        });
        templateTasks.add({
          'stage': 'Land & Legal',
          'title': 'Local Municipality Plan Submission & Approval',
          'duration': 14,
        });
      }
      if (service.contains('design') || service.contains('planning') || service.contains('planing')) {
        templateTasks.add({
          'stage': 'Design & Planning',
          'title': 'Architectural Concept & 2D Floor Plans',
          'duration': 7,
        });
        templateTasks.add({
          'stage': 'Design & Planning',
          'title': '3D Elevation Design & Client Review',
          'duration': 5,
        });
        templateTasks.add({
          'stage': 'Design & Planning',
          'title': 'Structural Analysis & Blueprint Finalization',
          'duration': 8,
        });
      }
      if (service.contains('mep')) {
        templateTasks.add({
          'stage': 'MEP',
          'title': 'Electrical Conduit & Piping Layout Blueprint',
          'duration': 4,
        });
        templateTasks.add({
          'stage': 'MEP',
          'title': 'Plumbing, Drainage, and Sanitary Pipeline Layout',
          'duration': 5,
        });
      }
      if (service.contains('structure') || service.contains('civil') || service.contains('foundation')) {
        templateTasks.add({
          'stage': 'Structure & Civil',
          'title': 'Excavation, Levelling, and Soil Compaction',
          'duration': 4,
        });
        templateTasks.add({
          'stage': 'Structure & Civil',
          'title': 'Foundation Footing & Steel Reinforcement Casting',
          'duration': 7,
        });
        templateTasks.add({
          'stage': 'Structure & Civil',
          'title': 'Brickwork, Pillars, and Roof Slab Casting',
          'duration': 20,
        });
      }
      if (service.contains('interior') || service.contains('finishing')) {
        templateTasks.add({
          'stage': 'Finishing & Interior',
          'title': 'Internal Plastering & Wall Putty Finish',
          'duration': 10,
        });
        templateTasks.add({
          'stage': 'Finishing & Interior',
          'title': 'Flooring Installation (Tiles/Marble)',
          'duration': 8,
        });
        templateTasks.add({
          'stage': 'Finishing & Interior',
          'title': 'Painting, Electrical Fixtures, and Deep Cleaning',
          'duration': 12,
        });
      }
    }

    if (templateTasks.length <= 1) {
      templateTasks.addAll([
        {'stage': 'Civil Works', 'title': 'Excavation & Ground Preparation', 'duration': 5},
        {'stage': 'Civil Works', 'title': 'Foundation & Columns Casting', 'duration': 10},
        {'stage': 'Civil Works', 'title': 'Brickwork & Wall Plastering', 'duration': 15},
        {'stage': 'Finishing', 'title': 'Flooring, Plumbing, and Electrical Fitouts', 'duration': 12},
      ]);
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/projects/${widget.projectId}/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tasks': templateTasks}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project schedule template generated!')),
        );
        _fetchProjectDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate template. Please try again.')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error generating template tasks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error.')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showTaskStatusSheet(Map<String, dynamic> task) {
    final taskId = task['id'];
    final title = task['title'] ?? 'Task Details';
    String selectedStatus = task['status'] ?? 'Todo';
    String? base64Image = task['photoUrl']; // Existing photo if any
    bool isSaving = false;

    final quotedCostController = TextEditingController(text: (task['quotedCost'] ?? 0.0).toString());
    final materialNameController = TextEditingController(text: task['materialName'] ?? '');
    final quantityController = TextEditingController(text: task['materialQuantity']?.toString() ?? '');
    final unitCostController = TextEditingController(text: task['materialUnitCost']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update status, material logs, or attach completion picture.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Status:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() => selectedStatus = 'Todo');
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: selectedStatus == 'Todo' ? Theme.of(context).primaryColor : Colors.grey.shade300,
                                width: selectedStatus == 'Todo' ? 2 : 1,
                              ),
                              backgroundColor: selectedStatus == 'Todo' ? Theme.of(context).primaryColor.withOpacity(0.08) : null,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Not Started',
                              style: TextStyle(
                                color: selectedStatus == 'Todo' ? Theme.of(context).primaryColor : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() => selectedStatus = 'In Progress');
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: selectedStatus == 'In Progress' ? Colors.blue : Colors.grey.shade300,
                                width: selectedStatus == 'In Progress' ? 2 : 1,
                              ),
                              backgroundColor: selectedStatus == 'In Progress' ? Colors.blue.withOpacity(0.08) : null,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'In Progress',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() => selectedStatus = 'Completed');
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: selectedStatus == 'Completed' ? Colors.green : Colors.grey.shade300,
                                width: selectedStatus == 'Completed' ? 2 : 1,
                              ),
                              backgroundColor: selectedStatus == 'Completed' ? Colors.green.withOpacity(0.08) : null,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Completed',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Quoted Cost for Client:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quotedCostController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quoted Price (₹)',
                        hintText: 'e.g. 1500',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.request_quote_outlined),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Material & Expense Details (Actual Cost):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: materialNameController,
                      decoration: InputDecoration(
                        labelText: 'Material / Expense Item',
                        hintText: 'e.g. Cement, Bricks, Legal Approval',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.build_circle_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity Used',
                              hintText: 'e.g. 5',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unitCostController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Unit Cost (₹)',
                              hintText: 'e.g. 250',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final quoted = double.tryParse(quotedCostController.text) ?? 0.0;
                        final qty = double.tryParse(quantityController.text) ?? 0.0;
                        final unit = double.tryParse(unitCostController.text) ?? 0.0;
                        final spent = qty * unit;
                        final profit = quoted - spent;
                        final isProfit = profit >= 0;
                                                     final isCompleted = task['status'] == 'Completed';
                                                     if (!isCompleted) {
                                                       if (quoted <= 0.0) return const SizedBox.shrink();
                                                       return Padding(
                                                         padding: const EdgeInsets.only(top: 4),
                                                         child: Text(
                                                           'Quoted Task Price: ₹${quoted.toStringAsFixed(2)}',
                                                           style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                                                         ),
                                                       );
                                                     }

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isProfit ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isProfit ? Colors.green.shade200 : Colors.red.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Quoted Cost (Client Charge):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  Text('₹${quoted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Actual Spent Cost:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  Text('₹${spent.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                                ],
                              ),
                              const Divider(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isProfit ? 'Estimated Profit:' : 'Estimated Loss:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isProfit ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                  ),
                                  Text(
                                    '${isProfit ? "+" : ""}₹${profit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isProfit ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    if (selectedStatus == 'Completed') ...[
                      const Text(
                        'Attach Completion Picture:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if (base64Image != null && base64Image!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.memory(
                                base64Decode(base64Image!.split(',').last),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () {
                                    setModalState(() => base64Image = null);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: () async {
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1000,
                            maxHeight: 1000,
                            imageQuality: 75,
                          );
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            final b64 = base64Encode(bytes);
                            setModalState(() {
                              base64Image = 'data:image/jpeg;base64,$b64';
                            });
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.add_a_photo),
                        label: Text(base64Image != null ? 'Change Photo' : 'Select Photo from Gallery'),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setModalState(() => isSaving = true);
                                    final quotedVal = double.tryParse(quotedCostController.text) ?? 0.0;
                                    final qtyVal = int.tryParse(quantityController.text);
                                    final costVal = double.tryParse(unitCostController.text);
                                    final totalCost = (qtyVal != null && costVal != null) ? (qtyVal * costVal) : 0.0;

                                    try {
                                      final response = await http.patch(
                                        Uri.parse('$apiBaseUrl/projects/${widget.projectId}/tasks'),
                                        headers: {'Content-Type': 'application/json'},
                                        body: jsonEncode({
                                          'taskId': taskId,
                                          'status': selectedStatus,
                                          'photoUrl': selectedStatus == 'Completed' ? base64Image : null,
                                          'materialName': materialNameController.text.trim(),
                                          'materialQuantity': qtyVal,
                                          'materialUnitCost': costVal,
                                          'taskCost': totalCost,
                                          'quotedCost': quotedVal,
                                        }),
                                      );
                                      if (response.statusCode == 200) {
                                        Navigator.pop(context);
                                        _fetchProjectDetails();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Task status updated!')),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to update task.')),
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('Error: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Network error updating task.')),
                                      );
                                    } finally {
                                      setModalState(() => isSaving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createCustomTask(String stage, String title, String durationStr) async {
    final duration = int.tryParse(durationStr) ?? 1;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/projects/${widget.projectId}/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'stage': stage,
          'title': title,
          'duration': duration,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom task added to plan!')));
        _fetchProjectDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add task.')));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error creating task: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to remove this task from the schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse('$apiBaseUrl/projects/${widget.projectId}/tasks?taskId=$taskId'),
        );
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted.')));
          _fetchProjectDetails();
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('Error deleting task: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startTask(String taskId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.patch(
        Uri.parse('$apiBaseUrl/projects/${widget.projectId}/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'taskId': taskId,
          'status': 'In Progress',
        }),
      );
      if (response.statusCode == 200) {
        _fetchProjectDetails();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task started!')),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start task.')),
        );
      }
    } catch (e) {
      debugPrint('Error starting task: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDailyUpdate(String title, String status, String notes) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/projects/${widget.projectId}/updates'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'status': status,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily update posted successfully!')),
        );
        _fetchProjectDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post update. Please try again.')),
        );
      }
    } catch (e) {
      debugPrint('Error adding update: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to backend.')),
      );
    }
  }

  void _showAddUpdateDialog() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    String selectedStatus = 'In Progress';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Post Daily Update',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Update Title',
                      hintText: 'e.g. Concrete pouring finished, Bricks delivery',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ['In Progress', 'Completed', 'Milestone Reached']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedStatus = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Optional Notes',
                      hintText: 'Provide details about today\'s tasks...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a title for the update.')),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _addDailyUpdate(
                          titleController.text.trim(),
                          selectedStatus,
                          notesController.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit Daily Log'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final durationController = TextEditingController(text: '5');
    
    final typeString = _project?['type'] as String? ?? '';
    final List<String> services = typeString.split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (services.isEmpty) services.add('General Planning');
    
    String selectedStage = services.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Custom Task',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStage,
                    decoration: const InputDecoration(labelText: 'Project Stage / Service', border: OutlineInputBorder()),
                    items: services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedStage = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Task Title (e.g. Concrete Pouring)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Duration (Days)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter task title')));
                        return;
                      }
                      Navigator.pop(context);
                      await _createCustomTask(selectedStage, titleController.text.trim(), durationController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Task'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateProjectStage(String stage) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.patch(
        Uri.parse('$apiBaseUrl/projects/${widget.projectId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'currentStage': stage}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project status updated to: $stage'), backgroundColor: Colors.green),
        );
        _fetchProjectDetails();
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to update status'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error updating project stage: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection failed. Could not update project.'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _project?['title'] ?? 'Active Job Details';
    final location = _project?['location'] ?? 'N/A';
    final plotSize = _project?['plotSize']?.toString() ?? '0';
    final double budget = (_project?['budget'] as num? ?? 0.0).toDouble();
    final timeline = _project?['timeline'] ?? 'N/A';
    final clientName = _project?['user']?['name'] ?? 'Client';
    final clientEmail = _project?['user']?['email'] ?? '';
    final updates = _project?['updates'] as List? ?? [];
    
    final tasks = _project?['tasks'] as List? ?? [];
    final completedCount = tasks.where((t) => t['status'] == 'Completed').length;
    final totalCount = tasks.length;
    final progressPercent = totalCount > 0 ? completedCount / totalCount : 0.0;

    double totalQuoted = 0.0;
    double totalSpent = 0.0;
    for (final t in tasks) {
      totalQuoted += (t['quotedCost'] as num? ?? 0.0).toDouble();
      totalSpent += (t['taskCost'] as num? ?? 0.0).toDouble();
    }
    final totalProfit = totalQuoted - totalSpent;
    final isTotalProfit = totalProfit >= 0;
    final materialTasks = tasks.where((t) => t['materialName'] != null && (t['materialName'] as String).isNotEmpty).toList();

    final Map<String, List<dynamic>> groupedTasks = {};
    for (final task in tasks) {
      final stage = task['stage'] ?? 'General Planning';
      groupedTasks.putIfAbsent(stage, () => []).add(task);
    }

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchProjectDetails,
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _project == null
                ? const Center(child: Text('Project details not found.'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 85),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Client details card
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                      child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            clientName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                          if (clientEmail.isNotEmpty)
                                            Text(
                                              clientEmail,
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Hired',
                                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                _buildDetailRow(Icons.location_on, 'Location', location),
                                const SizedBox(height: 8),
                                _buildDetailRow(Icons.square_foot, 'Plot Size', '$plotSize sq ft'),
                                const SizedBox(height: 8),
                                _buildDetailRow(Icons.calendar_today, 'Timeline', timeline),
                                const SizedBox(height: 8),
                                _buildDetailRow(Icons.currency_rupee, 'Budget', '₹$budget'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final currentStage = _project?['currentStage'] ?? 'Tracking';
                            final bool allCompleted = totalCount > 0 && completedCount == totalCount;

                            if (currentStage == 'Cancelled') {
                              return Card(
                                color: Colors.red.shade50,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.cancel, color: Colors.red, size: 28),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Project has been Cancelled.',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (currentStage == 'Completed' || currentStage == 'Finished') {
                              return Card(
                                color: Colors.green.shade50,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green, size: 28),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Project Completed successfully!',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (currentStage == 'Finished Pending Approval') {
                              return Card(
                                color: Colors.blue.shade50,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.hourglass_empty, color: Colors.blue, size: 28),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Project Submitted. Waiting for client\'s approval & review.',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final bool isOnHold = currentStage == 'On Hold';

                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Project Management Actions',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        // Hold/Resume Button
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateProjectStage(isOnHold ? 'Tracking' : 'On Hold'),
                                            icon: Icon(isOnHold ? Icons.play_arrow : Icons.pause),
                                            label: Text(isOnHold ? 'Resume Job' : 'Hold Project'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isOnHold ? Colors.orange : Colors.grey.shade700,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Finish Button
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: allCompleted && !isOnHold
                                                ? () => _updateProjectStage('Finished Pending Approval')
                                                : null,
                                            icon: const Icon(Icons.done_all),
                                            label: const Text('Finish Project'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!allCompleted) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.info_outline, size: 14, color: Colors.red),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Finish Project requires all tasks ($completedCount/$totalCount completed) to be done.',
                                              style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Tab / Segment Selector
                        SizedBox(
                          height: 48,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildCategoryTab(0, Icons.hourglass_empty, 'Pending', tasks.where((t) => t['status'] == 'Todo').length),
                              const SizedBox(width: 8),
                              _buildCategoryTab(1, Icons.play_arrow, 'Ongoing', tasks.where((t) => (t['status'] == 'In Progress' || t['status'] == 'Ongoing')).length),
                              const SizedBox(width: 8),
                              _buildCategoryTab(2, Icons.check_circle, 'Finished', tasks.where((t) => t['status'] == 'Completed').length),
                              const SizedBox(width: 8),
                              _buildCategoryTab(3, Icons.account_balance_wallet, 'Financials', null),
                              const SizedBox(width: 8),
                              _buildCategoryTab(4, Icons.people, 'Workers', null),
                              const SizedBox(width: 8),
                              _buildCategoryTab(5, Icons.description, 'Daily Logs', updates.length),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_selectedTab == 0) ...[
                          if (tasks.isEmpty) ...[
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(Icons.assignment, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Execution Plan Created Yet',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create a custom plan or generate a schedule template based on the client\'s selected services (${_project?['type'] ?? ''}).',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: _generateTemplateTasks,
                                      icon: const Icon(Icons.auto_awesome),
                                      label: const Text('Generate Smart Plan Template'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _showAddTaskDialog,
                                      child: const Text('Create Custom Step'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pending Project Steps',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _showAddTaskDialog,
                                  icon: const Icon(Icons.add_task, size: 16),
                                  label: const Text('Add Step'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final pendingList = tasks.where((t) => t['status'] == 'Todo').toList();
                                if (pendingList.isEmpty) {
                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                                            SizedBox(height: 12),
                                            Text(
                                              'No Pending Tasks!',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'All steps have either been started or completed.',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: pendingList.length,
                                  separatorBuilder: (context, idx) => const SizedBox(height: 10),
                                  itemBuilder: (context, idx) {
                                    final task = pendingList[idx];
                                    final taskId = task['id'];
                                    final tTitle = task['title'] ?? 'Untitled Step';
                                    final tDuration = task['duration'] ?? 1;
                                    final tStage = task['stage'] ?? 'General Planning';

                                    return Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        title: Text(tTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Stage: $tStage'),
                                            Text('Est. Duration: $tDuration days'),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.play_arrow, color: Colors.blue),
                                              tooltip: 'Start Task',
                                              onPressed: () => _startTask(taskId),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                              onPressed: () => _deleteTask(taskId),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            ),
                          ],
                        ],

                        // Tab 1: Ongoing Tasks
                        if (_selectedTab == 1) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ongoing Tasks / In Progress',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final ongoingList = tasks.where((t) => (t['status'] == 'In Progress' || t['status'] == 'Ongoing')).toList();
                              if (ongoingList.isEmpty) {
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.hourglass_empty, size: 48, color: Colors.orange),
                                          SizedBox(height: 12),
                                          Text(
                                            'No Ongoing Tasks!',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Start a pending task from the Pending tab.',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: ongoingList.length,
                                separatorBuilder: (context, idx) => const SizedBox(height: 10),
                                itemBuilder: (context, idx) {
                                  final task = ongoingList[idx];
                                  final tTitle = task['title'] ?? 'Untitled Step';
                                  final tDuration = task['duration'] ?? 1;
                                  final tStage = task['stage'] ?? 'General Planning';

                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      title: Text(tTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Stage: $tStage'),
                                          Text('Duration: $tDuration days in progress'),
                                        ],
                                      ),
                                      trailing: ElevatedButton.icon(
                                        icon: const Icon(Icons.check, size: 16),
                                        label: const Text('Complete'),
                                        onPressed: () => _showTaskStatusSheet(task),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          ),
                        ],

                        // Tab 2: Finished Tasks
                        if (_selectedTab == 2) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Finished / Completed Tasks',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final completedList = tasks.where((t) => t['status'] == 'Completed').toList();
                              if (completedList.isEmpty) {
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
                                          SizedBox(height: 12),
                                          Text(
                                            'No Finished Tasks Yet',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Complete active tasks to see them here.',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: completedList.length,
                                separatorBuilder: (context, idx) => const SizedBox(height: 10),
                                itemBuilder: (context, idx) {
                                  final task = completedList[idx];
                                  final tTitle = task['title'] ?? 'Untitled Step';
                                  final tStage = task['stage'] ?? 'General Planning';
                                  final quoted = (task['quotedCost'] as num? ?? 0.0).toDouble();
                                  final spent = (task['taskCost'] as num? ?? 0.0).toDouble();
                                  final profit = quoted - spent;
                                  final isProfit = profit >= 0;

                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  tTitle,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                ),
                                              ),
                                              const Icon(Icons.check_circle, color: Colors.green),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Stage: $tStage', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          if (task['materialName'] != null && (task['materialName'] as String).isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Material: ${task['materialName']} (Qty: ${task['materialQuantity'] ?? 1})',
                                              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800, fontStyle: FontStyle.italic),
                                            ),
                                          ],
                                          const Divider(height: 20),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            alignment: WrapAlignment.spaceBetween,
                                            children: [
                                              Text('Quoted Cost: ₹${quoted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                              Text('Spent Cost: ₹${spent.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                              Text(
                                                'Profit: ₹${profit.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isProfit ? Colors.green : Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (task['photoUrl'] != null && (task['photoUrl'] as String).isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.memory(
                                                base64Decode((task['photoUrl'] as String).split(',').last),
                                                height: 120,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          ),
                        ],

                        // Tab 3: Finance Summary
                        if (_selectedTab == 3) ...[
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.analytics_outlined, color: Theme.of(context).primaryColor, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Project Financials Summary',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Total Quoted', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                                            const SizedBox(height: 4),
                                            Text('₹${totalQuoted.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue)),
                                          ],
                                        ),
                                      ),
                                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Total Spent', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                                            const SizedBox(height: 4),
                                            Text('₹${totalSpent.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange)),
                                          ],
                                        ),
                                      ),
                                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(isTotalProfit ? 'Net Profit' : 'Net Loss', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${isTotalProfit ? "+" : ""}₹${totalProfit.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: isTotalProfit ? Colors.green.shade700 : Colors.red.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Project Budget:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('₹${budget.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Remaining Unallocated Budget:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text(
                                        '₹${(budget - totalQuoted).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: (budget - totalQuoted) >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (materialTasks.isNotEmpty) ...[
                                    const Divider(height: 24),
                                    const Text(
                                      'Material Expenses & Quotes Breakdown:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                                    ),
                                    const SizedBox(height: 12),
                                    ...materialTasks.map((t) {
                                      final mName = t['materialName'] ?? '';
                                      final mQty = t['materialQuantity'] ?? 1;
                                      final mUnit = (t['materialUnitCost'] as num? ?? 0.0).toDouble();
                                      final spent = (t['taskCost'] as num? ?? 0.0).toDouble();
                                      final quoted = (t['quotedCost'] as num? ?? 0.0).toDouble();
                                      final profit = quoted - spent;
                                      final isProfit = profit >= 0;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    mName,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  '${isProfit ? "+" : ""}₹${profit.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isProfit ? Colors.green.shade700 : Colors.red.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Qty: $mQty • Unit: ₹${mUnit.toStringAsFixed(2)}',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                ),
                                                Text(
                                                  'Quoted: ₹${quoted.toStringAsFixed(2)} • Spent: ₹${spent.toStringAsFixed(2)}',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Tab 4: Workers Attendance & Salary
                        if (_selectedTab == 4) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Labor & Wage Management',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                onPressed: _showAddWorkerDialog,
                                icon: const Icon(Icons.person_add, size: 16),
                                label: const Text('Add Worker'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text('Active Workers', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text('${_workers.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('Paid Salary', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${_workers.fold<double>(0.0, (sum, w) => sum + w.amountPaid).toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('Unpaid Salary', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${_workers.fold<double>(0.0, (sum, w) => sum + w.remainingSalary).toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _workers.length,
                            separatorBuilder: (context, idx) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final worker = _workers[idx];
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                            child: Text(worker.name.substring(0, 1), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                Text(worker.role, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                                const SizedBox(height: 2),
                                                Text('Wage: ₹${worker.dailyWage.toStringAsFixed(2)} / day • Worked: ${worker.daysPresent} days', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('Earned: ₹${worker.totalEarned.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              Text('Paid: ₹${worker.amountPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                                              Text('Unpaid: ₹${worker.remainingSalary.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: worker.isPresentToday,
                                                activeColor: Theme.of(context).primaryColor,
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setState(() {
                                                      worker.isPresentToday = val;
                                                      if (val) {
                                                        worker.daysPresent += 1;
                                                      } else {
                                                        worker.daysPresent = (worker.daysPresent - 1).clamp(0, 999);
                                                      }
                                                    });
                                                  }
                                                },
                                              ),
                                              const Text('Present Today', style: TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _showPayWagesDialog(worker),
                                            icon: const Icon(Icons.payment, size: 16),
                                            label: const Text('Pay Wages'),
                                            style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],

                          // Tab 5: Daily Logs
                          if (_selectedTab == 5) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daily Progress Logs',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _showAddUpdateDialog,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Log'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (updates.isEmpty)
                              Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.history, size: 48, color: Colors.grey),
                                        SizedBox(height: 12),
                                        Text(
                                          'No updates posted yet.',
                                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Post daily updates so the client can follow progress.',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: updates.length,
                                itemBuilder: (context, index) {
                                  final update = updates[index];
                                  final upTitle = update['title'] ?? 'Update';
                                  final upStatus = update['status'] ?? 'In Progress';
                                  final upNotes = update['notes'] ?? '';
                                  final upTime = update['createdAt'] != null
                                      ? DateTime.tryParse(update['createdAt'])?.toLocal().toString().substring(0, 16) ?? ''
                                      : '';

                                  Color statusColor = Colors.blue;
                                  if (upStatus == 'Completed') statusColor = Colors.green;
                                  if (upStatus == 'Milestone Reached') statusColor = Colors.orange;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  upTitle,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  upStatus,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (upNotes.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              upNotes,
                                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                            ),
                                          ],
                                          const Divider(height: 20),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Posted by assigned provider',
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                              ),
                                              Text(
                                                upTime,
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                      ],
                    ),
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final clientId = _project?['user']?['id'] ?? '';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  partnerId: clientId,
                  partnerName: clientName,
                ),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text('Chat with $clientName'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(int index, IconData icon, String label, int? count) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddWorkerDialog() {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final wageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Worker'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Worker Name',
                  hintText: 'e.g. Ramesh Singh',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'Role / Designation',
                  hintText: 'e.g. Mason, Electrician',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: wageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Daily Wage (₹)',
                  hintText: 'e.g. 25',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final role = roleController.text.trim();
              final wage = double.tryParse(wageController.text.trim()) ?? 0.0;

              if (name.isNotEmpty && role.isNotEmpty && wage > 0) {
                setState(() {
                  _workers.add(Worker(
                    id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    role: role,
                    dailyWage: wage,
                  ));
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Worker added successfully!')),
                );
              }
            },
            child: const Text('ADD WORKER'),
          ),
        ],
      ),
    );
  }

  void _showPayWagesDialog(Worker worker) {
    final amountController = TextEditingController(text: worker.remainingSalary.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pay Wages: ${worker.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Wage: ₹${worker.dailyWage.toStringAsFixed(2)}'),
            Text('Worked: ${worker.daysPresent} days'),
            Text('Total Earned: ₹${worker.totalEarned.toStringAsFixed(2)}'),
            Text('Already Paid: ₹${worker.amountPaid.toStringAsFixed(2)}'),
            const Divider(height: 16),
            Text(
              'Remaining Balance: ₹${worker.remainingSalary.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to Pay (₹)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (amount > 0) {
                setState(() {
                  worker.amountPaid += amount;
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Paid ₹${amount.toStringAsFixed(2)} to ${worker.name}!')),
                );
              }
            },
            child: const Text('RECORD PAYMENT'),
          ),
        ],
      ),
    );
  }
}
