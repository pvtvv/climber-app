import 'package:climber_app/services/session_store.dart';
import 'package:climber_app/state/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionController controller;
  var idCounter = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    idCounter = 0;
    controller = SessionController(
      store: SessionStore(),
      idGenerator: () => 'id-${++idCounter}',
    );
    await controller.addAthlete('Alice');
  });

  String athleteId() => controller.athletes.single.id;

  test('first addPendingRun creates one pending; second is no-op', () async {
    final first = await controller.addPendingRun(athleteId());
    expect(first, isTrue);
    expect(controller.athletes.single.runs.length, 1);
    expect(controller.athletes.single.runs.single.isPending, isTrue);

    final second = await controller.addPendingRun(athleteId());
    expect(second, isFalse);
    expect(controller.athletes.single.runs.length, 1);
  });

  test('saveRun converts pending into saved run with time', () async {
    await controller.addPendingRun(athleteId());
    final ok = await controller.saveRun(athleteId(), 12345);
    expect(ok, isTrue);
    final run = controller.athletes.single.runs.single;
    expect(run.isPending, isFalse);
    expect(run.durationMs, 12345);
    expect(run.completedAt, isNotNull);
    expect(run.runNumber, 1);
    expect(controller.hasPending(athleteId()), isFalse);
  });

  test('discardPending removes pending and leaves saved runs', () async {
    await controller.addPendingRun(athleteId());
    await controller.saveRun(athleteId(), 10000);
    await controller.addPendingRun(athleteId());
    expect(controller.athletes.single.runs.length, 2);

    final ok = await controller.discardPending(athleteId());
    expect(ok, isTrue);
    expect(controller.athletes.single.runs.length, 1);
    expect(controller.athletes.single.runs.single.durationMs, 10000);
    expect(controller.athletes.single.runs.single.isPending, isFalse);
  });

  test('sortByTime orders saved runs ascending by duration', () async {
    await controller.addPendingRun(athleteId());
    await controller.saveRun(athleteId(), 30000);
    await controller.addPendingRun(athleteId());
    await controller.saveRun(athleteId(), 10000);
    await controller.addPendingRun(athleteId());
    await controller.saveRun(athleteId(), 20000);

    controller.sortByTime(athleteId());
    final times =
        controller.athletes.single.runs.map((r) => r.durationMs).toList();
    expect(times, [10000, 20000, 30000]);
  });
}
