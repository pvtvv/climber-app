import 'package:flutter/material.dart';
import 'package:climber_app/state/session_controller.dart';
import 'package:climber_app/widgets/athlete_tile.dart';
import 'package:climber_app/widgets/leave_confirm.dart';
import 'package:climber_app/widgets/new_session_dialog.dart';

/// Session roster surface with ModePicker back navigation.
/// @cpt-flow:cpt-climberapp-flow-measurement-mode-entry-leave-to-picker:p1
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _expandedIds = {};
  final ValueNotifier<bool> _timingInProgress = ValueNotifier(false);

  SessionController get controller => widget.controller;

  @override
  void dispose() {
    _timingInProgress.dispose();
    super.dispose();
  }

  Future<void> _addAthlete() async {
    var typedName = '';
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add athlete'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Athlete name',
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => typedName = v,
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(typedName),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (name == null) return;
    final ok = await controller.addAthlete(name);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 10 athletes reached.')),
      );
    }
  }

  Future<void> _newSession() async {
    final choice = await showNewSessionDialog(context);
    if (choice == 'save') {
      await controller.newSessionSave();
    } else if (choice == 'cancel') {
      await controller.newSessionCancel();
    }
    if (mounted) {
      setState(() => _expandedIds.clear());
    }
  }

  Future<void> _handleBack() async {
    if (_timingInProgress.value) {
      final leave = await confirmLeaveWhileRunning(context);
      if (!leave || !mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop<int?>(null);
      }
      _timingInProgress.value = false;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_timingInProgress.value,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final athletes = controller.athletes;
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: _handleBack),
              title: const Text('Climber Speed Timer'),
              actions: [
                IconButton(
                  tooltip: 'Export CSV',
                  onPressed: athletes.isEmpty
                      ? null
                      : () {
                          controller.exportCsv();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('CSV downloaded.')),
                          );
                        },
                  icon: const Icon(Icons.download),
                ),
                IconButton(
                  tooltip: 'New session',
                  onPressed: athletes.isEmpty ? null : _newSession,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: athletes.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No athletes yet.\nTap + to add an athlete and start timing.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
                    itemCount: athletes.length,
                    itemBuilder: (context, index) {
                      final athlete = athletes[index];
                      final expanded = _expandedIds.contains(athlete.id);
                      return AthleteTile(
                        athlete: athlete,
                        expanded: expanded,
                        controller: controller,
                        timingInProgress: _timingInProgress,
                        onLeaveWhileRunning: () async {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        onToggle: () {
                          setState(() {
                            if (expanded) {
                              _expandedIds.remove(athlete.id);
                            } else {
                              _expandedIds.add(athlete.id);
                            }
                          });
                        },
                      );
                    },
                  ),
            floatingActionButton: FloatingActionButton(
              onPressed: controller.canAddAthlete ? _addAthlete : null,
              tooltip: controller.canAddAthlete
                  ? 'Add athlete'
                  : 'Maximum 10 athletes',
              backgroundColor: controller.canAddAthlete
                  ? null
                  : Theme.of(context).disabledColor,
              child: const Icon(Icons.person_add),
            ),
          );
        },
      ),
    );
  }
}
