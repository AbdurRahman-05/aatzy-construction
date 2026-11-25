import 'package:flutter/material.dart';
import 'package:construction_app/core/widgets/bento.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:construction_app/core/api_http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/media_picker_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/wallpaper_background.dart';
import '../../core/services/push_notification_service.dart';
import '../chat/chat_detail_screen.dart';
import '../../core/full_screen_image_viewer.dart';

class Worker {
  final String id;
  String name;
  String role;
  double dailyWage;
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'dailyWage': dailyWage,
    'isPresentToday': isPresentToday,
    'daysPresent': daysPresent,
    'amountPaid': amountPaid,
  };

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    role: json['role'] as String? ?? '',
    dailyWage: (json['dailyWage'] as num?)?.toDouble() ?? 0.0,
    isPresentToday: json['isPresentToday'] as bool? ?? false,
    daysPresent: (json['daysPresent'] as num?)?.toInt() ?? 0,
    amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
  );
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
  int _selectedTab =
      0; // 0: Pending, 1: Ongoing, 2: Finished, 3: Financials, 4: Workers, 5: Daily Logs
  final ImagePicker _picker = ImagePicker();
  List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    _fetchProjectDetails();
  }

  Future<void> _loadWorkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('project_workers_${widget.projectId}');
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        // Exclude legacy mock worker IDs and names so only user-added workers are loaded
        final loaded = list
            .map((item) => Worker.fromJson(item))
            .where(
              (w) =>
                  !['w1', 'w2', 'w3', 'w4'].contains(w.id) &&
                  ![
                    'Rajesh Kumar',
                    'Amit Singh',
                    'Sunil Verma',
                    'Vijay Yadav',
                  ].contains(w.name),
            )
            .toList();
        if (mounted) {
          setState(() {
            _workers = loaded;
          });
        }
        // If legacy mock workers were filtered out, update persistent store immediately
        if (loaded.length != list.length) {
          final encoded = jsonEncode(loaded.map((w) => w.toJson()).toList());
          await prefs.setString('project_workers_${widget.projectId}', encoded);
        }
      } else {
        if (mounted) {
          setState(() {
            _workers = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading workers: $e');
      if (mounted) setState(() => _workers = []);
    }
  }

  Future<void> _saveWorkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_workers.map((w) => w.toJson()).toList());
      await prefs.setString('project_workers_${widget.projectId}', encoded);
    } catch (e) {
      debugPrint('Error saving workers: $e');
    }
  }

  Future<void> _fetchProjectDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/projects/${widget.projectId}'),
      );
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
    final services = typeString
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .toList();

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
      if (service.contains('design') ||
          service.contains('planning') ||
          service.contains('planing')) {
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
      if (service.contains('borewell')) {
        templateTasks.add({
          'stage': 'Borewell',
          'title': 'Borewell Drilling & Casing Pipe Installation',
          'duration': 3,
        });
        templateTasks.add({
          'stage': 'Borewell',
          'title': 'Submersible Pump Installation & Testing',
          'duration': 2,
        });
      }
      if (service.contains('structure') ||
          service.contains('civil') ||
          service.contains('foundation')) {
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
        {
          'stage': 'Civil Works',
          'title': 'Excavation & Ground Preparation',
          'duration': 5,
        },
        {
          'stage': 'Civil Works',
          'title': 'Foundation & Columns Casting',
          'duration': 10,
        },
        {
          'stage': 'Civil Works',
          'title': 'Brickwork & Wall Plastering',
          'duration': 15,
        },
        {
          'stage': 'Finishing',
          'title': 'Flooring, Plumbing, and Electrical Fitouts',
          'duration': 12,
        },
      ]);
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/projects/${widget.projectId}/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tasks': templateTasks}),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project schedule template generated!')),
        );
        _fetchProjectDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate template. Please try again.'),
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error generating template tasks: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Connection error.')));
      setState(() => _isLoading = false);
    }
  }

  void _showTaskStatusSheet(Map<String, dynamic> task) {
    final taskId = task['id'];
    final title = task['title'] ?? 'Task Details';
    String selectedStatus = task['status'] ?? 'Todo';
    String? base64Image = task['photoUrl']; // Existing photo if any
    bool isSaving = false;

    // Detect if we already have other expense or material expense
    String expenseType = 'Material';
    if (task['materialName'] != null &&
        (task['materialName'] as String).isNotEmpty) {
      if (task['materialQuantity'] == null &&
          task['materialUnitCost'] == null) {
        expenseType = 'Other';
      }
    }

    final quotedCostController = TextEditingController(
      text: (task['quotedCost'] ?? 0.0).toString(),
    );
    final materialNameController = TextEditingController(
      text: task['materialName'] ?? '',
    );
    final quantityController = TextEditingController(
      text: task['materialQuantity']?.toString() ?? '',
    );
    final unitCostController = TextEditingController(
      text: task['materialUnitCost']?.toString() ?? '',
    );
    final otherCostController = TextEditingController(
      text: (task['taskCost'] ?? 0.0).toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update status, material logs, or attach completion picture.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                                color: selectedStatus == 'Todo'
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade300,
                                width: selectedStatus == 'Todo' ? 2 : 1,
                              ),
                              backgroundColor: selectedStatus == 'Todo'
                                  ? Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.08)
                                  : null,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Not Started',
                              style: TextStyle(
                                color: selectedStatus == 'Todo'
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade700,
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
                              setModalState(
                                () => selectedStatus = 'In Progress',
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: selectedStatus == 'In Progress'
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: selectedStatus == 'In Progress' ? 2 : 1,
                              ),
                              backgroundColor: selectedStatus == 'In Progress'
                                  ? Colors.blue.withValues(alpha: 0.08)
                                  : null,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                                color: selectedStatus == 'Completed'
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                width: selectedStatus == 'Completed' ? 2 : 1,
                              ),
                              backgroundColor: selectedStatus == 'Completed'
                                  ? Colors.green.withValues(alpha: 0.08)
                                  : null,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quotedCostController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quoted Price (₹)',
                        hintText: 'e.g. 1500',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.request_quote_outlined),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Expense Category / Log Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: expenseType,
                      decoration: InputDecoration(
                        labelText: 'Expense Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Material',
                          child: Text('Material Expenses'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Others')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            expenseType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (expenseType == 'Material') ...[
                      TextField(
                        controller: materialNameController,
                        decoration: InputDecoration(
                          labelText: 'Material Item Name',
                          hintText: 'e.g. Cement, Bricks, Sand',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      TextField(
                        controller: materialNameController,
                        decoration: InputDecoration(
                          labelText: 'Expense Reason / Description',
                          hintText: 'e.g. Legal Approval, Logistics, Tax',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.info_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: otherCostController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Expense Cost (₹)',
                          hintText: 'e.g. 1500',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.currency_rupee),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final quoted =
                            double.tryParse(quotedCostController.text) ?? 0.0;
                        double spent = 0.0;
                        if (expenseType == 'Material') {
                          final qty =
                              double.tryParse(quantityController.text) ?? 0.0;
                          final unit =
                              double.tryParse(unitCostController.text) ?? 0.0;
                          spent = qty * unit;
                        } else {
                          spent =
                              double.tryParse(otherCostController.text) ?? 0.0;
                        }
                        final profit = quoted - spent;
                        final isProfit = profit >= 0;
                        final isCompleted = selectedStatus == 'Completed';
                        if (!isCompleted) {
                          if (quoted <= 0.0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Quoted Task Price: ₹${quoted.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isProfit
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isProfit
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Quoted Cost (Client Charge):',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '₹${quoted.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Actual Spent Cost:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '₹${spent.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isProfit
                                        ? 'Estimated Profit:'
                                        : 'Estimated Loss:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isProfit
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                    ),
                                  ),
                                  Text(
                                    '${isProfit ? "+" : ""}₹${profit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isProfit
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (base64Image != null && base64Image!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FullScreenImageViewer(
                                            base64Image: base64Image!,
                                            title: title,
                                          ),
                                    ),
                                  );
                                },
                                child: Image.memory(
                                  base64Decode(base64Image!.split(',').last),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
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
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.add_a_photo),
                        label: Text(
                          base64Image != null
                              ? 'Change Photo'
                              : 'Select Photo from Gallery',
                        ),
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
                                    final quotedVal =
                                        double.tryParse(
                                          quotedCostController.text,
                                        ) ??
                                        0.0;
                                    int? qtyVal;
                                    double? costVal;
                                    double totalCost = 0.0;

                                    if (expenseType == 'Material') {
                                      qtyVal = int.tryParse(
                                        quantityController.text,
                                      );
                                      costVal = double.tryParse(
                                        unitCostController.text,
                                      );
                                      totalCost =
                                          (qtyVal != null && costVal != null)
                                          ? (qtyVal * costVal)
                                          : 0.0;
                                    } else {
                                      qtyVal = null;
                                      costVal = null;
                                      totalCost =
                                          double.tryParse(
                                            otherCostController.text,
                                          ) ??
                                          0.0;
                                    }

                                    try {
                                      final response = await http.patch(
                                        Uri.parse(
                                          '$apiBaseUrl/projects/${widget.projectId}/tasks',
                                        ),
                                        headers: {
                                          'Content-Type': 'application/json',
                                        },
                                        body: jsonEncode({
                                          'taskId': taskId,
                                          'status': selectedStatus,
                                          'photoUrl':
                                              selectedStatus == 'Completed'
                                              ? base64Image
                                              : null,
                                          'materialName': materialNameController
                                              .text
                                              .trim(),
                                          'materialQuantity': qtyVal,
                                          'materialUnitCost': costVal,
                                          'taskCost': totalCost,
                                          'quotedCost': quotedVal,
                                        }),
                                      );
                                      if (response.statusCode == 200) {
                                        final taskTitle =
                                            task['title'] ?? 'Task';
                                        final projTitle =
                                            _project?['title'] ?? 'Project';
                                        if (selectedStatus == 'Completed') {
                                          PushNotificationService().showNotification(
                                            id:
                                                DateTime.now()
                                                    .millisecondsSinceEpoch ~/
                                                1000,
                                            title:
                                                '✅ Task Finished: $taskTitle',
                                            body:
                                                'Milestone marked as finished on "$projTitle"!',
                                            payload:
                                                '/provider-job/${widget.projectId}',
                                            channelId: 'buildzy_leads_v2',
                                            channelName: 'Tasks & Milestones',
                                          );
                                        } else if (selectedStatus ==
                                            'In Progress') {
                                          PushNotificationService().showNotification(
                                            id:
                                                DateTime.now()
                                                    .millisecondsSinceEpoch ~/
                                                1000,
                                            title:
                                                '🚀 Task Started: $taskTitle',
                                            body:
                                                'Work is now ongoing for "$projTitle".',
                                            payload:
                                                '/provider-job/${widget.projectId}',
                                            channelId: 'buildzy_leads_v2',
                                            channelName: 'Tasks & Milestones',
                                          );
                                        }

                                        if (expenseType == 'Material' &&
                                            materialNameController.text
                                                .trim()
                                                .isNotEmpty) {
                                          PushNotificationService().showNotification(
                                            id:
                                                DateTime.now()
                                                        .millisecondsSinceEpoch ~/
                                                    1000 +
                                                1,
                                            title:
                                                '🧱 Material Logged: ${materialNameController.text.trim()}',
                                            body:
                                                'Site material updated: ${qtyVal?.toStringAsFixed(0) ?? ''} units @ ₹${costVal?.toStringAsFixed(0) ?? ''} on "${_project?['title'] ?? 'Project'}".',
                                            payload:
                                                '/provider-job/${widget.projectId}',
                                            channelId: 'buildzy_orders_v2',
                                            channelName:
                                                'Material Inquiries & Orders',
                                          );
                                        }

                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext);
                                          ScaffoldMessenger.of(
                                            sheetContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Task status updated!',
                                              ),
                                            ),
                                          );
                                        }
                                        _fetchProjectDetails();
                                      } else {
                                        if (sheetContext.mounted) {
                                          ScaffoldMessenger.of(
                                            sheetContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Failed to update task.',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      debugPrint('Error: $e');
                                      if (sheetContext.mounted) {
                                        ScaffoldMessenger.of(
                                          sheetContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Network error updating task.',
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                      setModalState(() => isSaving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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

  Future<void> _createCustomTask(
    String stage,
    String title,
    String durationStr,
  ) async {
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

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final projTitle = _project?['title'] ?? 'Project';
        PushNotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: '📋 Task Created: $title',
          body: 'New task created under stage "$stage" for "$projTitle".',
          payload: '/provider-job/${widget.projectId}',
          channelId: 'buildzy_leads_v2',
          channelName: 'Tasks & Milestones',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom task added to plan!')),
        );
        _fetchProjectDetails();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add task.')));
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
        content: const Text(
          'Are you sure you want to remove this task from the schedule?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse(
            '$apiBaseUrl/projects/${widget.projectId}/tasks?taskId=$taskId',
          ),
        );
        if (!mounted) return;
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Task deleted.')));
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
        body: jsonEncode({'taskId': taskId, 'status': 'In Progress'}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        _fetchProjectDetails();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task started!')));
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to start task.')));
      }
    } catch (e) {
      debugPrint('Error starting task: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDailyUpdate(
    String title,
    String status,
    String notes, [
    String? photoUrl,
  ]) async {
    try {
      final effectiveNotes = (photoUrl != null && photoUrl.isNotEmpty)
          ? '$notes\n[PHOTO:$photoUrl]'.trim()
          : notes;

      final response = await http.post(
        Uri.parse('$apiBaseUrl/projects/${widget.projectId}/updates'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'status': status,
          'notes': effectiveNotes,
          if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily update posted successfully!')),
        );
        _fetchProjectDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post update. Please try again.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding update: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to backend.')),
      );
    }
  }

  void _showAddUpdateDialog() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    String selectedStatus = 'In Progress';
    String? updatePhotoBase64;
    bool isPickingImage = false;

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Post Daily Update',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Update Title',
                        hintText:
                            'e.g. Concrete pouring finished, Bricks delivery',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['In Progress', 'Completed', 'Milestone Reached']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
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
                    const SizedBox(height: 16),
                    // Photo Attachment Section
                    if (updatePhotoBase64 != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Builder(
                              builder: (context) {
                                try {
                                  final cleanB64 =
                                      updatePhotoBase64!.contains(',')
                                      ? updatePhotoBase64!.split(',').last
                                      : updatePhotoBase64!;
                                  return Image.memory(
                                    base64Decode(
                                      cleanB64.replaceAll(RegExp(r'\s+'), ''),
                                    ),
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  );
                                } catch (_) {
                                  return Container(
                                    height: 140,
                                    width: double.infinity,
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  updatePhotoBase64 = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isPickingImage
                                  ? null
                                  : () async {
                                      setModalState(
                                        () => isPickingImage = true,
                                      );
                                      try {
                                        final XFile? photo =
                                            await MediaPickerService.pickImage(
                                              source: ImageSource.camera,
                                              context: context,
                                              maxWidth: 1000,
                                              maxHeight: 1000,
                                              imageQuality: 75,
                                            );
                                        if (photo != null) {
                                          final bytes = await photo
                                              .readAsBytes();
                                          setModalState(() {
                                            updatePhotoBase64 =
                                                'data:image/jpeg;base64,${base64Encode(bytes)}';
                                          });
                                        }
                                      } finally {
                                        setModalState(
                                          () => isPickingImage = false,
                                        );
                                      }
                                    },
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Camera',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isPickingImage
                                  ? null
                                  : () async {
                                      setModalState(
                                        () => isPickingImage = true,
                                      );
                                      try {
                                        final XFile? photo =
                                            await MediaPickerService.pickImage(
                                              source: ImageSource.gallery,
                                              context: context,
                                              maxWidth: 1000,
                                              maxHeight: 1000,
                                              imageQuality: 75,
                                            );
                                        if (photo != null) {
                                          final bytes = await photo
                                              .readAsBytes();
                                          setModalState(() {
                                            updatePhotoBase64 =
                                                'data:image/jpeg;base64,${base64Encode(bytes)}';
                                          });
                                        }
                                      } finally {
                                        setModalState(
                                          () => isPickingImage = false,
                                        );
                                      }
                                    },
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Gallery',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a title for the update.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          _addDailyUpdate(
                            titleController.text.trim(),
                            selectedStatus,
                            notesController.text.trim(),
                            updatePhotoBase64,
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
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Delete Project',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete this cancelled project? This will delete all tasks, logs, and associated records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete Permanently',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse('$apiBaseUrl/projects/${widget.projectId}'),
        );
        if (response.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/provider-home');
          }
        } else {
          final data = jsonDecode(response.body);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Failed to delete project'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('Error deleting project: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting project. Connection failed.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final durationController = TextEditingController(text: '5');

    final typeString = _project?['type'] as String? ?? '';
    final List<String> services = typeString
        .split(',')
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStage,
                    decoration: const InputDecoration(
                      labelText: 'Project Stage / Service',
                      border: OutlineInputBorder(),
                    ),
                    items: services
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
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
                    decoration: const InputDecoration(
                      labelText: 'Task Title (e.g. Concrete Pouring)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (Days)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter task title'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      await _createCustomTask(
                        selectedStage,
                        titleController.text.trim(),
                        durationController.text.trim(),
                      );
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
          SnackBar(
            content: Text('Project status updated to: $stage'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchProjectDetails();
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error updating project stage: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection failed. Could not update project.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _project?['title'] ?? 'Active Job Details';
    final location = _project?['location'] ?? 'N/A';
    final plotSize = _project?['plotSize']?.toString() ?? '0';
    final quotes = _project?['quotes'] as List? ?? [];
    Map<String, dynamic>? acceptedQuote;
    for (final q in quotes) {
      if (q is Map && q['isAccepted'] == true) {
        acceptedQuote = Map<String, dynamic>.from(q);
        break;
      }
    }
    final double acceptedBudget =
        (acceptedQuote?['estimatedCost'] as num?)?.toDouble() ?? 0.0;
    final double budget = acceptedBudget > 0
        ? acceptedBudget
        : (_project?['budget'] as num? ?? 0.0).toDouble();
    final timeline = (acceptedQuote?['timeline']?.toString().isNotEmpty == true)
        ? acceptedQuote!['timeline']
        : (_project?['timeline'] ?? 'N/A');
    final clientName = _project?['user']?['name'] ?? 'Client';
    final clientEmail = _project?['user']?['email'] ?? '';
    final updates = _project?['updates'] as List? ?? [];

    final tasks = _project?['tasks'] as List? ?? [];
    final completedCount = tasks
        .where((t) => t['status'] == 'Completed')
        .length;
    final totalCount = tasks.length;

    final currentStage = _project?['currentStage'] ?? 'Tracking';
    final stageLower = currentStage.toString().toLowerCase().trim();
    final bool isCompleted =
        stageLower == 'completed' || stageLower == 'finished';
    final bool isCancelled = stageLower == 'cancelled';
    final bool isReadOnly = isCompleted || isCancelled;

    double totalQuoted = 0.0;
    double totalSpent = 0.0;
    for (final t in tasks) {
      totalQuoted += (t['quotedCost'] as num? ?? 0.0).toDouble();
      totalSpent += (t['taskCost'] as num? ?? 0.0).toDouble();
    }
    final materialTasks = tasks
        .where(
          (t) =>
              t['materialName'] != null &&
              (t['materialName'] as String).isNotEmpty,
        )
        .toList();

    final Map<String, List<dynamic>> groupedTasks = {};
    for (final task in tasks) {
      final stage = task['stage'] ?? 'General Planning';
      groupedTasks.putIfAbsent(stage, () => []).add(task);
    }

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BentoAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/provider-home');
              }
            },
          ),
          title: Text(title),
          actions: [
            if (isCancelled)
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                tooltip: 'Delete Cancelled Project',
                onPressed: _showDeleteConfirmationDialog,
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchProjectDetails,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _project == null
            ? const Center(child: Text('Project details not found.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Bento hero: stage, progress, client ──
                    _buildJobHero(
                      title: title.toString(),
                      clientName: clientName.toString(),
                      clientEmail: clientEmail.toString(),
                      clientImage: _project?['user']?['profileImage']?.toString(),
                      stage: currentStage.toString(),
                      completed: completedCount,
                      total: totalCount,
                    ),
                    const SizedBox(height: Bento.gap),
                    _buildJobFacts(location.toString(), plotSize, timeline.toString(), budget),
                    const SizedBox(height: Bento.gap),
                    _buildJobActions(currentStage.toString(), completedCount, totalCount),
                    const SizedBox(height: 24),

                    // ── Section tabs ──
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryTab(0, Icons.schedule_rounded, 'Pending', tasks.where((t) => t['status'] == 'Todo').length),
                          const SizedBox(width: 8),
                          _buildCategoryTab(
                            1,
                            Icons.play_arrow_rounded,
                            'Ongoing',
                            tasks.where((t) => t['status'] == 'In Progress' || t['status'] == 'Ongoing').length,
                          ),
                          const SizedBox(width: 8),
                          _buildCategoryTab(2, Icons.check_circle_rounded, 'Finished', tasks.where((t) => t['status'] == 'Completed').length),
                          const SizedBox(width: 8),
                          _buildCategoryTab(3, Icons.account_balance_wallet_rounded, 'Financials', null),
                          const SizedBox(width: 8),
                          _buildCategoryTab(4, Icons.groups_rounded, 'Workers', _workers.length),
                          const SizedBox(width: 8),
                          _buildCategoryTab(5, Icons.photo_library_rounded, 'Daily logs', updates.length),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Tab 0: Pending steps ──
                    if (_selectedTab == 0) ...[
                      if (tasks.isEmpty)
                        _buildNoPlanCard(isReadOnly)
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Pending steps',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                  color: Bento.text(Theme.of(context).brightness == Brightness.dark),
                                ),
                              ),
                            ),
                            if (!isReadOnly)
                              BentoButton(
                                label: 'Add step',
                                icon: Icons.add_rounded,
                                compact: true,
                                onTap: _showAddTaskDialog,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final pendingList = tasks.where((t) => t['status'] == 'Todo').toList();
                            if (pendingList.isEmpty) {
                              return const BentoEmptyState(
                                icon: Icons.task_alt_rounded,
                                title: 'No pending steps',
                                subtitle: 'Every step has been started or completed.',
                              );
                            }
                            return Column(
                              children: [
                                for (final task in pendingList) ...[
                                  _buildPendingTaskCard(task, isReadOnly),
                                  const SizedBox(height: 10),
                                ],
                              ],
                            );
                          },
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final ongoingList = tasks
                              .where(
                                (t) =>
                                    (t['status'] == 'In Progress' ||
                                    t['status'] == 'Ongoing'),
                              )
                              .toList();
                          if (ongoingList.isEmpty) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.hourglass_empty,
                                        size: 48,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No Ongoing Tasks!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Start a pending task from the Pending tab.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
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
                            separatorBuilder: (context, idx) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final task = ongoingList[idx];
                              final tTitle = task['title'] ?? 'Untitled Step';
                              final tDuration = task['duration'] ?? 1;
                              final tStage =
                                  task['stage'] ?? 'General Planning';

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  title: Text(
                                    tTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Stage: $tStage'),
                                      Text(
                                        'Duration: $tDuration days in progress',
                                      ),
                                    ],
                                  ),
                                  trailing: isReadOnly
                                      ? null
                                      : ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.check,
                                            size: 16,
                                          ),
                                          label: const Text('Complete'),
                                          onPressed: () =>
                                              _showTaskStatusSheet(task),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],

                    // Tab 2: Finished Tasks
                    if (_selectedTab == 2) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Finished / Completed Tasks',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final completedList = tasks
                              .where((t) => t['status'] == 'Completed')
                              .toList();
                          if (completedList.isEmpty) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.assignment_turned_in_outlined,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No Finished Tasks Yet',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Complete active tasks to see them here.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
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
                            separatorBuilder: (context, idx) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final task = completedList[idx];
                              final tTitle = task['title'] ?? 'Untitled Step';
                              final tStage =
                                  task['stage'] ?? 'General Planning';
                              final quoted = (task['quotedCost'] as num? ?? 0.0)
                                  .toDouble();
                              final spent = (task['taskCost'] as num? ?? 0.0)
                                  .toDouble();
                              final profit = quoted - spent;
                              final isProfit = profit >= 0;

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              tTitle,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Stage: $tStage',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (task['materialName'] != null &&
                                          (task['materialName'] as String)
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Builder(
                                          builder: (context) {
                                            final isMaterial =
                                                task['materialQuantity'] !=
                                                    null &&
                                                task['materialUnitCost'] !=
                                                    null;
                                            if (isMaterial) {
                                              return Text(
                                                'Material: ${task['materialName']} (Qty: ${task['materialQuantity']} @ ₹${(task['materialUnitCost'] as num).toStringAsFixed(0)}/unit)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Colors.blueGrey.shade800,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              );
                                            } else {
                                              return Text(
                                                'Other Expense: ${task['materialName']} (Cost: ₹${(task['taskCost'] ?? 0.0).toStringAsFixed(0)})',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Colors.blueGrey.shade800,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                      const Divider(height: 20),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        alignment: WrapAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Quoted Cost: ₹${quoted.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Spent Cost: ₹${spent.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Profit: ₹${profit.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isProfit
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (task['photoUrl'] != null &&
                                          (task['photoUrl'] as String)
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () {
                                            final rawPhoto =
                                                task['photoUrl'] as String;
                                            final isNet =
                                                rawPhoto.startsWith(
                                                  'http://',
                                                ) ||
                                                rawPhoto.startsWith('https://');
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    FullScreenImageViewer(
                                                      base64Image: isNet
                                                          ? null
                                                          : rawPhoto,
                                                      imageUrl: isNet
                                                          ? rawPhoto
                                                          : null,
                                                      title:
                                                          task['title'] ??
                                                          'Task Photo',
                                                    ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Builder(
                                              builder: (context) {
                                                final rawPhoto =
                                                    (task['photoUrl'] as String)
                                                        .trim();
                                                if (rawPhoto.startsWith(
                                                      'http://',
                                                    ) ||
                                                    rawPhoto.startsWith(
                                                      'https://',
                                                    )) {
                                                  return Image.network(
                                                    rawPhoto,
                                                    height: 120,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Container(
                                                          height: 120,
                                                          color: Colors
                                                              .grey
                                                              .shade200,
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .broken_image,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ),
                                                  );
                                                }
                                                try {
                                                  final cleanB64 =
                                                      (rawPhoto.contains(',')
                                                              ? rawPhoto
                                                                    .split(',')
                                                                    .last
                                                              : rawPhoto)
                                                          .replaceAll(
                                                            RegExp(r'\\s+'),
                                                            '',
                                                          );
                                                  return Image.memory(
                                                    base64Decode(cleanB64),
                                                    height: 120,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Container(
                                                          height: 120,
                                                          color: Colors
                                                              .grey
                                                              .shade200,
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .broken_image,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ),
                                                  );
                                                } catch (_) {
                                                  return Container(
                                                    height: 120,
                                                    color: Colors.grey.shade200,
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],

                    // Tab 3: Finance Summary
                    if (_selectedTab == 3) ...[
                      Builder(
                        builder: (context) {
                          final double totalWorkersWage = _workers.fold<double>(
                            0.0,
                            (sum, w) => sum + w.totalEarned,
                          );
                          final double totalWorkersPaid = _workers.fold<double>(
                            0.0,
                            (sum, w) => sum + w.amountPaid,
                          );
                          final double totalProjectExpenses =
                              totalSpent + totalWorkersWage;
                          final double actualProfit =
                              totalQuoted - totalProjectExpenses;
                          final bool isActualProfit = actualProfit >= 0;

                          // Cash Flow calculations
                          final double cashIn = totalQuoted;
                          final double cashOut = totalSpent + totalWorkersPaid;
                          final double netCashFlow = cashIn - cashOut;
                          final bool isPositiveCashFlow = netCashFlow >= 0;

                          return Column(
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.analytics_outlined,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Project Financials Summary',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Quoted Revenue',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '₹${totalQuoted.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 35,
                                            color: Colors.grey.shade300,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Total Expenses',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '₹${totalProjectExpenses.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 35,
                                            color: Colors.grey.shade300,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isActualProfit
                                                      ? 'Net Profit'
                                                      : 'Net Loss',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${isActualProfit ? "+" : ""}₹${actualProfit.toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                    color: isActualProfit
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade700,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Contract Budget:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '₹${budget.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Material Expenses:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '₹${totalSpent.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Labor Wages (Workers):',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '₹${totalWorkersWage.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Visual Chart Card (PieChart)
                              if (totalQuoted > 0)
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Budget Allocation & Margins',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          height: 180,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 4,
                                                child: PieChart(
                                                  PieChartData(
                                                    sectionsSpace: 2,
                                                    centerSpaceRadius: 35,
                                                    sections: [
                                                      if (totalSpent > 0)
                                                        PieChartSectionData(
                                                          color: Colors
                                                              .orange
                                                              .shade400,
                                                          value: totalSpent,
                                                          title:
                                                              '${((totalSpent / totalQuoted) * 100).toStringAsFixed(0)}%',
                                                          radius: 40,
                                                          titleStyle:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                      if (totalWorkersWage > 0)
                                                        PieChartSectionData(
                                                          color: Colors
                                                              .red
                                                              .shade400,
                                                          value:
                                                              totalWorkersWage,
                                                          title:
                                                              '${((totalWorkersWage / totalQuoted) * 100).toStringAsFixed(0)}%',
                                                          radius: 40,
                                                          titleStyle:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                      if (actualProfit > 0)
                                                        PieChartSectionData(
                                                          color: Colors
                                                              .green
                                                              .shade400,
                                                          value: actualProfit,
                                                          title:
                                                              '${((actualProfit / totalQuoted) * 100).toStringAsFixed(0)}%',
                                                          radius: 45,
                                                          titleStyle:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 5,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _buildLegendItem(
                                                      Colors.orange.shade400,
                                                      'Materials',
                                                      totalSpent,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _buildLegendItem(
                                                      Colors.red.shade400,
                                                      'Labor / Wages',
                                                      totalWorkersWage,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _buildLegendItem(
                                                      Colors.green.shade400,
                                                      isActualProfit
                                                          ? 'Profit Margin'
                                                          : 'Loss',
                                                      actualProfit,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),

                              // Cash Flow Card
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Project Cash Flow',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildCashFlowRow(
                                        'Cash In (Revenue Generated)',
                                        cashIn,
                                        Colors.blue,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCashFlowRow(
                                        'Cash Out (Wages Paid + Materials)',
                                        cashOut,
                                        Colors.orange,
                                      ),
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Net Cash Flow:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '${isPositiveCashFlow ? "+" : ""}₹${netCashFlow.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              color: isPositiveCashFlow
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (materialTasks.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    'Material Expenses Breakdown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...materialTasks.map((t) {
                                  final mName = t['materialName'] ?? '';
                                  final mQty = t['materialQuantity'] ?? 1;
                                  final mUnit =
                                      (t['materialUnitCost'] as num? ?? 0.0)
                                          .toDouble();
                                  final spent = (t['taskCost'] as num? ?? 0.0)
                                      .toDouble();
                                  final quoted =
                                      (t['quotedCost'] as num? ?? 0.0)
                                          .toDouble();
                                  final profit = quoted - spent;
                                  final isProfit = profit >= 0;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                mName,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              '${isProfit ? "+" : ""}₹${profit.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isProfit
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Builder(
                                              builder: (context) {
                                                final isMaterial =
                                                    t['materialQuantity'] !=
                                                        null &&
                                                    t['materialUnitCost'] !=
                                                        null;
                                                if (isMaterial) {
                                                  return Text(
                                                    'Qty: $mQty • Unit: ₹${mUnit.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  );
                                                } else {
                                                  return Text(
                                                    'Other Expense',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            Text(
                                              'Quoted: ₹${quoted.toStringAsFixed(0)} • Spent: ₹${spent.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          );
                        },
                      ),
                    ],

                    // Tab 4: Workers Attendance & Salary
                    if (_selectedTab == 4) ...[
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Labor & Wage Management',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (!isReadOnly)
                              ElevatedButton.icon(
                                onPressed: _showAddWorkerDialog,
                                icon: const Icon(Icons.person_add, size: 16),
                                label: const Text('Add Worker'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Active Workers',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_workers.length}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Paid Salary',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '₹${_workers.fold<double>(0.0, (sum, w) => sum + w.amountPaid).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Unpaid Salary',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '₹${_workers.fold<double>(0.0, (sum, w) => sum + w.remainingSalary).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_workers.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 28,
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.engineering_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No workers added yet',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add your workers to track daily attendance, daily wages, and payouts.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (!isReadOnly) ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _showAddWorkerDialog,
                                      icon: const Icon(
                                        Icons.person_add,
                                        size: 16,
                                      ),
                                      label: const Text('Add First Worker'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _workers.length,
                          separatorBuilder: (context, idx) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final worker = _workers[idx];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.1),
                                          child: Text(
                                            worker.name.isNotEmpty
                                                ? worker.name
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                : 'W',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                worker.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                worker.role,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Wage: ₹${worker.dailyWage.toStringAsFixed(0)} / day • Worked: ${worker.daysPresent} days',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Earned: ₹${worker.totalEarned.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Paid: ₹${worker.amountPaid.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.green,
                                              ),
                                            ),
                                            Text(
                                              'Unpaid: ₹${worker.remainingSalary.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          InkWell(
                                            onTap: isReadOnly
                                                ? null
                                                : () {
                                                    setState(() {
                                                      worker.isPresentToday =
                                                          !worker
                                                              .isPresentToday;
                                                      if (worker
                                                          .isPresentToday) {
                                                        worker.daysPresent += 1;
                                                      } else {
                                                        worker.daysPresent =
                                                            (worker.daysPresent -
                                                                    1)
                                                                .clamp(0, 999);
                                                      }
                                                    });
                                                    _saveWorkers();
                                                  },
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Checkbox(
                                                  value: worker.isPresentToday,
                                                  activeColor: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  onChanged: isReadOnly
                                                      ? null
                                                      : (val) {
                                                          if (val != null) {
                                                            setState(() {
                                                              worker.isPresentToday =
                                                                  val;
                                                              if (val) {
                                                                worker.daysPresent +=
                                                                    1;
                                                              } else {
                                                                worker.daysPresent =
                                                                    (worker.daysPresent -
                                                                            1)
                                                                        .clamp(
                                                                          0,
                                                                          999,
                                                                        );
                                                              }
                                                            });
                                                            _saveWorkers();
                                                          }
                                                        },
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  'Present Today',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isReadOnly)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _showEditWorkerDialog(
                                                        worker,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    size: 14,
                                                  ),
                                                  label: const Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.blue,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 4,
                                                        ),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      _deleteWorker(worker),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                    color: Colors.red,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  constraints:
                                                      const BoxConstraints(),
                                                  tooltip: 'Delete Worker',
                                                ),
                                                const SizedBox(width: 2),
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _showPayWagesDialog(
                                                        worker,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.payment,
                                                    size: 14,
                                                  ),
                                                  label: const Text(
                                                    'Pay Wages',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 4,
                                                        ),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
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
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Daily Progress Logs',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (!isReadOnly)
                              ElevatedButton.icon(
                                onPressed: _showAddUpdateDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Log'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (updates.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No updates posted yet.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Post daily updates so the client can follow progress.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
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
                            final rawNotes = (update['notes'] ?? '').toString();
                            String upNotes = rawNotes;
                            String? updatePhoto =
                                (update['photoUrl'] as String?)?.trim();

                            // Extract embedded photo tag if present
                            final photoMatch = RegExp(
                              r'\[PHOTO:(.+?)\]',
                            ).firstMatch(rawNotes);
                            if (photoMatch != null) {
                              if (updatePhoto == null || updatePhoto.isEmpty) {
                                updatePhoto = photoMatch.group(1)?.trim();
                              }
                              upNotes = upNotes
                                  .replaceAll(RegExp(r'\[PHOTO:.+?\]'), '')
                                  .trim();
                            }

                            final upTime = update['createdAt'] != null
                                ? DateTime.tryParse(update['createdAt'])
                                          ?.toLocal()
                                          .toString()
                                          .substring(0, 16) ??
                                      ''
                                : '';

                            Color statusColor = Colors.blue;
                            if (upStatus == 'Completed') {
                              statusColor = Colors.green;
                            }
                            if (upStatus == 'Milestone Reached') {
                              statusColor = Colors.orange;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            upTitle,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                    if (updatePhoto != null &&
                                        updatePhoto.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      _buildDailyLogPhotoPreview(
                                        context,
                                        updatePhoto,
                                        upTitle,
                                      ),
                                    ],
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Posted by assigned provider',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          upTime,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                          ),
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
        bottomNavigationBar: _project == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: BentoPressable(
                    onTap: () => _openClientChat(clientName.toString()),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: Bento.inkGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_rounded, color: Bento.accentLight, size: 20),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Chat with $clientName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ===========================================================================
  // Bento building blocks for the job detail page
  // ===========================================================================

  ({String label, Color color, IconData icon}) _jobStatus(String stage) {
    final s = stage.toLowerCase().trim();
    if (s == 'cancelled') return (label: 'Cancelled', color: const Color(0xFFF87171), icon: Icons.cancel_rounded);
    if (s == 'completed' || s == 'finished') return (label: 'Completed', color: const Color(0xFF34D399), icon: Icons.verified_rounded);
    if (s == 'finished pending approval') return (label: 'Awaiting approval', color: const Color(0xFFA78BFA), icon: Icons.hourglass_top_rounded);
    if (s == 'on hold') return (label: 'On hold', color: const Color(0xFFFBBF24), icon: Icons.pause_circle_rounded);
    return (label: 'In progress', color: Bento.accentLight, icon: Icons.construction_rounded);
  }

  String _formatRupees(num value) => '₹${NumberFormat.decimalPattern('en_IN').format(value.round())}';

  Widget _buildJobHero({
    required String title,
    required String clientName,
    required String clientEmail,
    required String? clientImage,
    required String stage,
    required int completed,
    required int total,
  }) {
    final status = _jobStatus(stage);
    final progress = total == 0 ? 0.0 : completed / total;

    return BentoCard(
      gradient: Bento.inkGradient,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned(right: -60, top: -70, child: BentoGlow(size: 210)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BentoPill(
                      label: status.label.toUpperCase(),
                      color: status.color,
                      background: status.color.withValues(alpha: 0.16),
                      icon: status.icon,
                    ),
                    const Spacer(),
                    BentoPill(
                      label: 'HIRED',
                      color: const Color(0xFF34D399),
                      background: const Color(0xFF10B981).withValues(alpha: 0.16),
                      icon: Icons.handshake_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(value: 1, strokeWidth: 7, color: Colors.white.withValues(alpha: 0.1)),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => CircularProgressIndicator(
                              value: v,
                              strokeWidth: 7,
                              strokeCap: StrokeCap.round,
                              color: status.color,
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$completed/$total',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                ),
                                const Text('steps', style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 21, height: 1.15, fontWeight: FontWeight.w900, letterSpacing: -0.6),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            total == 0 ? 'No steps planned yet' : '${(progress * 100).round()}% of the work is done',
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(Bento.radiusSm),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      BentoAvatar(name: clientName, image: clientImage, size: 40, ring: false),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CLIENT', style: TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
                            Text(
                              clientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800),
                            ),
                            if (clientEmail.isNotEmpty)
                              Text(
                                clientEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobFacts(String location, String plotSize, String timeline, double budget) {
    Widget fact(IconData icon, Color color, String label, String value) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      return BentoCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            BentoIconBubble(icon: icon, color: color, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Bento.muted(dark), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Bento.text(dark)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: fact(Icons.place_rounded, Bento.red, 'Location', location)),
            const SizedBox(width: Bento.gap),
            Expanded(child: fact(Icons.square_foot_rounded, Bento.blue, 'Plot size', '$plotSize sq ft')),
          ],
        ),
        const SizedBox(height: Bento.gap),
        Row(
          children: [
            Expanded(child: fact(Icons.event_rounded, Bento.violet, 'Timeline', timeline)),
            const SizedBox(width: Bento.gap),
            Expanded(child: fact(Icons.account_balance_wallet_rounded, Bento.green, 'Budget', budget > 0 ? _formatRupees(budget) : '—')),
          ],
        ),
      ],
    );
  }

  Widget _buildJobActions(String stage, int completed, int total) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final s = stage.toLowerCase().trim();

    Widget banner(Color color, IconData icon, String title, String text, {Widget? action}) {
      return BentoCard(
        color: Color.alphaBlend(color.withValues(alpha: dark ? 0.14 : 0.08), Bento.surface(dark)),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BentoIconBubble(icon: icon, color: color, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Bento.text(dark))),
                      const SizedBox(height: 2),
                      Text(text, style: TextStyle(fontSize: 12, color: Bento.muted(dark), height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
            if (action != null) ...[const SizedBox(height: 14), action],
          ],
        ),
      );
    }

    if (s == 'cancelled') {
      return banner(
        Bento.red,
        Icons.cancel_rounded,
        'Project cancelled',
        'Work has stopped. You can permanently delete this project and all its records.',
        action: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showDeleteConfirmationDialog,
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete project data'),
            style: ElevatedButton.styleFrom(backgroundColor: Bento.red, foregroundColor: Colors.white),
          ),
        ),
      );
    }
    if (s == 'completed' || s == 'finished') {
      return banner(Bento.green, Icons.verified_rounded, 'Project completed', 'All milestones are finalized. This job is now view-only.');
    }
    if (s == 'finished pending approval') {
      return banner(Bento.violet, Icons.hourglass_top_rounded, 'Submitted for approval', 'Waiting for the client to review and approve the finished work.');
    }

    final isOnHold = s == 'on hold';
    final allDone = total > 0 && completed == total;
    final canFinish = allDone && !isOnHold;

    Widget actionTile({
      required IconData icon,
      required String label,
      required String caption,
      required VoidCallback? onTap,
      Gradient? gradient,
      Color? color,
      bool light = true,
    }) {
      final fg = light ? Colors.white : Bento.muted(dark);
      return BentoCard(
        gradient: gradient,
        color: color,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: light ? Colors.white.withValues(alpha: 0.18) : Bento.border(dark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: fg, size: 21),
            ),
            const SizedBox(height: 14),
            Text(label, style: TextStyle(color: light ? Colors.white : Bento.text(dark), fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: light ? Colors.white70 : Bento.muted(dark), fontSize: 11.5, height: 1.3),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: isOnHold
                    ? actionTile(
                        icon: Icons.play_arrow_rounded,
                        label: 'Resume job',
                        caption: 'Notify the client work restarted',
                        color: const Color(0xFFD97706),
                        onTap: () => _updateProjectStage('Tracking'),
                      )
                    : actionTile(
                        icon: Icons.pause_rounded,
                        label: 'Hold project',
                        caption: 'Pause work and inform the client',
                        gradient: Bento.inkGradient,
                        onTap: () => _updateProjectStage('On Hold'),
                      ),
              ),
              const SizedBox(width: Bento.gap),
              Expanded(
                child: canFinish
                    ? actionTile(
                        icon: Icons.done_all_rounded,
                        label: 'Finish project',
                        caption: 'Send to the client for approval',
                        gradient: Bento.accentGradient,
                        onTap: () => _updateProjectStage('Finished Pending Approval'),
                      )
                    : actionTile(
                        icon: Icons.lock_rounded,
                        label: 'Finish project',
                        caption: isOnHold ? 'Resume the job first' : 'Complete all steps to unlock',
                        color: Bento.surfaceAlt(dark),
                        light: false,
                        onTap: null,
                      ),
              ),
            ],
          ),
        ),
        if (!allDone && total > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: BentoProgressBar(value: completed / total, height: 6)),
              const SizedBox(width: 10),
              Text(
                '$completed of $total steps done',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Bento.muted(dark)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNoPlanCard(bool isReadOnly) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BentoCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const BentoIconBubble(icon: Icons.auto_awesome_rounded, color: Bento.accent, size: 60),
          const SizedBox(height: 14),
          Text(
            'No execution plan yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Bento.text(dark), letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            'Generate a smart plan from the client\'s selected services (${_project?['type'] ?? ''}) or add your own steps.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Bento.muted(dark), height: 1.4),
          ),
          if (!isReadOnly) ...[
            const SizedBox(height: 18),
            BentoButton(
              label: 'Generate smart plan',
              icon: Icons.auto_awesome_rounded,
              expand: true,
              onTap: _generateTemplateTasks,
            ),
            const SizedBox(height: 6),
            TextButton(onPressed: _showAddTaskDialog, child: const Text('Create a custom step')),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingTaskCard(dynamic task, bool isReadOnly) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final taskId = task['id'];
    final title = (task['title'] ?? 'Untitled step').toString();
    final duration = task['duration'] ?? 1;
    final stage = (task['stage'] ?? 'General planning').toString();

    return BentoCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          BentoIconBubble(icon: Icons.radio_button_unchecked_rounded, color: Bento.muted(dark), size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Bento.text(dark)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    BentoPill(label: stage, color: Bento.accentText(dark), icon: Icons.layers_rounded),
                    BentoPill(
                      label: '$duration day${duration == 1 ? '' : 's'}',
                      color: Bento.muted(dark),
                      background: Bento.surfaceAlt(dark),
                      icon: Icons.timer_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isReadOnly) ...[
            const SizedBox(width: 6),
            BentoCircleButton(
              icon: Icons.play_arrow_rounded,
              color: Bento.accentText(dark),
              tooltip: 'Start step',
              onPressed: () => _startTask(taskId),
            ),
            IconButton(
              tooltip: 'Delete step',
              icon: Icon(Icons.delete_outline_rounded, color: Bento.muted(dark)),
              onPressed: () => _deleteTask(taskId),
            ),
          ],
        ],
      ),
    );
  }

  void _openClientChat(String clientName) {
    final clientId = _project?['user']?['id'] ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatDetailScreen(partnerId: clientId, partnerName: clientName)),
    );
  }

  Widget _buildCategoryTab(int index, IconData icon, String label, int? count) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selectedTab == index;
    return BentoPressable(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? (dark ? Colors.white : Bento.ink) : Bento.surface(dark),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: selected ? Colors.transparent : Bento.border(dark)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? (dark ? Bento.ink : Colors.white) : Bento.muted(dark)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? (dark ? Bento.ink : Colors.white) : Bento.text(dark),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Bento.accent : Bento.surfaceAlt(dark),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: selected ? Colors.white : Bento.muted(dark)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildLegendItem(Color color, String label, double value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
                  _workers.add(
                    Worker(
                      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      role: role,
                      dailyWage: wage,
                    ),
                  );
                });
                _saveWorkers();
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
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
    final amountController = TextEditingController(
      text: worker.remainingSalary.toStringAsFixed(2),
    );

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
              final amount =
                  double.tryParse(amountController.text.trim()) ?? 0.0;
              if (amount > 0) {
                setState(() {
                  worker.amountPaid += amount;
                });
                _saveWorkers();
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Paid ₹${amount.toStringAsFixed(2)} to ${worker.name}!',
                    ),
                  ),
                );
              }
            },
            child: const Text('RECORD PAYMENT'),
          ),
        ],
      ),
    );
  }

  void _showEditWorkerDialog(Worker worker) {
    final nameController = TextEditingController(text: worker.name);
    final roleController = TextEditingController(text: worker.role);
    final wageController = TextEditingController(
      text: worker.dailyWage.toString(),
    );
    final daysController = TextEditingController(
      text: worker.daysPresent.toString(),
    );
    final paidController = TextEditingController(
      text: worker.amountPaid.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Worker: ${worker.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Worker Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'Role / Designation',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: wageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Daily Wage (₹)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Days Worked'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: paidController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Wages Paid (₹)'),
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
              final days = int.tryParse(daysController.text.trim()) ?? 0;
              final paid = double.tryParse(paidController.text.trim()) ?? 0.0;

              if (name.isNotEmpty && role.isNotEmpty && wage > 0) {
                setState(() {
                  worker.name = name;
                  worker.role = role;
                  worker.dailyWage = wage;
                  worker.daysPresent = days;
                  worker.amountPaid = paid;
                });
                _saveWorkers();
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Worker details updated successfully!'),
                  ),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _deleteWorker(Worker worker) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Worker'),
        content: Text('Are you sure you want to remove ${worker.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _workers.removeWhere((w) => w.id == worker.id);
              });
              _saveWorkers();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Worker removed.')));
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLogPhotoPreview(
    BuildContext context,
    String photoUrl,
    String title,
  ) {
    final isNet =
        photoUrl.startsWith('http://') || photoUrl.startsWith('https://');
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(
              base64Image: isNet ? null : photoUrl,
              imageUrl: isNet ? photoUrl : null,
              title: title,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Builder(
              builder: (context) {
                if (isNet) {
                  return Image.network(
                    photoUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  );
                }
                try {
                  final cleanB64 =
                      (photoUrl.contains(',')
                              ? photoUrl.split(',').last
                              : photoUrl)
                          .replaceAll(RegExp(r'\s+'), '');
                  return Image.memory(
                    base64Decode(cleanB64),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  );
                } catch (_) {
                  return Container(
                    height: 140,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                }
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Tap to expand',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
