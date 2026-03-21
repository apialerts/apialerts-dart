/// Base class for all API Alerts exceptions.
sealed class ApiAlertsException implements Exception {
  const ApiAlertsException();
}

/// The global client has not been initialised via [ApiAlerts.configure].
final class NotInitializedException extends ApiAlertsException {
  const NotInitializedException();
  @override
  String toString() =>
      'ApiAlertsException: client not initialized — call configure() first';
}

/// The API key was empty.
final class MissingApiKeyException extends ApiAlertsException {
  const MissingApiKeyException();
  @override
  String toString() => 'ApiAlertsException: api key is required';
}

/// The message field was empty.
final class MissingMessageException extends ApiAlertsException {
  const MissingMessageException();
  @override
  String toString() => 'ApiAlertsException: message is required';
}

/// HTTP 400 — the server rejected the request payload.
final class BadRequestException extends ApiAlertsException {
  const BadRequestException();
  @override
  String toString() => 'ApiAlertsException: bad request';
}

/// HTTP 401 — the API key is invalid.
final class UnauthorizedException extends ApiAlertsException {
  const UnauthorizedException();
  @override
  String toString() => 'ApiAlertsException: unauthorized — check your API key';
}

/// HTTP 403 — the API key does not have permission for this operation.
final class ForbiddenException extends ApiAlertsException {
  const ForbiddenException();
  @override
  String toString() => 'ApiAlertsException: forbidden';
}

/// HTTP 429 — the account has exceeded its event quota.
final class RateLimitExceededException extends ApiAlertsException {
  const RateLimitExceededException();
  @override
  String toString() => 'ApiAlertsException: rate limit exceeded';
}

/// Any non-2xx status code not explicitly handled above.
final class UnexpectedStatusException extends ApiAlertsException {
  final int statusCode;
  const UnexpectedStatusException(this.statusCode);
  @override
  String toString() => 'ApiAlertsException: unexpected status $statusCode';
}

/// The 200 response body was not valid JSON or was missing expected fields.
final class InvalidResponseException extends ApiAlertsException {
  final String details;
  const InvalidResponseException(this.details);
  @override
  String toString() => 'ApiAlertsException: invalid response: $details';
}
