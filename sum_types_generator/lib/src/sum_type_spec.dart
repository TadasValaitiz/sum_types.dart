import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sum_types_generator/src/templates.dart';

@immutable
class SumTypeSpec {
  const SumTypeSpec({@required this.anchorName, @required this.sumTypeName, @required this.cases});

  final String anchorName;
  final String sumTypeName;
  final Iterable<CaseSpec> cases;
}

@immutable
class CaseSpec {
  const CaseSpec({@required this.type, @required this.name});

  final DartType type;
  final String name;

  @override
  bool operator ==(dynamic other) => other.runtimeType == runtimeType && other.type == type && other.name == name;

  @override
  int get hashCode {
    int result = 17;
    result = 37 * result + type.hashCode;
    result = 37 * result + name.hashCode;
    return result;
  }
}

SumTypeSpec makeSumTypeSpec(Element element, ConstantReader annotation) {
  if (element is ClassElement && element.isMixin) {
    return SumTypeSpec(
      anchorName: element.name,
      sumTypeName: undecoratedID(element.name),
      cases: annotation.objectValue.getField("cases").toListValue().map(makeCaseSpec),
    );
  }
  throw Exception("A sum-type anchor must be a mix-in");
}

CaseSpec makeCaseSpec(DartObject obj) {
  final caseType = obj.type.typeArguments.first;
  return CaseSpec(
    type: caseType,
    name: obj.getField("name").toStringValue() ?? _defaultCaseName(caseType),
  );
}

String _defaultCaseName(DartType type) => lowercaseLeadingID(undecoratedID(type.name));

bool caseRequiresPayload(CaseSpec caseSpec) =>
    !(caseSpec.type.isDynamic || caseSpec.type.isVoid || caseSpec.type.isDartCoreNull);

String caseTypeName(CaseSpec caseSpec) => _typeName(caseSpec.type);

String _typeName(DartType type) => [
      "${type.name}",
      if (type is ParameterizedType && type.typeArguments.isNotEmpty) ...[
        "<",
        type.typeArguments.map(_typeName).join(", "),
        ">",
      ]
    ].join();
