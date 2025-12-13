  // lib/screens/add_pt_session_screen.dart

  import 'package:flutter/material.dart';
  import 'package:flutter_form_builder/flutter_form_builder.dart';
  import 'package:provider/provider.dart';
  import 'package:intl/intl.dart';
  import 'package:uuid/uuid.dart';

  import 'package:gym/models/pt_session.dart';
  import 'package:gym/models/trainer_package.dart';
  import 'package:gym/providers/pt_provider.dart';
  import 'package:gym/providers/customer_provider.dart';
  import 'package:gym/providers/trainer_provider.dart';
  import 'package:gym/providers/database_helper.dart';
  import 'package:gym/utils/app_refresher.dart';

  class AddPTSessionScreen extends StatefulWidget {
    final String? preselectedCustomerId;
    final String? preselectedTrainerId;
    final String? preselectedPackageId;

    const AddPTSessionScreen({
      super.key,
      this.preselectedCustomerId,
      this.preselectedTrainerId,
      this.preselectedPackageId,
    });

    @override
    State<AddPTSessionScreen> createState() => _AddPTSessionScreenState();
  }

  class _AddPTSessionScreenState extends State<AddPTSessionScreen> {
    final _formKey = GlobalKey<FormBuilderState>();

    List<TrainerPackage> _availablePackages = [];
    bool _isLoadingPackages = false;

    bool _usingPackage = false;
    double _trainerRate = 0.0;

    @override
    void initState() {
      super.initState();

      if (widget.preselectedCustomerId != null) {
        Future.microtask(() {
          _fetchPackages(widget.preselectedCustomerId!);
        });
      }

      _loadPreselectedTrainer();
    }

    // ---------------------------------------------------------------------------
    // SAFE TRAINER PRELOAD
    // ---------------------------------------------------------------------------
    void _loadPreselectedTrainer() {
      if (widget.preselectedTrainerId == null) return;

      try {
        final trainerProvider =
            Provider.of<TrainerProvider>(context, listen: false);

        final trainer = trainerProvider.trainers.firstWhere(
          (t) => t.trainerId == widget.preselectedTrainerId,
          orElse: () => throw Exception("Trainer not found"),
        );

        _trainerRate = trainer.ratePerSession;

        // Update cost field once trainer rate is known
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_usingPackage) {
            _formKey.currentState?.fields['cost']
                ?.didChange(_trainerRate.toStringAsFixed(2));
          }
        });
      } catch (e) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Unable to load trainer rate."),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }

    // ---------------------------------------------------------------------------
    // INPUT DECORATION (Premium look)
    // ---------------------------------------------------------------------------
    InputDecoration _fieldDecoration(String label, IconData icon,
        {String? hintText, String? suffixText}) {
      return InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixText: suffixText,
        prefixIcon: Icon(icon, color: Colors.blueGrey.shade400),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
      );
    }

    // ---------------------------------------------------------------------------
    // PACKAGE FETCH WITH ERROR TRAPPING
    // ---------------------------------------------------------------------------
    Future<void> _fetchPackages(String customerId) async {
      setState(() => _isLoadingPackages = true);

      try {
        final db = DatabaseHelper();
        final raw = await db.getTrainerPackages() ?? [];

        final filtered = raw
            .map((m) => TrainerPackage.fromJson(m))
            .where((p) =>
                p.customerId == customerId &&
                p.calculatedStatus == "Active" &&
                p.sessionsRemaining > 0)
            .toList();

        setState(() => _availablePackages = filtered);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load PT packages."),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoadingPackages = false);
      }
    }

    // ---------------------------------------------------------------------------
    // TRAINER SELECTION HANDLER
    // ---------------------------------------------------------------------------
    void _onTrainerSelected(String? trainerId) {
      if (trainerId == null) return;

      try {
        final trainerProvider =
            Provider.of<TrainerProvider>(context, listen: false);

        final trainer = trainerProvider.trainers.firstWhere(
          (t) => t.trainerId == trainerId,
          orElse: () => throw Exception("Trainer not found"),
        );

        setState(() => _trainerRate = trainer.ratePerSession);

        if (!_usingPackage) {
          _formKey.currentState?.fields['cost']
              ?.didChange(_trainerRate.toStringAsFixed(2));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to update trainer info."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // ---------------------------------------------------------------------------
    // UI BUILD
    // ---------------------------------------------------------------------------
    @override
    Widget build(BuildContext context) {
      final customerProvider = Provider.of<CustomerProvider>(context);
      final trainerProvider = Provider.of<TrainerProvider>(context);

      return Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.black), // ← makes back button black
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.08),
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            "Book PT Session",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Colors.black87,
            ),
          ),
        ),


        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              children: [
                // Premium header card
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEEF5FF), Color(0xFFE0F7FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.blue.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: const Icon(Icons.fitness_center,
                            color: Colors.blueAccent, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Create a New PT Session",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Set client, trainer, schedule and payment in one flow.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d').format(DateTime.now()),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                FormBuilder(
                  key: _formKey,
                  initialValue: {
                    'customer_id': widget.preselectedCustomerId,
                    'trainer_id': widget.preselectedTrainerId,
                    'package_id': widget.preselectedPackageId ?? 'cash',
                    'start_time': DateTime.now().add(const Duration(hours: 1)),
                    'duration': '60',
                    'cost': widget.preselectedPackageId != null
                        ? "0.00"
                        : _trainerRate.toStringAsFixed(2),
                    'is_paid': false,
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("Who"),

                      _card(
                        child: Column(
                          children: [
                            // CUSTOMER
                            FormBuilderDropdown<String>(
                              name: 'customer_id',
                              enabled: widget.preselectedCustomerId == null,
                              decoration: _fieldDecoration(
                                  "Customer", Icons.person, hintText: "Select"),
                              items: customerProvider.customers
                                  .map((c) => DropdownMenuItem(
                                        value: c.customerId,
                                        child: Text(
                                            "${c.firstName} ${c.lastName}"),
                                      ))
                                  .toList(),
                              onChanged: widget.preselectedCustomerId == null
                                  ? (val) {
                                      if (val != null) _fetchPackages(val);
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // TRAINER
                            FormBuilderDropdown<String>(
                              name: 'trainer_id',
                              enabled: widget.preselectedTrainerId == null,
                              decoration: _fieldDecoration("Trainer",
                                  Icons.sports_gymnastics,
                                  hintText: "Select"),
                              items: trainerProvider.trainers
                                  .map((t) => DropdownMenuItem(
                                        value: t.trainerId,
                                        child: Text(
                                          "${t.firstName} ${t.lastName} "
                                          "(₱${t.ratePerSession})",
                                        ),
                                      ))
                                  .toList(),
                              onChanged: widget.preselectedTrainerId == null
                                  ? _onTrainerSelected
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      _sectionTitle("When"),

                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FormBuilderDateTimePicker(
                              name: 'start_time',
                              inputType: InputType.both,
                              decoration: _fieldDecoration(
                                "Date & Time",
                                Icons.calendar_today,
                              ),
                            ),
                            const SizedBox(height: 16),

                            FormBuilderTextField(
                              name: 'duration',
                              keyboardType: TextInputType.number,
                              decoration: _fieldDecoration(
                                "Duration",
                                Icons.timer,
                                hintText: "Enter duration in minutes",
                                suffixText: "min",
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return "Required";
                                }
                                final parsed = int.tryParse(val);
                                if (parsed == null) {
                                  return "Must be a valid number";
                                }
                                if (parsed < 30) {
                                  return "Minimum duration is 30 minutes";
                                }
                                if (parsed > 300) {
                                  return "Maximum duration is 5 hours (300 minutes)";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Sessions must be between 30 minutes and 5 hours.",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      _sectionTitle("Payment"),

                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _isLoadingPackages
                                ? const LinearProgressIndicator()
                                : FormBuilderDropdown<String>(
                                    name: 'package_id',
                                    enabled:
                                        widget.preselectedPackageId == null,
                                    decoration: _fieldDecoration(
                                        "Payment Method", Icons.payment),
                                    items: [
                                      const DropdownMenuItem(
                                        value: 'cash',
                                        child: Text("Pay Per Session"),
                                      ),
                                      ..._availablePackages.map(
                                        (p) => DropdownMenuItem(
                                          value: p.packageId,
                                          child: Text(
                                            "${p.packageName} "
                                            "(${p.sessionsRemaining} left)",
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      try {
                                        if (val == 'cash') {
                                          _formKey
                                              .currentState?.fields['cost']
                                              ?.didChange(_trainerRate
                                                  .toStringAsFixed(2));
                                          _usingPackage = false;
                                        } else {
                                          _formKey.currentState
                                              ?.fields['cost']
                                              ?.didChange("0.00");
                                          _usingPackage = true;
                                        }
                                      } catch (_) {}
                                    },
                                  ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'cost',
                                    readOnly: _usingPackage,
                                    keyboardType: TextInputType.number,
                                    decoration: _fieldDecoration(
                                      "Cost (₱)",
                                      Icons.money,
                                      hintText: "0.00",
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
Expanded(
  child: FormBuilderSwitch(
    name: 'is_paid',
    enabled: !_usingPackage,
    title: const Text(
      "Paid?",
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
    decoration: const InputDecoration(
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
      ),
    ),

    activeColor: Colors.green,
    inactiveThumbColor: Colors.grey,
    inactiveTrackColor: Color(0xFFE0E0E0),


  ),
),

                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      _saveButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ---------------------------------------------------------------------------
    // SAVE BUTTON + ERROR TRAPPING + DURATION LIMITS
    // ---------------------------------------------------------------------------
    Widget _saveButton() {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
          child: const Text(
            "Confirm Booking",
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          onPressed: () async {
            if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please fix the highlighted fields."),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            try {
              final data = _formKey.currentState!.value;

              final duration = int.tryParse(data['duration'].toString());
              if (duration == null) {
                throw Exception("Invalid session duration.");
              }

              // Extra safety: enforce 30–300 min in logic too
              if (duration < 30 || duration > 300) {
                throw Exception(
                    "Session duration must be between 30 and 300 minutes.");
              }

              final cost = double.tryParse(data['cost'].toString());
              if (cost == null || cost < 0) {
                throw Exception("Invalid cost value.");
              }

              final ptProvider =
                  Provider.of<PTProvider>(context, listen: false);

              bool isAvailable = false;
              try {
                isAvailable = ptProvider.checkAvailability(
                  data['trainer_id'],
                  data['start_time'],
                  duration,
                );
              } catch (_) {
                throw Exception("Unable to validate trainer availability.");
              }

              if (!isAvailable) {
                throw Exception("Trainer is already booked at this time.");
              }

              final session = PTSession(
                sessionId: const Uuid().v4(),
                customerId: data['customer_id'],
                trainerId: data['trainer_id'],
                packageId:
                    data['package_id'] == 'cash' ? null : data['package_id'],
                startTime: data['start_time'],
                durationMinutes: duration,
                cost: cost,
                status: "Completed",
                isPaid: data['package_id'] == 'cash'
                    ? data['is_paid'] ?? false
                    : false,
                trainerPaid: false,
                notes: null,
              );

              await ptProvider.addSession(session);

              if (mounted) {
                await AppRefresher.refreshAll(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("PT Session saved successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    e.toString().replaceAll("Exception:", "").trim(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );
    }

    // ---------------------------------------------------------------------------
    // SMALL HELPERS
    // ---------------------------------------------------------------------------
    Widget _sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      );
    }

    Widget _card({required Widget child}) {
      return Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: child,
        ),
      );
    }
  }
