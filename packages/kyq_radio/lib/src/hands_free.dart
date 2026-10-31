import 'package:kyq_ptt/kyq_ptt.dart';

import 'controller/radio_cubit.dart';

/// El botón físico y la burbuja de 005 hablan por la conversación seleccionada de Radio cuando
/// no hay viaje (FR-028).
class RadioHandsFree implements HandsFreeRadio {
  RadioHandsFree(this.cubit);

  final RadioCubit cubit;

  RadioState get _s => cubit.state;

  @override
  bool get ready => !cubit.isClosed && (_s.me?.radioOn ?? false) && _s.selected != null;

  @override
  bool get speaking => _s.talk == TalkStatus.requesting || _s.talk == TalkStatus.talking;

  @override
  BubbleLook get look {
    final c = _s.selected;
    return switch (_s.talk) {
      TalkStatus.requesting || TalkStatus.talking => BubbleLook.talking,
      TalkStatus.busy => BubbleLook.busy,
      _ when c != null && _s.holders[c.id] != null => BubbleLook.remoteTalking,
      _ => BubbleLook.idle,
    };
  }

  @override
  Stream<void> get changes => cubit.stream;

  @override
  Future<void> press() => cubit.press();

  @override
  Future<void> release() => cubit.release();
}
