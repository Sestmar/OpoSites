import '../../../tests/data/models/test_result.dart';

export '../../../tests/data/models/test_result.dart'
    show TestResult, QuestionResult, TopicAnalysis;

/// Un simulacro comparte exactamente la misma estructura de resultado que un
/// test libre ([TestResult]), con la diferencia de que [TestResult.analisisPorTema]
/// **siempre está presente** en simulacros (nunca es null).
///
/// Usamos un typedef para que la UI de simulacros pueda usar el tipo
/// [SimulacroResult] sin importar desde la feature de tests directamente.
typedef SimulacroResult = TestResult;
