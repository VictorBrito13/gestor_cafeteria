//clase sellada para vgestionar los estaos de fallo

//clase principal ->sellada -> va a saber quienes sin todos sus hijos 
sealed class Failure implements Exception{
  const Failure (this.message);
  final String message;
}

//1   sin conexion,DNS,timeouts
final class NetworkFailure extends Failure{
  const NetworkFailure (): super ("NO SE PUEDO CONECTAR ALA SERVIDOR ");
}

//2. 5xx Servidor no responde 
final class ServerFailure extends Failure{
  const ServerFailure (this.statusCode): super("Error del servidor ");
  final int statusCode;
}

//3. 404
final class NotFoundFailure extends Failure {
const NotFoundFailure(super.message);
}

//4. 409
final class ConflictFailure extends Failure {
ConflictFailure(super.message);
}

//5. 422
final class ValidationFailure extends Failure {
ValidationFailure(this.fields) : super ("error de validacion");
final Map<String,String>fields;
}


//error deconocido
final class UnexpectedFailure extends Failure{
  const UnexpectedFailure (this.statusCode,super.message);
  final int statusCode;
}